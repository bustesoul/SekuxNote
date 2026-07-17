import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import '../../app/storage/app_data_directory.dart';

const webDavSyncFileName = 'sekuxnote-config.json';

class WebDavSyncSettings {
  const WebDavSyncSettings({
    this.url = '',
    this.username = '',
    this.password = '',
    this.remotePath = 'sekuxnote/config',
  });

  final String url;
  final String username;
  final String password;
  final String remotePath;

  WebDavSyncSettings copyWith({
    String? url,
    String? username,
    String? password,
    String? remotePath,
  }) {
    return WebDavSyncSettings(
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      remotePath: remotePath ?? this.remotePath,
    );
  }

  Map<String, Object?> toJson() => {
    'url': url,
    'username': username,
    'password': password,
    'remotePath': remotePath,
  };

  factory WebDavSyncSettings.fromJson(Map<String, Object?> json) {
    return WebDavSyncSettings(
      url: json['url']?.toString().trim() ?? '',
      username: json['username']?.toString().trim() ?? '',
      password: json['password']?.toString() ?? '',
      remotePath: json['remotePath']?.toString().trim().isNotEmpty == true
          ? json['remotePath']!.toString().trim()
          : 'sekuxnote/config',
    );
  }
}

abstract interface class WebDavSyncSettingsStore {
  Future<WebDavSyncSettings> read();
  Future<void> write(WebDavSyncSettings settings);
}

class FileWebDavSyncSettingsStore implements WebDavSyncSettingsStore {
  FileWebDavSyncSettingsStore._(this._file);

  final File _file;

  static Future<FileWebDavSyncSettingsStore> open() async {
    final directory = await getSekuxNoteDataDirectory();
    return FileWebDavSyncSettingsStore._(
      File('${directory.path}/webdav-sync-settings.json'),
    );
  }

  static FileWebDavSyncSettingsStore atPath(String path) =>
      FileWebDavSyncSettingsStore._(File(path));

  @override
  Future<WebDavSyncSettings> read() async {
    if (!await _file.exists()) return const WebDavSyncSettings();
    try {
      return WebDavSyncSettings.fromJson(
        Map<String, Object?>.from(
          jsonDecode(await _file.readAsString()) as Map,
        ),
      );
    } catch (_) {
      return const WebDavSyncSettings();
    }
  }

  @override
  Future<void> write(WebDavSyncSettings settings) async {
    await _file.parent.create(recursive: true);
    final temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(jsonEncode(settings.toJson()), flush: true);
    if (await _file.exists()) await _file.delete();
    await temporary.rename(_file.path);
  }
}

/// Encrypts the provider snapshot with AES-256-GCM. The encryption key is
/// derived from the WebDAV password so another device needs no extra secret.
class ConfigurationSyncCodec {
  ConfigurationSyncCodec({int iterations = 120000}) : _iterations = iterations;

  static const format = 'sekuxnote.encrypted-config';
  static const version = 1;

  final int _iterations;

  Future<Uint8List> encode(
    Map<String, Object?> snapshot, {
    required String password,
  }) async {
    if (password.isEmpty) throw ArgumentError.value(password, 'password');
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await _deriveKey(password, salt, _iterations);
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(jsonEncode(snapshot)),
      secretKey: key,
      nonce: nonce,
    );
    final envelope = <String, Object?>{
      'format': format,
      'version': version,
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': _iterations,
      'salt': base64Encode(salt),
      'cipher': 'aes-256-gcm',
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<Map<String, Object?>> decode(
    List<int> bytes, {
    required String password,
  }) async {
    if (password.isEmpty) throw ArgumentError.value(password, 'password');
    final envelope = Map<String, Object?>.from(
      jsonDecode(utf8.decode(bytes)) as Map,
    );
    if (envelope['format'] != format || envelope['version'] != version) {
      throw const FormatException('unsupportedEncryptedConfiguration');
    }
    final iterations = (envelope['iterations'] as num?)?.toInt();
    if (iterations == null || iterations < 10000 || iterations > 1000000) {
      throw const FormatException('invalidKeyDerivationParameters');
    }
    final salt = base64Decode(envelope['salt']! as String);
    final nonce = base64Decode(envelope['nonce']! as String);
    final cipherText = base64Decode(envelope['ciphertext']! as String);
    final mac = Mac(base64Decode(envelope['mac']! as String));
    final key = await _deriveKey(password, salt, iterations);
    final clearText = await AesGcm.with256bits().decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: key,
    );
    return Map<String, Object?>.from(jsonDecode(utf8.decode(clearText)) as Map);
  }

  Future<SecretKey> _deriveKey(
    String password,
    List<int> salt,
    int iterations,
  ) {
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}

class WebDavSyncException implements Exception {
  const WebDavSyncException(this.code, [this.statusCode]);

  final String code;
  final int? statusCode;

  @override
  String toString() => statusCode == null ? code : '$code ($statusCode)';
}

class WebDavConfigSyncClient {
  WebDavConfigSyncClient({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<void> test(WebDavSyncSettings settings) =>
      _ensureCollection(_validated(settings));

  Future<void> upload(WebDavSyncSettings settings, List<int> bytes) async {
    final valid = _validated(settings);
    await _ensureCollection(valid);
    final response = await _client.put(
      _fileUri(valid),
      headers: {
        ..._headers(valid),
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
      },
      body: bytes,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebDavSyncException('uploadFailed', response.statusCode);
    }
  }

  Future<Uint8List> download(WebDavSyncSettings settings) async {
    final valid = _validated(settings);
    final response = await _client.get(
      _fileUri(valid),
      headers: _headers(valid),
    );
    if (response.statusCode == 404) {
      throw const WebDavSyncException('remoteConfigurationMissing', 404);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebDavSyncException('downloadFailed', response.statusCode);
    }
    return response.bodyBytes;
  }

  Future<DateTime?> remoteModifiedAt(WebDavSyncSettings settings) async {
    final valid = _validated(settings);
    final request = http.Request('HEAD', _fileUri(valid));
    request.headers.addAll(_headers(valid));
    final response = await _client.send(request).then(http.Response.fromStream);
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebDavSyncException('remoteMetadataFailed', response.statusCode);
    }
    final value = response.headers[HttpHeaders.lastModifiedHeader];
    if (value == null) return null;
    try {
      return HttpDate.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureCollection(WebDavSyncSettings settings) async {
    final segments = _remoteSegments(settings);
    if (segments.isEmpty) {
      await _propFind(settings, _rootUri(settings));
      return;
    }
    for (var index = 1; index <= segments.length; index += 1) {
      final uri = _collectionUri(settings, segments.take(index).toList());
      final status = await _propFind(settings, uri, allowMissing: true);
      if (status != 404) continue;
      final request = http.Request('MKCOL', uri);
      request.headers.addAll(_headers(settings));
      final response = await _client
          .send(request)
          .then(http.Response.fromStream);
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 405) {
        throw WebDavSyncException(
          'createRemotePathFailed',
          response.statusCode,
        );
      }
    }
  }

  Future<int> _propFind(
    WebDavSyncSettings settings,
    Uri uri, {
    bool allowMissing = false,
  }) async {
    final request = http.Request('PROPFIND', uri);
    request.headers.addAll({
      ..._headers(settings),
      'Depth': '0',
      HttpHeaders.contentTypeHeader: 'application/xml; charset=utf-8',
    });
    request.body =
        '<?xml version="1.0" encoding="utf-8"?>'
        '<d:propfind xmlns:d="DAV:"><d:prop><d:displayname/>'
        '</d:prop></d:propfind>';
    final response = await _client.send(request).then(http.Response.fromStream);
    if (allowMissing && response.statusCode == 404) return 404;
    if (response.statusCode != 207 &&
        (response.statusCode < 200 || response.statusCode >= 400)) {
      throw WebDavSyncException('connectionFailed', response.statusCode);
    }
    return response.statusCode;
  }

  WebDavSyncSettings _validated(WebDavSyncSettings settings) {
    final uri = Uri.tryParse(settings.url.trim());
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      throw const WebDavSyncException('invalidUrl');
    }
    if (settings.password.isEmpty) {
      throw const WebDavSyncException('passwordRequired');
    }
    return settings.copyWith(
      url: settings.url.trim().replaceAll(RegExp(r'/+$'), ''),
      username: settings.username.trim(),
      remotePath: settings.remotePath.trim(),
    );
  }

  Map<String, String> _headers(WebDavSyncSettings settings) {
    if (settings.username.isEmpty) return const {};
    final token = base64Encode(
      utf8.encode('${settings.username}:${settings.password}'),
    );
    return {HttpHeaders.authorizationHeader: 'Basic $token'};
  }

  Uri _rootUri(WebDavSyncSettings settings) {
    final base = Uri.parse(settings.url);
    return base.replace(query: null, fragment: null);
  }

  List<String> _remoteSegments(WebDavSyncSettings settings) => settings
      .remotePath
      .split('/')
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);

  List<String> _baseSegments(WebDavSyncSettings settings) => Uri.parse(
    settings.url,
  ).pathSegments.where((segment) => segment.isNotEmpty).toList();

  Uri _collectionUri(WebDavSyncSettings settings, List<String> segments) {
    final base = Uri.parse(settings.url);
    return base.replace(
      pathSegments: [..._baseSegments(settings), ...segments, ''],
      query: null,
      fragment: null,
    );
  }

  Uri _fileUri(WebDavSyncSettings settings) {
    final base = Uri.parse(settings.url);
    return base.replace(
      pathSegments: [
        ..._baseSegments(settings),
        ..._remoteSegments(settings),
        webDavSyncFileName,
      ],
      query: null,
      fragment: null,
    );
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
