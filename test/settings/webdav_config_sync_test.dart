import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sekuxnote/features/providers/provider_controller.dart';
import 'package:sekuxnote/features/settings/pages/webdav_sync_page.dart';
import 'package:sekuxnote/features/settings/webdav_config_sync.dart';
import 'package:sekuxnote/l10n/app_localizations.dart';

void main() {
  group('configuration snapshot', () {
    test('contains provider settings and API keys but no user data', () async {
      final source = ProviderController.inMemory();
      addTearDown(source.dispose);
      await source.saveText(
        name: 'Remote Text',
        enabled: true,
        baseUrl: 'https://text.example/v1',
        model: 'text-model',
        apiKey: 'text-secret',
      );
      await source.saveTranscription(
        name: 'Remote Speech',
        enabled: true,
        baseUrl: 'https://speech.example/v1',
        batchModel: 'speech-model',
        fastFileModel: 'speech-fast',
        realtimeModel: 'speech-realtime',
        language: 'en',
        chunkDurationSeconds: 45,
        maxConcurrentUploads: 3,
        apiKey: 'speech-secret',
      );

      final snapshot = await source.exportConfigurationSnapshot();
      final serialized = jsonEncode(snapshot);

      expect(serialized, contains('text-secret'));
      expect(serialized, contains('speech-secret'));
      expect(snapshot.keys, <String>[
        'schemaVersion',
        'exportedAt',
        'textProviderSettings',
        'transcriptionProviderSettings',
        'credentials',
      ]);
      expect(serialized, isNot(contains('transcription_tasks')));
      expect(serialized, isNot(contains('"transcript":')));
      expect(serialized, isNot(contains('"conversations":')));
      expect(serialized, isNot(contains('"recordingEntries":')));

      final target = ProviderController.inMemory();
      addTearDown(target.dispose);
      await target.importConfigurationSnapshot(snapshot);

      expect(target.textConfig.name, 'Remote Text');
      expect(target.transcriptionConfig.name, 'Remote Speech');
      expect(target.transcriptionConfig.language, 'en');
      expect(target.textCredentialConfigured, isTrue);
      expect(target.transcriptionCredentialConfigured, isTrue);
    });

    test(
      'rejects credential references not owned by imported providers',
      () async {
        final source = ProviderController.inMemory();
        addTearDown(source.dispose);
        final snapshot = await source.exportConfigurationSnapshot();
        snapshot['credentials'] = {'unrelated.secret': 'must-not-import'};

        final target = ProviderController.inMemory();
        addTearDown(target.dispose);
        await target.importConfigurationSnapshot(snapshot);

        expect(target.textCredentialConfigured, isFalse);
        expect(target.transcriptionCredentialConfigured, isFalse);
      },
    );
  });

  group('encrypted configuration codec', () {
    test('round trips without exposing API keys in the remote bytes', () async {
      final codec = ConfigurationSyncCodec(iterations: 10000);
      final encrypted = await codec.encode({
        'schemaVersion': 1,
        'credentials': {'provider.key': 'plain-api-key'},
      }, password: 'webdav-password');

      expect(utf8.decode(encrypted), isNot(contains('plain-api-key')));
      expect(
        await codec.decode(encrypted, password: 'webdav-password'),
        containsPair('schemaVersion', 1),
      );
      await expectLater(
        codec.decode(encrypted, password: 'wrong-password'),
        throwsA(anything),
      );
    });
  });

  group('WebDAV client', () {
    test('creates the collection and uploads the fixed config file', () async {
      final requests = <http.BaseRequest>[];
      final client = MockClient((request) async {
        requests.add(request);
        return switch (request.method) {
          'PROPFIND' => http.Response('', 207),
          'PUT' => http.Response('', 201),
          _ => http.Response('', 500),
        };
      });
      final webDav = WebDavConfigSyncClient(client: client);
      const settings = WebDavSyncSettings(
        url: 'https://dav.example/root',
        username: 'alice',
        password: 'secret',
        remotePath: 'sekuxnote/config',
      );

      await webDav.upload(settings, utf8.encode('{"encrypted":true}'));

      expect(requests.map((request) => request.method), [
        'PROPFIND',
        'PROPFIND',
        'PUT',
      ]);
      expect(
        requests.last.url.toString(),
        'https://dav.example/root/sekuxnote/config/$webDavSyncFileName',
      );
      expect(
        requests.last.headers[HttpHeaders.authorizationHeader],
        startsWith('Basic '),
      );
    });

    test('reports remote modification time with HEAD', () async {
      final client = MockClient(
        (request) async => http.Response(
          '',
          200,
          headers: {
            HttpHeaders.lastModifiedHeader: 'Fri, 17 Jul 2026 08:30:00 GMT',
          },
        ),
      );
      final webDav = WebDavConfigSyncClient(client: client);

      final modified = await webDav.remoteModifiedAt(
        const WebDavSyncSettings(
          url: 'https://dav.example/root',
          password: 'secret',
        ),
      );

      expect(modified?.toUtc(), DateTime.utc(2026, 7, 17, 8, 30));
    });
  });

  test('local WebDAV settings survive reopening', () async {
    final directory = await Directory.systemTemp.createTemp('webdav-settings-');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/settings.json';
    final store = FileWebDavSyncSettingsStore.atPath(path);

    await store.write(
      const WebDavSyncSettings(
        url: 'https://dav.example',
        username: 'alice',
        password: 'local-password',
        remotePath: 'custom/path',
      ),
    );

    final restored = await FileWebDavSyncSettingsStore.atPath(path).read();
    expect(restored.url, 'https://dav.example');
    expect(restored.username, 'alice');
    expect(restored.password, 'local-password');
    expect(restored.remotePath, 'custom/path');
  });

  testWidgets('settings page exposes connection and sync actions', (
    tester,
  ) async {
    final providerController = ProviderController.inMemory();
    addTearDown(providerController.dispose);
    final client = WebDavConfigSyncClient(
      client: MockClient((request) async => http.Response('', 200)),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: WebDavSyncPage(
          providerController: providerController,
          settingsStore: _MemoryWebDavSettingsStore(),
          client: client,
          codec: ConfigurationSyncCodec(iterations: 10000),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('webdav_url')), findsOneWidget);
    expect(find.byKey(const Key('webdav_password')), findsOneWidget);
    expect(find.byKey(const Key('webdav_test')), findsOneWidget);
    expect(find.byKey(const Key('webdav_upload')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('webdav_download')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('webdav_download')), findsOneWidget);
  });
}

class _MemoryWebDavSettingsStore implements WebDavSyncSettingsStore {
  WebDavSyncSettings value = const WebDavSyncSettings();

  @override
  Future<WebDavSyncSettings> read() async => value;

  @override
  Future<void> write(WebDavSyncSettings settings) async => value = settings;
}
