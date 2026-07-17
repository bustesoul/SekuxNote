import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../../app/storage/app_data_directory.dart';
import 'package:record/record.dart';

import '../providers/dashscope_realtime_client.dart';
import '../providers/provider_controller.dart';
import 'recording_background_service.dart';
import 'recording_models.dart';

class RecordingSessionController extends ChangeNotifier {
  RecordingSessionController({
    required ProviderController providerController,
    AudioRecorder? recorder,
    Directory? recordingsDirectory,
  }) : _providerController = providerController,
       _recorder = recorder ?? AudioRecorder(),
       _recordingsDirectory = recordingsDirectory;

  final ProviderController _providerController;
  final AudioRecorder _recorder;
  Directory? _recordingsDirectory;
  final List<RecordingEntry> _recordings = [];
  final Map<int, RealtimeTranscriptEvent> _sentences = {};
  StreamSubscription<Uint8List>? _audioSubscription;
  StreamSubscription<RealtimeTranscriptEvent>? _realtimeSubscription;
  DashScopeRealtimeClient? _realtimeClient;
  _WavStreamWriter? _writer;
  RecordingEntry? _active;
  Timer? _ticker;
  int _pcmBytes = 0;
  String _partialText = '';
  bool _loaded = false;

  List<RecordingEntry> get recordings =>
      List.unmodifiable(_recordings.reversed);
  RecordingEntry? get active => _active;
  bool get isRecording => _active?.status == RecordingStatus.recording;
  bool get isPaused => _active?.status == RecordingStatus.paused;
  String get partialText => _partialText;
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
        final recovered =
            entry.status == RecordingStatus.recording ||
                entry.status == RecordingStatus.paused
            ? entry.copyWith(
                status: RecordingStatus.recovered,
                realtimeStatus: RealtimeRecordingStatus.interrupted,
                updatedAt: DateTime.now(),
              )
            : entry;
        await _repairWavIfNeeded(File(recovered.audioPath));
        _recordings.add(recovered);
        if (recovered != entry) await _persist(recovered);
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
    if (!await _recorder.hasPermission()) {
      throw StateError('microphonePermissionDenied');
    }
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final directory = Directory('${(await _root()).path}/$id');
    await directory.create(recursive: true);
    final audioPath = '${directory.path}/audio.wav';
    _writer = _WavStreamWriter(File(audioPath));
    await _writer!.open();
    _pcmBytes = 0;
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
    );
    _active = entry;
    _recordings.add(entry);
    await _persist(entry);
    try {
      await RecordingBackgroundService.start(entry.title);
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ),
      );
      _audioSubscription = stream.listen(
        _onAudio,
        onError: (Object error, StackTrace stack) => _failCapture(error),
      );
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
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
      rethrow;
    }
  }

  Future<void> pause() async {
    final entry = _active;
    if (entry == null || entry.status != RecordingStatus.recording) return;
    await _recorder.pause();
    await _finishRealtime();
    _active = entry.copyWith(
      status: RecordingStatus.paused,
      durationMilliseconds: elapsedMilliseconds,
      updatedAt: DateTime.now(),
    );
    _replaceEntry(_active!);
    await _persist(_active!);
    notifyListeners();
  }

  Future<void> resume() async {
    final entry = _active;
    if (entry == null || entry.status != RecordingStatus.paused) return;
    await _recorder.resume();
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
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _recorder.stop();
    await RecordingBackgroundService.stop();
    await _writer?.close();
    _writer = null;
    await _finishRealtime();
    final completed = entry.copyWith(
      status: RecordingStatus.ready,
      durationMilliseconds: elapsedMilliseconds,
      realtimeStatus: entry.realtimeEnabled
          ? RealtimeRecordingStatus.completed
          : RealtimeRecordingStatus.disabled,
      realtimeTranscript: _completedTranscript(),
      updatedAt: DateTime.now(),
      clearError: true,
    );
    _active = null;
    _replaceEntry(completed);
    await _persist(completed);
    notifyListeners();
    return completed;
  }

  void _onAudio(Uint8List bytes) {
    try {
      _writer?.add(bytes);
      _pcmBytes += bytes.length;
      _realtimeClient?.sendAudio(bytes);
    } catch (error) {
      unawaited(_failCapture(error));
    }
  }

  Future<void> _connectRealtime() async {
    final entry = _active;
    if (entry == null || !entry.realtimeEnabled) return;
    try {
      final client = await _providerController.createDashScopeRealtimeClient();
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

  Future<void> _failCapture(Object error) async {
    final current = _active;
    if (current == null) return;
    try {
      await _recorder.stop();
    } catch (_) {}
    await RecordingBackgroundService.stop();
    await _writer?.close();
    _writer = null;
    _ticker?.cancel();
    _ticker = null;
    final failed = current.copyWith(
      status: RecordingStatus.failed,
      durationMilliseconds: elapsedMilliseconds,
      errorMessage: error.toString(),
      updatedAt: DateTime.now(),
    );
    _active = null;
    _replaceEntry(failed);
    await _persist(failed);
    notifyListeners();
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

  Future<void> _repairWavIfNeeded(File file) async {
    if (!await file.exists() || await file.length() < 44) return;
    final handle = await file.open(mode: FileMode.writeOnly);
    final dataBytes = await file.length() - 44;
    await handle.setPosition(0);
    await handle.writeFrom(_wavHeader(dataBytes));
    await handle.close();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_audioSubscription?.cancel());
    unawaited(_realtimeSubscription?.cancel());
    unawaited(_realtimeClient?.dispose());
    unawaited(_recorder.dispose());
    _writer?.closeSync();
    super.dispose();
  }
}

class _WavStreamWriter {
  _WavStreamWriter(this.file);

  final File file;
  RandomAccessFile? _handle;
  int _dataBytes = 0;

  Future<void> open() async {
    _handle = await file.open(mode: FileMode.write);
    await _handle!.writeFrom(_wavHeader(0));
  }

  void add(Uint8List bytes) {
    _handle?.writeFromSync(bytes);
    _dataBytes += bytes.length;
  }

  Future<void> close() async {
    final handle = _handle;
    _handle = null;
    if (handle == null) return;
    await handle.setPosition(0);
    await handle.writeFrom(_wavHeader(_dataBytes));
    await handle.flush();
    await handle.close();
  }

  void closeSync() {
    final handle = _handle;
    _handle = null;
    if (handle == null) return;
    handle.setPositionSync(0);
    handle.writeFromSync(_wavHeader(_dataBytes));
    handle.flushSync();
    handle.closeSync();
  }
}

Uint8List _wavHeader(int dataBytes) {
  final data = ByteData(44);
  void ascii(int offset, String value) {
    for (var index = 0; index < value.length; index += 1) {
      data.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 16000, Endian.little);
  data.setUint32(28, 32000, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, dataBytes, Endian.little);
  return data.buffer.asUint8List();
}
