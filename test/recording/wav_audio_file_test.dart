import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:sekuxnote/features/providers/provider_controller.dart';
import 'package:sekuxnote/features/recording/recording_models.dart';
import 'package:sekuxnote/features/recording/recording_session_controller.dart';
import 'package:sekuxnote/features/recording/wav_audio_file.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('sekuxnote-wav-test-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('PCM is finalized to a canonical WAV by atomic replacement', () async {
    final pcm = File('${root.path}/audio.pcm.part');
    final wav = File('${root.path}/audio.wav');
    final samples = Uint8List.fromList(List<int>.generate(32000, (i) => i));
    await pcm.writeAsBytes(samples);

    final result = await WavAudioFile.finalizePcm(pcmFile: pcm, wavFile: wav);

    expect(result.isValid, isTrue);
    expect(result.dataBytes, samples.length);
    expect(result.fileBytes, samples.length + 44);
    expect(result.durationMilliseconds, 1000);
    expect(await pcm.exists(), isFalse);
    expect(await File('${wav.path}.tmp').exists(), isFalse);
  });

  test('the observed 44-byte negative-size WAV is rejected', () {
    final corrupt = WavAudioFile.header(0);
    final view = ByteData.sublistView(corrupt);
    view.setUint32(4, 0xfffffff8, Endian.little);
    view.setUint32(40, 0xffffffd4, Endian.little);

    final result = WavAudioFile.validateBytes(corrupt);

    expect(result.isValid, isFalse);
    expect(result.code, 'riffSizeMismatch');
    expect(result.fileBytes, 44);
  });

  test('load never rewrites an already completed recording', () async {
    final directory = Directory('${root.path}/ready')..createSync();
    final wav = File('${directory.path}/audio.wav');
    final original = Uint8List.fromList([
      ...WavAudioFile.header(8),
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
    ]);
    await wav.writeAsBytes(original);
    await _writeEntry(
      directory,
      _entry(id: 'ready', audioPath: wav.path, status: RecordingStatus.ready),
    );
    final provider = ProviderController.inMemory();
    final controller = RecordingSessionController(
      providerController: provider,
      recordingsDirectory: root,
      capture: _FakeCapture(),
    );
    addTearDown(() {
      controller.dispose();
      provider.dispose();
    });

    await controller.load();
    final afterFirstLoad = await wav.readAsBytes();
    await controller.load();

    expect(afterFirstLoad, original);
    expect(await wav.readAsBytes(), original);
    expect(controller.recordings.single.status, RecordingStatus.ready);
    expect(
      controller.recordings.single.audioIntegrityStatus,
      AudioIntegrityStatus.valid,
    );
  });

  test(
    'an interrupted PCM part is recovered without touching it first',
    () async {
      final directory = Directory('${root.path}/interrupted')..createSync();
      final wav = File('${directory.path}/audio.wav');
      final pcm = File('${directory.path}/audio.pcm.part');
      await pcm.writeAsBytes(List<int>.filled(3200, 7));
      await _writeEntry(
        directory,
        _entry(
          id: 'interrupted',
          audioPath: wav.path,
          status: RecordingStatus.recording,
        ),
      );
      final provider = ProviderController.inMemory();
      final controller = RecordingSessionController(
        providerController: provider,
        recordingsDirectory: root,
        capture: _FakeCapture(),
      );
      addTearDown(() {
        controller.dispose();
        provider.dispose();
      });

      await controller.load();

      expect(controller.recordings.single.status, RecordingStatus.recovered);
      expect(await pcm.exists(), isFalse);
      expect(
        (await WavAudioFile.validate(
          wav,
          requireCanonicalHeader: true,
        )).isValid,
        isTrue,
      );
    },
  );

  test(
    'a legacy interrupted WAV is recovered through a separate PCM copy',
    () async {
      final directory = Directory('${root.path}/legacy')..createSync();
      final wav = File('${directory.path}/audio.wav');
      final legacyBytes = Uint8List.fromList([
        ...WavAudioFile.header(0),
        ...List<int>.filled(3200, 9),
      ]);
      await wav.writeAsBytes(legacyBytes);
      await _writeEntry(
        directory,
        _entry(
          id: 'legacy',
          audioPath: wav.path,
          status: RecordingStatus.paused,
        ),
      );
      final provider = ProviderController.inMemory();
      final controller = RecordingSessionController(
        providerController: provider,
        recordingsDirectory: root,
        capture: _FakeCapture(),
      );
      addTearDown(() {
        controller.dispose();
        provider.dispose();
      });

      await controller.load();
      final validation = await WavAudioFile.validate(
        wav,
        requireCanonicalHeader: true,
      );

      expect(validation.isValid, isTrue);
      expect(validation.dataBytes, 3200);
      expect(controller.recordings.single.status, RecordingStatus.recovered);
      expect(await File('${wav.path}.legacy.pcm.part').exists(), isFalse);
    },
  );

  test(
    'a corrupt completed WAV is quarantined logically but stays byte-identical',
    () async {
      final directory = Directory('${root.path}/corrupt')..createSync();
      final wav = File('${directory.path}/audio.wav');
      final corrupt = WavAudioFile.header(0);
      final view = ByteData.sublistView(corrupt);
      view.setUint32(4, 0xfffffff8, Endian.little);
      view.setUint32(40, 0xffffffd4, Endian.little);
      await wav.writeAsBytes(corrupt);
      await _writeEntry(
        directory,
        _entry(
          id: 'corrupt',
          audioPath: wav.path,
          status: RecordingStatus.ready,
        ),
      );
      final provider = ProviderController.inMemory();
      final controller = RecordingSessionController(
        providerController: provider,
        recordingsDirectory: root,
        capture: _FakeCapture(),
      );
      addTearDown(() {
        controller.dispose();
        provider.dispose();
      });

      await controller.load();

      expect(await wav.readAsBytes(), corrupt);
      expect(controller.recordings.single.status, RecordingStatus.failed);
      expect(
        controller.recordings.single.audioIntegrityStatus,
        AudioIntegrityStatus.corrupt,
      );
    },
  );

  test('stop drains platform tail frames before finalizing the WAV', () async {
    final provider = ProviderController.inMemory();
    final capture = _FakeCapture(tailBytes: Uint8List.fromList([5, 6, 7, 8]));
    final controller = RecordingSessionController(
      providerController: provider,
      recordingsDirectory: root,
      capture: capture,
    );
    addTearDown(() {
      controller.dispose();
      provider.dispose();
    });

    await controller.start(realtimeEnabled: false);
    capture.add(Uint8List.fromList([1, 2, 3, 4]));
    final completed = await controller.stop();
    final bytes = await File(completed!.audioPath).readAsBytes();

    expect(completed.status, RecordingStatus.ready);
    expect(completed.pcmBytes, 8);
    expect(bytes.sublist(44), [1, 2, 3, 4, 5, 6, 7, 8]);
  });

  test(
    'platform stop failure leaves recoverable PCM instead of a fake WAV',
    () async {
      final provider = ProviderController.inMemory();
      final capture = _FakeCapture(
        stopError: StateError('platform stop failed'),
      );
      final controller = RecordingSessionController(
        providerController: provider,
        recordingsDirectory: root,
        capture: capture,
      );
      addTearDown(() {
        controller.dispose();
        provider.dispose();
      });

      await controller.start(realtimeEnabled: false);
      capture.add(Uint8List.fromList([1, 2, 3, 4]));
      await Future<void>.delayed(Duration.zero);
      final failed = await controller.stop();

      expect(failed!.status, RecordingStatus.failed);
      expect(await File(failed.audioPath).exists(), isFalse);
      expect(
        await File(
          '${File(failed.audioPath).parent.path}/audio.pcm.part',
        ).length(),
        4,
      );
    },
  );

  test('PCM volume drives audio level and pause resets it', () async {
    final provider = ProviderController.inMemory();
    final capture = _FakeCapture();
    final controller = RecordingSessionController(
      providerController: provider,
      recordingsDirectory: root,
      capture: capture,
    );
    addTearDown(() {
      controller.dispose();
      provider.dispose();
    });
    await controller.start(realtimeEnabled: false);

    capture.add(Uint8List(640));
    await Future<void>.delayed(Duration.zero);
    expect(controller.audioLevel, closeTo(0, 0.001));

    final voiced = ByteData(640);
    for (var offset = 0; offset < voiced.lengthInBytes; offset += 2) {
      voiced.setInt16(offset, 12000, Endian.little);
    }
    capture.add(voiced.buffer.asUint8List());
    await Future<void>.delayed(Duration.zero);
    expect(controller.audioLevel, greaterThan(0.5));

    await controller.pause();
    expect(controller.audioLevel, 0);
  });
}

RecordingEntry _entry({
  required String id,
  required String audioPath,
  required RecordingStatus status,
}) {
  final now = DateTime(2026, 7, 17, 12);
  return RecordingEntry(
    id: id,
    title: id,
    status: status,
    createdAt: now,
    updatedAt: now,
    audioPath: audioPath,
    durationMilliseconds: 0,
    realtimeEnabled: false,
    realtimeStatus: RealtimeRecordingStatus.disabled,
  );
}

Future<void> _writeEntry(Directory directory, RecordingEntry entry) => File(
  '${directory.path}/recording.json',
).writeAsString(jsonEncode(entry.toJson()));

class _FakeCapture implements RecordingCapture {
  _FakeCapture({this.tailBytes, this.stopError});

  final Uint8List? tailBytes;
  final Object? stopError;
  StreamController<Uint8List>? _controller;

  void add(Uint8List bytes) => _controller!.add(bytes);

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async {
    _controller = StreamController<Uint8List>();
    return _controller!.stream;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {
    if (stopError case final error?) throw error;
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    if (tailBytes case final bytes?) controller.add(bytes);
    await controller.close();
  }

  @override
  Future<void> dispose() async {
    final controller = _controller;
    if (controller != null && !controller.isClosed) await controller.close();
  }
}
