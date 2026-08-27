import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../../app/storage/app_data_directory.dart';
import '../providers/provider_controller.dart';
import '../providers/realtime_transcription_client.dart';
import 'recording_background_service.dart';
import 'recording_models.dart';
import 'wav_audio_file.dart';

class RecordingSessionController extends ChangeNotifier {
  RecordingSessionController({
    required ProviderController providerController,
    RecordingCapture? capture,
    Directory? recordingsDirectory,
  }) : _providerController = providerController,
       _capture = capture ?? RecordPluginCapture(),
       _recordingsDirectory = recordingsDirectory;

  final ProviderController _providerController;
  final RecordingCapture _capture;
  Directory? _recordingsDirectory;
  final List<RecordingEntry> _recordings = [];
  final Map<int, RealtimeTranscriptEvent> _sentences = {};
  StreamSubscription<Uint8List>? _audioSubscription;
  StreamSubscription<RealtimeTranscriptEvent>? _realtimeSubscription;
  RealtimeTranscriptionClient? _realtimeClient;
  _PcmStreamWriter? _writer;
  Completer<void>? _audioDone;
  RecordingEntry? _active;
  Timer? _ticker;
  int _pcmBytes = 0;
  double _audioLevel = 0;
  int _lastAudioLevelNotificationMicros = 0;
  String _partialText = '';
  bool _loaded = false;

  List<RecordingEntry> get recordings =>
      List.unmodifiable(_recordings.reversed);
  RecordingEntry? get active => _active;
  bool get isRecording => _active?.status == RecordingStatus.recording;
  bool get isPaused => _active?.status == RecordingStatus.paused;
  String get partialText => _partialText;
  double get audioLevel => _audioLevel;
  int get elapsedMilliseconds => (_pcmBytes * 1000) ~/ 32000;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final root = await _root();
    if (!await root.exists()) {
      await root.create(recursive: true);
      return;
    }
    await for (final entity in root.list()) {
      if (entity is! Directory) continue;
      final metadata = File('${entity.path}/recording.json');
      if (!await metadata.exists()) continue;
      try {
        final entry = RecordingEntry.fromJson(
          Map<String, Object?>.from(
            jsonDecode(await metadata.readAsString()) as Map,
          ),
        );
        final recovered = await _recoverOrValidateEntry(entry);
        _recordings.add(recovered);
        if (!mapEquals(recovered.toJson(), entry.toJson())) {
          await _persist(recovered);
        }
      } catch (_) {
        // A malformed metadata file is isolated; other recordings remain usable.
      }
    }
    _recordings.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();
  }

  Future<void> start({String? title, bool realtimeEnabled = true}) async {
    if (_active != null) throw StateError('recordingAlreadyActive');
    await load();
    if (!await _capture.hasPermission()) {
      throw StateError('microphonePermissionDenied');
    }
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final directory = Directory('${(await _root()).path}/$id');
    await directory.create(recursive: true);
    final audioPath = '${directory.path}/audio.wav';
    _writer = _PcmStreamWriter(File('${directory.path}/audio.pcm.part'));
    await _writer!.open();
    _pcmBytes = 0;
    _audioLevel = 0;
    _lastAudioLevelNotificationMicros = 0;
    _sentences.clear();
    _partialText = '';
    final entry = RecordingEntry(
      id: id,
      title: title?.trim().isNotEmpty == true
          ? title!.trim()
          : '录音 ${now.toLocal().toString().substring(0, 16)}',
      status: RecordingStatus.recording,
      createdAt: now,
      updatedAt: now,
      audioPath: audioPath,
      durationMilliseconds: 0,
      realtimeEnabled: realtimeEnabled,
      realtimeStatus: realtimeEnabled
          ? RealtimeRecordingStatus.connecting
          : RealtimeRecordingStatus.disabled,
      audioIntegrityStatus: AudioIntegrityStatus.recording,
    );
    _active = entry;
    _recordings.add(entry);
    await _persist(entry);
    try {
      await RecordingBackgroundService.start(entry.title);
      final stream = await _capture.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ),
      );
      _audioDone = Completer<void>();
      _audioSubscription = stream.listen(
        _onAudio,
        onError: (Object error, StackTrace stack) => _failCapture(error),
        onDone: () {
          final done = _audioDone;
          if (done != null && !done.isCompleted) done.complete();
        },
      );
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _writer?.flushSync();
        notifyListeners();
      });
      if (realtimeEnabled) unawaited(_connectRealtime());
      notifyListeners();
    } catch (error) {
      await _writer?.close();
      await RecordingBackgroundService.stop();
      _writer = null;
      _active = entry.copyWith(
        status: RecordingStatus.failed,
        errorMessage: error.toString(),
        updatedAt: DateTime.now(),
      );
      _replaceEntry(_active!);
      await _persist(_active!);
      _active = null;
      _audioLevel = 0;
      rethrow;
    }
  }

  Future<void> pause() async {
    final entry = _active;
    if (entry == null || entry.status != RecordingStatus.recording) return;
    await _capture.pause();
    _writer?.flushSync();
    _audioLevel = 0;
    await _finishRealtime();
    _active = entry.copyWith(
      status: RecordingStatus.paused,
      durationMilliseconds: elapsedMilliseconds,
      pcmBytes: _pcmBytes,
      updatedAt: DateTime.now(),
    );
    _replaceEntry(_active!);
    await _persist(_active!);
    notifyListeners();
  }

  Future<void> resume() async {
    final entry = _active;
    if (entry == null || entry.status != RecordingStatus.paused) return;
    await _capture.resume();
    _active = entry.copyWith(
      status: RecordingStatus.recording,
      realtimeStatus: entry.realtimeEnabled
          ? RealtimeRecordingStatus.connecting
          : RealtimeRecordingStatus.disabled,
      updatedAt: DateTime.now(),
    );
    _replaceEntry(_active!);
    await _persist(_active!);
    if (entry.realtimeEnabled) unawaited(_connectRealtime());
    notifyListeners();
  }

  Future<RecordingEntry?> stop() async {
    final entry = _active;
    if (entry == null) return null;
    _ticker?.cancel();
    _ticker = null;
    try {
      await _capture.stop();
    } catch (error) {
      return _failCapture(error, stopCapture: false);
    }
    try {
      await _audioDone?.future.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      // Some platform streams do not emit done after stop. The recorder has
      // already stopped, so cancellation is now safe and cannot drop live data.
    }
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    _audioDone = null;
    try {
      await _writer?.close();
    } catch (error) {
      return _failCapture(error, stopCapture: false);
    }
    _writer = null;
    try {
      await RecordingBackgroundService.stop();
    } catch (_) {
      // A notification/service cleanup failure must not discard valid audio.
    }
    Object? realtimeFinishError;
    try {
      await _finishRealtime();
    } catch (error) {
      realtimeFinishError = error;
    }
    final validation = await WavAudioFile.finalizePcm(
      pcmFile: File('${File(entry.audioPath).parent.path}/audio.pcm.part'),
      wavFile: File(entry.audioPath),
    );
    if (!validation.isValid) {
      final failed = entry.copyWith(
        status: RecordingStatus.failed,
        durationMilliseconds: elapsedMilliseconds,
        pcmBytes: _pcmBytes,
        audioFileSize: validation.fileBytes,
        audioIntegrityStatus: AudioIntegrityStatus.corrupt,
        errorMessage: 'recordingAudioCorrupt',
        updatedAt: DateTime.now(),
      );
      _active = null;
      _audioLevel = 0;
      _replaceEntry(failed);
      await _persist(failed);
      notifyListeners();
      return failed;
    }
    final completed = entry.copyWith(
      status: RecordingStatus.ready,
      durationMilliseconds: validation.durationMilliseconds,
      realtimeStatus: entry.realtimeEnabled
          ? realtimeFinishError == null
                ? RealtimeRecordingStatus.completed
                : RealtimeRecordingStatus.interrupted
          : RealtimeRecordingStatus.disabled,
      realtimeTranscript: _completedTranscript(),
      pcmBytes: validation.dataBytes,
      audioFileSize: validation.fileBytes,
      audioIntegrityStatus: AudioIntegrityStatus.valid,
      updatedAt: DateTime.now(),
      errorMessage: realtimeFinishError?.toString(),
      clearError: realtimeFinishError == null,
    );
    _active = null;
    _audioLevel = 0;
    _replaceEntry(completed);
    await _persist(completed);
    notifyListeners();
    return completed;
  }

  Future<void> deleteRecording(String id) async {
    await load();
    if (_active?.id == id) throw StateError('recordingIsActive');
    final index = _recordings.indexWhere((entry) => entry.id == id);
    if (index < 0) return;

    final directory = Directory('${(await _root()).path}/$id');
    if (await directory.exists()) await directory.delete(recursive: true);
    _recordings.removeAt(index);
    notifyListeners();
  }

  void _onAudio(Uint8List bytes) {
    try {
      _writer?.add(bytes);
      _pcmBytes += bytes.length;
      _updateAudioLevel(bytes);
      _realtimeClient?.sendAudio(bytes);
    } catch (error) {
      unawaited(_failCapture(error));
    }
  }

  Future<void> _connectRealtime() async {
    final entry = _active;
    if (entry == null || !entry.realtimeEnabled) return;
    try {
      final client = await _providerController.createRealtimeClient();
      _realtimeClient = client;
      _realtimeSubscription = client.events.listen(
        (event) {
          _sentences[event.sentenceId] = event;
          _partialText = event.isFinal ? '' : event.text;
          if (event.isFinal) {
            final current = _active;
            if (current != null) {
              _active = current.copyWith(
                realtimeTranscript: _completedTranscript(),
                updatedAt: DateTime.now(),
              );
              _replaceEntry(_active!);
              unawaited(_persist(_active!));
            }
          }
          notifyListeners();
        },
        onError: (Object error, StackTrace stack) {
          _markRealtimeInterrupted(error);
        },
      );
      await client.connect();
      final current = _active;
      if (current != null) {
        _active = current.copyWith(
          realtimeStatus: RealtimeRecordingStatus.streaming,
          updatedAt: DateTime.now(),
          clearError: true,
        );
        _replaceEntry(_active!);
        await _persist(_active!);
        notifyListeners();
      }
    } catch (error) {
      _markRealtimeInterrupted(error);
    }
  }

  void _markRealtimeInterrupted(Object error) {
    final current = _active;
    if (current == null) return;
    _active = current.copyWith(
      realtimeStatus: RealtimeRecordingStatus.interrupted,
      errorMessage: error.toString(),
      updatedAt: DateTime.now(),
    );
    _replaceEntry(_active!);
    unawaited(_persist(_active!));
    notifyListeners();
  }

  Future<void> _finishRealtime() async {
    final client = _realtimeClient;
    _realtimeClient = null;
    if (client != null) {
      await client.finish();
    }
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    if (client != null) await client.dispose();
  }

  Future<RecordingEntry?> _failCapture(
    Object error, {
    bool stopCapture = true,
  }) async {
    final current = _active;
    if (current == null) return null;
    if (stopCapture) {
      try {
        await _capture.stop();
      } catch (_) {}
    }
    try {
      await _audioSubscription?.cancel();
    } catch (_) {}
    _audioSubscription = null;
    _audioDone = null;
    try {
      await RecordingBackgroundService.stop();
    } catch (_) {}
    try {
      await _writer?.close();
    } catch (_) {}
    _writer = null;
    _ticker?.cancel();
    _ticker = null;
    final failed = current.copyWith(
      status: RecordingStatus.failed,
      durationMilliseconds: elapsedMilliseconds,
      pcmBytes: _pcmBytes,
      audioIntegrityStatus: AudioIntegrityStatus.unknown,
      errorMessage: error.toString(),
      updatedAt: DateTime.now(),
    );
    _active = null;
    _audioLevel = 0;
    _replaceEntry(failed);
    await _persist(failed);
    notifyListeners();
    return failed;
  }

  void _updateAudioLevel(Uint8List bytes) {
    if (_active?.status != RecordingStatus.recording || bytes.length < 2) {
      return;
    }
    final view = ByteData.sublistView(bytes);
    var sumSquares = 0.0;
    var samples = 0;
    for (var offset = 0; offset + 1 < bytes.length; offset += 2) {
      final normalized = view.getInt16(offset, Endian.little) / 32768.0;
      sumSquares += normalized * normalized;
      samples += 1;
    }
    if (samples == 0) return;
    final rms = math.sqrt(sumSquares / samples);
    final aboveNoiseFloor = ((rms - 0.006) / 0.18).clamp(0.0, 1.0);
    final measured = math.pow(aboveNoiseFloor, 0.65).toDouble();
    _audioLevel = measured > _audioLevel
        ? _audioLevel * 0.25 + measured * 0.75
        : _audioLevel * 0.72 + measured * 0.28;

    final now = DateTime.now().microsecondsSinceEpoch;
    if (now - _lastAudioLevelNotificationMicros >= 50000) {
      _lastAudioLevelNotificationMicros = now;
      notifyListeners();
    }
  }

  String _completedTranscript() {
    final values = _sentences.values.where((event) => event.isFinal).toList()
      ..sort((a, b) => a.sentenceId.compareTo(b.sentenceId));
    return values.map((event) => event.text).join('\n');
  }

  void _replaceEntry(RecordingEntry entry) {
    final index = _recordings.indexWhere((value) => value.id == entry.id);
    if (index >= 0) _recordings[index] = entry;
  }

  Future<Directory> _root() async {
    final configured = _recordingsDirectory;
    if (configured != null) return configured;
    final dataDirectory = await getSekuxNoteDataDirectory();
    return _recordingsDirectory = Directory('${dataDirectory.path}/recordings');
  }

  Future<void> _persist(RecordingEntry entry) async {
    final directory = Directory('${(await _root()).path}/${entry.id}');
    await directory.create(recursive: true);
    final temporary = File('${directory.path}/recording.json.tmp');
    final target = File('${directory.path}/recording.json');
    await temporary.writeAsString(jsonEncode(entry.toJson()), flush: true);
    await temporary.rename(target.path);
  }

  Future<RecordingEntry> _recoverOrValidateEntry(RecordingEntry entry) async {
    final wavFile = File(entry.audioPath);
    final pcmFile = File('${wavFile.parent.path}/audio.pcm.part');
    final interrupted =
        entry.status == RecordingStatus.recording ||
        entry.status == RecordingStatus.paused;
    WavValidation validation;
    var wasRecovered = false;

    if (await pcmFile.exists() && await pcmFile.length() > 0) {
      validation = await WavAudioFile.finalizePcm(
        pcmFile: pcmFile,
        wavFile: wavFile,
      );
      wasRecovered = validation.isValid;
    } else {
      validation = await WavAudioFile.validate(
        wavFile,
        requireCanonicalHeader: true,
      );
      if (!validation.isValid && interrupted && validation.fileBytes > 44) {
        validation = await WavAudioFile.recoverLegacyInterruptedFile(wavFile);
        wasRecovered = validation.isValid;
      }
    }

    if (!validation.isValid) {
      return entry.copyWith(
        status: RecordingStatus.failed,
        realtimeStatus: interrupted
            ? RealtimeRecordingStatus.interrupted
            : entry.realtimeStatus,
        pcmBytes: validation.dataBytes,
        audioFileSize: validation.fileBytes,
        audioIntegrityStatus: AudioIntegrityStatus.corrupt,
        errorMessage: 'recordingAudioCorrupt',
        updatedAt: DateTime.now(),
      );
    }
    return entry.copyWith(
      status: interrupted || wasRecovered
          ? RecordingStatus.recovered
          : entry.status,
      realtimeStatus: interrupted
          ? RealtimeRecordingStatus.interrupted
          : entry.realtimeStatus,
      durationMilliseconds: validation.durationMilliseconds,
      pcmBytes: validation.dataBytes,
      audioFileSize: validation.fileBytes,
      audioIntegrityStatus: interrupted || wasRecovered
          ? AudioIntegrityStatus.recovered
          : AudioIntegrityStatus.valid,
      updatedAt: interrupted || wasRecovered ? DateTime.now() : entry.updatedAt,
      clearError: interrupted || wasRecovered,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_audioSubscription?.cancel());
    unawaited(_realtimeSubscription?.cancel());
    unawaited(_realtimeClient?.dispose());
    unawaited(_capture.dispose());
    _writer?.closeSync();
    super.dispose();
  }
}

abstract interface class RecordingCapture {
  Future<bool> hasPermission();

  Future<Stream<Uint8List>> startStream(RecordConfig config);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> dispose();
}

class RecordPluginCapture implements RecordingCapture {
  RecordPluginCapture({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) =>
      _recorder.startStream(config);

  @override
  Future<void> pause() => _recorder.pause();

  @override
  Future<void> resume() => _recorder.resume();

  @override
  Future<void> stop() async {
    await _recorder.stop();
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}

class _PcmStreamWriter {
  _PcmStreamWriter(this.file);

  final File file;
  RandomAccessFile? _handle;

  Future<void> open() async {
    _handle = await file.open(mode: FileMode.writeOnly);
  }

  void add(Uint8List bytes) {
    _handle?.writeFromSync(bytes);
  }

  Future<void> close() async {
    final handle = _handle;
    _handle = null;
    if (handle == null) return;
    await handle.flush();
    await handle.close();
  }

  void closeSync() {
    final handle = _handle;
    _handle = null;
    if (handle == null) return;
    handle.flushSync();
    handle.closeSync();
  }

  void flushSync() => _handle?.flushSync();
}
