import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'audio_chunker.dart';
import 'dashscope_realtime_client.dart';
import 'openai_api_client.dart';
import 'provider_models.dart';
import 'provider_storage.dart';
import 'task_audio_store.dart';

class ProviderController extends ChangeNotifier {
  ProviderController({
    required ProviderSettingsStore settingsStore,
    required CredentialStore credentialStore,
    required TranscriptionTaskStore taskStore,
    required OpenAiApiClient apiClient,
    AudioChunker? audioChunker,
    TaskAudioStore? taskAudioStore,
  }) : _settingsStore = settingsStore,
       _credentialStore = credentialStore,
       _taskStore = taskStore,
       _apiClient = apiClient,
       _audioChunker = audioChunker ?? PlatformAudioChunker(),
       _taskAudioStore = taskAudioStore ?? SandboxedTaskAudioStore();

  factory ProviderController.inMemory() {
    return ProviderController(
      settingsStore: MemoryProviderSettingsStore(),
      credentialStore: MemoryCredentialStore(),
      taskStore: MemoryTranscriptionTaskStore(),
      apiClient: OpenAiApiClient(),
      taskAudioStore: MemoryTaskAudioStore(),
    );
  }

  static Future<ProviderController> createPersistent() async {
    final store = await SqliteProviderStore.open();
    final controller = ProviderController(
      settingsStore: store,
      credentialStore: store,
      taskStore: store,
      apiClient: OpenAiApiClient(),
      taskAudioStore: SandboxedTaskAudioStore(),
    );
    await controller.load();
    return controller;
  }

  final ProviderSettingsStore _settingsStore;
  final CredentialStore _credentialStore;
  final TranscriptionTaskStore _taskStore;
  final OpenAiApiClient _apiClient;
  final AudioChunker _audioChunker;
  final TaskAudioStore _taskAudioStore;
  final Map<String, _TaskRun> _taskRuns = {};

  TextProviderSettings _textSettings = TextProviderSettings.defaults();
  TranscriptionProviderSettings _transcriptionSettings =
      TranscriptionProviderSettings.defaults();
  final Set<String> _configuredTextCredentialRefs = {};
  final Set<String> _configuredTranscriptionCredentialRefs = {};

  TextProviderSettings get textSettings => _textSettings;
  TextProviderConfig get textConfig => _textSettings.defaultProvider;
  TranscriptionProviderSettings get transcriptionSettings =>
      _transcriptionSettings;
  TranscriptionProviderConfig get transcriptionConfig =>
      _transcriptionSettings.defaultProvider;
  bool get textCredentialConfigured =>
      _configuredTextCredentialRefs.contains(textConfig.credentialRef);
  bool get transcriptionCredentialConfigured =>
      _configuredTranscriptionCredentialRefs.contains(
        transcriptionConfig.credentialRef,
      );
  Future<bool> transcriptionCredentialConfiguredFor(String providerId) async {
    final provider = transcriptionProviderById(providerId);
    if (provider == null) return false;
    return (await _credentialStore.read(provider.credentialRef))?.isNotEmpty ??
        false;
  }

  TranscriptionProviderConfig? transcriptionProviderById(String id) {
    for (final provider in _transcriptionSettings.providers) {
      if (provider.id == id) return provider;
    }
    return null;
  }

  TextProviderConfig? textProviderById(String id) {
    for (final provider in _textSettings.providers) {
      if (provider.id == id) return provider;
    }
    return null;
  }

  Future<bool> textCredentialConfiguredFor(String providerId) async {
    final provider = textProviderById(providerId);
    if (provider == null) return false;
    return (await _credentialStore.read(provider.credentialRef))?.isNotEmpty ??
        false;
  }

  Future<void> load() async {
    _textSettings = await _settingsStore.readTextSettings();
    _transcriptionSettings = await _settingsStore.readTranscriptionSettings();
    _configuredTextCredentialRefs
      ..clear()
      ..addAll(
        (await Future.wait(
          _textSettings.providers.map((provider) async {
            final configured =
                (await _credentialStore.read(
                  provider.credentialRef,
                ))?.isNotEmpty ??
                false;
            return configured ? provider.credentialRef : null;
          }),
        )).whereType<String>(),
      );
    _configuredTranscriptionCredentialRefs
      ..clear()
      ..addAll(
        (await Future.wait(
          _transcriptionSettings.providers.map((provider) async {
            final configured =
                (await _credentialStore.read(
                  provider.credentialRef,
                ))?.isNotEmpty ??
                false;
            return configured ? provider.credentialRef : null;
          }),
        )).whereType<String>(),
      );
    final unfinished = (await _taskStore.list()).where(
      (task) =>
          task.status == TranscriptionTaskStatus.queued ||
          task.status == TranscriptionTaskStatus.running,
    );
    for (final task in unfinished) {
      final canResumeRemote =
          task.providerType == TranscriptionProviderType.dashScopeFunAsr &&
          !task.model.startsWith('fun-asr-flash') &&
          task.remoteTaskId?.isNotEmpty == true;
      if (canResumeRemote) {
        unawaited(_resumeDashScopeTask(task));
      } else {
        await _taskStore.update(
          task.copyWith(
            status: TranscriptionTaskStatus.failed,
            updatedAt: DateTime.now(),
            errorMessage: 'taskInterrupted',
          ),
        );
      }
    }
    notifyListeners();
  }

  Future<void> saveText({
    String? providerId,
    required String name,
    required bool enabled,
    required String baseUrl,
    required String model,
    TextProviderProtocol? protocol,
    List<String>? models,
    String? apiKey,
  }) async {
    final id = providerId ?? _textSettings.defaultProviderId;
    final existing = textProviderById(id);
    if (existing == null) throw ArgumentError.value(id, 'providerId');
    final normalizedModels = <String>{
      ...?models
          ?.map((value) => value.trim())
          .where((value) => value.isNotEmpty),
      model.trim(),
    }.toList(growable: false);
    final updated = existing.copyWith(
      name: name.trim(),
      enabled: enabled,
      baseUrl: baseUrl.trim(),
      model: model.trim(),
      protocol: protocol,
      models: normalizedModels,
    );
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      await _credentialStore.write(updated.credentialRef, apiKey.trim());
      _configuredTextCredentialRefs.add(updated.credentialRef);
    }
    _textSettings = _textSettings.copyWith(
      providers: _textSettings.providers
          .map((provider) => provider.id == id ? updated : provider)
          .toList(growable: false),
    );
    await _settingsStore.writeTextSettings(_textSettings);
    notifyListeners();
  }

  Future<TextProviderConfig> addTextProvider() async {
    final id = 'text-${DateTime.now().microsecondsSinceEpoch}';
    final provider = TextProviderConfig.openAiCompatible(id: id);
    _textSettings = _textSettings.copyWith(
      providers: [..._textSettings.providers, provider],
    );
    await _settingsStore.writeTextSettings(_textSettings);
    notifyListeners();
    return provider;
  }

  Future<void> setDefaultTextProvider(String providerId) async {
    if (textProviderById(providerId) == null) {
      throw ArgumentError.value(providerId, 'providerId');
    }
    _textSettings = _textSettings.copyWith(defaultProviderId: providerId);
    await _settingsStore.writeTextSettings(_textSettings);
    notifyListeners();
  }

  Future<void> deleteTextProvider(String providerId) async {
    if (_textSettings.providers.length == 1) return;
    final target = textProviderById(providerId);
    if (target == null) return;
    final providers = _textSettings.providers
        .where((provider) => provider.id != providerId)
        .toList(growable: false);
    _textSettings = TextProviderSettings(
      providers: providers,
      defaultProviderId: _textSettings.defaultProviderId == providerId
          ? providers.first.id
          : _textSettings.defaultProviderId,
    );
    await _credentialStore.delete(target.credentialRef);
    _configuredTextCredentialRefs.remove(target.credentialRef);
    await _settingsStore.writeTextSettings(_textSettings);
    notifyListeners();
  }

  Future<void> saveTranscription({
    String? providerId,
    required String name,
    required bool enabled,
    required String baseUrl,
    required String batchModel,
    String? fastFileModel,
    String? realtimeModel,
    required String language,
    required int chunkDurationSeconds,
    required int maxConcurrentUploads,
    String? dashScopeApiUrl,
    String? apiKey,
  }) async {
    final id = providerId ?? _transcriptionSettings.defaultProviderId;
    final existing = transcriptionProviderById(id);
    if (existing == null) throw ArgumentError.value(id, 'providerId');
    final updated = existing.copyWith(
      name: name.trim(),
      enabled: enabled,
      baseUrl: baseUrl.trim(),
      batchModel: batchModel.trim(),
      fastFileModel: fastFileModel?.trim(),
      realtimeModel: realtimeModel?.trim(),
      language: language.trim(),
      chunkDurationSeconds: chunkDurationSeconds,
      maxConcurrentUploads: maxConcurrentUploads,
      dashScopeApiUrl: dashScopeApiUrl?.trim(),
    );
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      await _credentialStore.write(updated.credentialRef, apiKey.trim());
      _configuredTranscriptionCredentialRefs.add(updated.credentialRef);
    }
    _transcriptionSettings = _transcriptionSettings.copyWith(
      providers: _transcriptionSettings.providers
          .map((provider) => provider.id == id ? updated : provider)
          .toList(growable: false),
    );
    await _settingsStore.writeTranscriptionSettings(_transcriptionSettings);
    notifyListeners();
  }

  Future<TranscriptionProviderConfig> addTranscriptionProvider(
    TranscriptionProviderType type,
  ) async {
    final id = 'transcription-${DateTime.now().microsecondsSinceEpoch}';
    final provider = switch (type) {
      TranscriptionProviderType.openAiCompatible =>
        TranscriptionProviderConfig.defaults().copyWith(name: 'OpenAI 兼容'),
      TranscriptionProviderType.dashScopeFunAsr =>
        TranscriptionProviderConfig.dashScopeDefaults(id: id),
    };
    final withId = type == TranscriptionProviderType.openAiCompatible
        ? TranscriptionProviderConfig(
            id: id,
            type: provider.type,
            name: provider.name,
            enabled: provider.enabled,
            credentialRef: 'sekuxnote.transcription.$id',
            baseUrl: provider.baseUrl,
            batchModel: provider.batchModel,
            fastFileModel: provider.fastFileModel,
            realtimeModel: provider.realtimeModel,
            language: provider.language,
            chunkDurationSeconds: provider.chunkDurationSeconds,
            maxConcurrentUploads: provider.maxConcurrentUploads,
            capabilities: provider.capabilities,
          )
        : provider;
    _transcriptionSettings = _transcriptionSettings.copyWith(
      providers: [..._transcriptionSettings.providers, withId],
    );
    await _settingsStore.writeTranscriptionSettings(_transcriptionSettings);
    notifyListeners();
    return withId;
  }

  Future<void> setDefaultTranscriptionProvider(String providerId) async {
    if (transcriptionProviderById(providerId) == null) {
      throw ArgumentError.value(providerId, 'providerId');
    }
    _transcriptionSettings = _transcriptionSettings.copyWith(
      defaultProviderId: providerId,
    );
    await _settingsStore.writeTranscriptionSettings(_transcriptionSettings);
    notifyListeners();
  }

  Future<ApiOperationResult> testText({String? providerId}) async {
    final config = textProviderById(
      providerId ?? _textSettings.defaultProviderId,
    );
    if (config == null) throw const ProviderRequestException('providerMissing');
    _ensureEnabled(config.enabled);
    final key = await _requiredKey(config.credentialRef);
    return _apiClient.testText(config: config, apiKey: key);
  }

  Stream<TextGenerationChunk> streamText({
    required List<TextChatMessage> messages,
    String? providerId,
    String? model,
  }) async* {
    final config = textProviderById(
      providerId ?? _textSettings.defaultProviderId,
    );
    if (config == null) throw const ProviderRequestException('providerMissing');
    _ensureEnabled(config.enabled);
    final key = await _requiredKey(config.credentialRef);
    yield* _apiClient.streamText(
      config: config,
      apiKey: key,
      model: model?.trim().isNotEmpty == true ? model!.trim() : config.model,
      messages: messages,
    );
  }

  Future<TranscriptionResult> transcribe(
    SelectedAudioFile file, {
    String? providerId,
    TranscriptionRequestOptions? options,
  }) async {
    final config = transcriptionProviderById(
      providerId ?? _transcriptionSettings.defaultProviderId,
    );
    if (config == null) throw const ProviderRequestException('providerMissing');
    _ensureEnabled(config.enabled);
    final key = await _requiredKey(config.credentialRef);
    return _apiClient.transcribe(
      config: config,
      apiKey: key,
      file: file,
      options:
          options ?? TranscriptionRequestOptions(language: config.language),
    );
  }

  Future<List<TranscriptionTask>> listTranscriptionTasks() => _taskStore.list();

  Future<DashScopeRealtimeClient> createDashScopeRealtimeClient({
    String? providerId,
  }) async {
    final config = transcriptionProviderById(
      providerId ?? _transcriptionSettings.defaultProviderId,
    );
    if (config == null) throw const ProviderRequestException('providerMissing');
    if (config.type != TranscriptionProviderType.dashScopeFunAsr) {
      throw const ProviderRequestException('realtimeProviderUnsupported');
    }
    _ensureEnabled(config.enabled);
    final key = await _requiredKey(config.credentialRef);
    return DashScopeRealtimeClient(config: config, apiKey: key);
  }

  /// Retries are additional attempts: the first request plus up to three
  /// retries. Authentication and input errors are intentionally not retried.
  static const maxAutomaticChunkRetries = 3;
  static const _singleUploadLimitBytes = 25 * 1024 * 1024;

  Future<TranscriptionTask> startTranscriptionTask(
    SelectedAudioFile file, {
    String? providerId,
    String? language,
    bool diarizationEnabled = false,
    int? speakerCount,
    TranscriptionFileMode fileMode = TranscriptionFileMode.precision,
    void Function({required int total, required int completed})? onProgress,
    void Function(String text)? onPartialText,
  }) async {
    final config = transcriptionProviderById(
      providerId ?? _transcriptionSettings.defaultProviderId,
    );
    if (config == null) throw const ProviderRequestException('providerMissing');
    final now = DateTime.now();
    var task = TranscriptionTask(
      id: '${now.microsecondsSinceEpoch}-${file.sizeBytes}',
      fileName: file.name,
      providerId: config.id,
      providerType: config.type,
      providerName: config.name,
      model:
          fileMode == TranscriptionFileMode.fast &&
              config.fastFileModel?.trim().isNotEmpty == true
          ? config.fastFileModel!.trim()
          : config.batchModel,
      status: TranscriptionTaskStatus.queued,
      createdAt: now,
      updatedAt: now,
      chunksTotal: 0,
      chunksCompleted: 0,
      language: language?.trim().isNotEmpty == true
          ? language!.trim()
          : config.language,
      diarizationEnabled: diarizationEnabled,
      speakerCount: speakerCount,
    );
    await _taskStore.create(task);
    notifyListeners();
    try {
      final sourcePath = await _taskAudioStore.save(task.id, file);
      task = await _updateTask(task, sourcePath: sourcePath);
      return _runTask(
        task,
        file,
        onProgress: onProgress,
        onPartialText: onPartialText,
      );
    } catch (error) {
      return _updateTask(
        task,
        status: TranscriptionTaskStatus.failed,
        errorMessage: _taskErrorCode(error),
      );
    }
  }

  Future<TranscriptionTask> retryTranscriptionTask(String taskId) async {
    final task = await _taskById(taskId);
    if (task == null || task.status == TranscriptionTaskStatus.running) {
      return task ?? (throw ArgumentError.value(taskId, 'taskId'));
    }
    final sourcePath = task.sourcePath;
    if (sourcePath == null) {
      return _updateTask(
        task,
        status: TranscriptionTaskStatus.failed,
        errorMessage: 'sourceAudioMissing',
      );
    }
    try {
      final source = await _taskAudioStore.read(
        sourcePath,
        fileName: task.fileName,
      );
      return _runTask(task, source);
    } catch (error) {
      return _updateTask(
        task,
        status: TranscriptionTaskStatus.failed,
        errorMessage: 'sourceAudioMissing',
      );
    }
  }

  Future<void> stopTranscriptionTask(String taskId) async {
    _taskRuns[taskId]?.stopRequested = true;
    final task = await _taskById(taskId);
    if (task == null || task.isTerminal) return;
    for (final chunk in await _taskStore.listChunks(taskId)) {
      if (chunk.status == TranscriptionTaskChunkStatus.pending ||
          chunk.status == TranscriptionTaskChunkStatus.running) {
        await _taskStore.updateChunk(
          chunk.copyWith(status: TranscriptionTaskChunkStatus.stopped),
        );
      }
    }
    await _updateTask(task, status: TranscriptionTaskStatus.stopped);
  }

  /// Permanently removes a completed task and its local retry source audio.
  /// Active tasks must be stopped first so a background run cannot write it back.
  Future<void> deleteTranscriptionTask(String taskId) async {
    final task = await _taskById(taskId);
    if (task == null) return;
    if (!task.isTerminal) {
      throw StateError('transcriptionTaskStillRunning');
    }
    await _taskStore.deleteTask(taskId);
    await _taskAudioStore.delete(taskId);
    notifyListeners();
  }

  Future<TranscriptionTask> _runTask(
    TranscriptionTask task,
    SelectedAudioFile source, {
    void Function({required int total, required int completed})? onProgress,
    void Function(String text)? onPartialText,
  }) async {
    final savedProvider = transcriptionProviderById(task.providerId);
    if (savedProvider == null) {
      return _updateTask(
        task,
        status: TranscriptionTaskStatus.failed,
        errorMessage: 'providerMissing',
      );
    }
    final config = savedProvider.copyWith(
      batchModel: task.model,
      language: task.language,
    );
    final run = _TaskRun();
    _taskRuns[task.id] = run;
    try {
      _ensureEnabled(config.enabled);
      final key = await _requiredKey(config.credentialRef);
      task = await _updateTask(
        task,
        status: TranscriptionTaskStatus.running,
        clearErrorMessage: true,
      );
      var taskChunks = await _taskStore.listChunks(task.id);
      final audioChunks =
          config.type == TranscriptionProviderType.dashScopeFunAsr ||
              source.sizeBytes < _singleUploadLimitBytes
          ? [source]
          : await _audioChunker.split(
              source,
              chunkDurationSeconds: config.chunkDurationSeconds,
            );
      if (taskChunks.isEmpty) {
        taskChunks = List.generate(
          audioChunks.length,
          (index) => TranscriptionTaskChunk(
            taskId: task.id,
            index: index,
            status: TranscriptionTaskChunkStatus.pending,
            attempts: 0,
          ),
        );
        await _taskStore.createChunks(taskChunks);
      }
      if (taskChunks.length != audioChunks.length) {
        throw const ProviderRequestException('sourceAudioChanged');
      }
      task = await _updateTask(task, chunksTotal: taskChunks.length);
      onProgress?.call(
        total: taskChunks.length,
        completed: task.chunksCompleted,
      );

      final runnable = taskChunks
          .where(
            (chunk) => chunk.status != TranscriptionTaskChunkStatus.succeeded,
          )
          .toList();
      var next = 0;
      final segments = <TranscriptionSegment>[];
      Future<void> worker() async {
        while (!run.stopRequested && next < runnable.length) {
          final chunk = runnable[next++];
          await _transcribeChunk(
            run: run,
            task: task,
            chunk: chunk,
            file: audioChunks[chunk.index],
            config: config,
            apiKey: key,
            onProgress: onProgress,
            onPartialText: onPartialText,
            onResult: (result) {
              final offset = chunk.index * config.chunkDurationSeconds;
              segments.addAll(
                result.segments.map(
                  (segment) => TranscriptionSegment(
                    startSeconds: segment.startSeconds + offset,
                    endSeconds: segment.endSeconds + offset,
                    text: segment.text,
                    speakerId: segment.speakerId,
                    words: segment.words
                        .map(
                          (word) => TranscriptionWord(
                            startSeconds: word.startSeconds + offset,
                            endSeconds: word.endSeconds + offset,
                            text: word.text,
                            punctuation: word.punctuation,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              );
            },
          );
        }
      }

      await Future.wait(
        List.generate(
          min<int>(
            config.type == TranscriptionProviderType.dashScopeFunAsr
                ? 1
                : config.maxConcurrentUploads,
            runnable.length,
          ),
          (_) => worker(),
        ),
      );
      if (run.stopRequested) return (await _taskById(task.id))!;
      final finalChunks = await _taskStore.listChunks(task.id);
      final failed = finalChunks.any(
        (chunk) => chunk.status == TranscriptionTaskChunkStatus.failed,
      );
      final failure = failed
          ? finalChunks
                    .firstWhere(
                      (chunk) =>
                          chunk.status == TranscriptionTaskChunkStatus.failed,
                    )
                    .errorMessage ??
                'requestFailed'
          : null;
      return _updateTask(
        (await _taskById(task.id))!,
        status: failed
            ? TranscriptionTaskStatus.failed
            : TranscriptionTaskStatus.succeeded,
        transcript: finalChunks
            .where(
              (chunk) => chunk.status == TranscriptionTaskChunkStatus.succeeded,
            )
            .map((chunk) => chunk.text ?? '')
            .join('\n'),
        segments: (segments
          ..sort(
            (first, second) =>
                first.startSeconds.compareTo(second.startSeconds),
          )),
        errorMessage: failure,
        clearErrorMessage: !failed,
      );
    } catch (error) {
      return _updateTask(
        (await _taskById(task.id)) ?? task,
        status: TranscriptionTaskStatus.failed,
        errorMessage: _taskErrorCode(error),
      );
    } finally {
      _taskRuns.remove(task.id);
    }
  }

  Future<void> _transcribeChunk({
    required _TaskRun run,
    required TranscriptionTask task,
    required TranscriptionTaskChunk chunk,
    required SelectedAudioFile file,
    required TranscriptionProviderConfig config,
    required String apiKey,
    void Function({required int total, required int completed})? onProgress,
    void Function(TranscriptionResult result)? onResult,
    void Function(String text)? onPartialText,
  }) async {
    var current = chunk;
    for (var retry = 0; retry <= maxAutomaticChunkRetries; retry += 1) {
      if (run.stopRequested) {
        await _taskStore.updateChunk(
          current.copyWith(status: TranscriptionTaskChunkStatus.stopped),
        );
        return;
      }
      current = current.copyWith(
        status: TranscriptionTaskChunkStatus.running,
        attempts: current.attempts + 1,
        clearErrorMessage: true,
      );
      await _taskStore.updateChunk(current);
      try {
        final result = await _apiClient.transcribe(
          config: config,
          apiKey: apiKey,
          file: file,
          options: TranscriptionRequestOptions(
            language: task.language,
            diarizationEnabled: task.diarizationEnabled,
            speakerCount: task.speakerCount,
          ),
          onPartialText: (text) {
            onPartialText?.call(text);
            unawaited(_taskStore.updateChunk(current.copyWith(text: text)));
          },
          onRemoteTaskCreated: (remoteTaskId) async {
            final latest = await _taskById(task.id);
            if (latest != null) {
              await _updateTask(latest, remoteTaskId: remoteTaskId);
            }
          },
        );
        if (run.stopRequested) {
          await _taskStore.updateChunk(
            current.copyWith(status: TranscriptionTaskChunkStatus.stopped),
          );
          return;
        }
        await _taskStore.updateChunk(
          current.copyWith(
            status: TranscriptionTaskChunkStatus.succeeded,
            text: _renderSegmentedText(
              result,
              offsetSeconds: chunk.index * config.chunkDurationSeconds,
            ),
            clearErrorMessage: true,
          ),
        );
        onResult?.call(result);
        await _refreshTaskProgress(task.id, run, onProgress);
        return;
      } catch (error) {
        current = current.copyWith(errorMessage: _taskErrorCode(error));
        final canRetry =
            retry < maxAutomaticChunkRetries && _isRetryable(error);
        if (!canRetry) {
          await _taskStore.updateChunk(
            current.copyWith(status: TranscriptionTaskChunkStatus.failed),
          );
          await _refreshTaskProgress(task.id, run, onProgress);
          return;
        }
        await _taskStore.updateChunk(
          current.copyWith(status: TranscriptionTaskChunkStatus.pending),
        );
        await Future<void>.delayed(Duration(seconds: 1 << retry));
      }
    }
  }

  Future<void> _refreshTaskProgress(
    String taskId,
    _TaskRun run,
    void Function({required int total, required int completed})? onProgress,
  ) {
    run.progressQueue = run.progressQueue.then((_) async {
      if (run.stopRequested) return;
      final chunks = await _taskStore.listChunks(taskId);
      final task = await _taskById(taskId);
      if (task == null) return;
      final completed = chunks
          .where(
            (chunk) => chunk.status == TranscriptionTaskChunkStatus.succeeded,
          )
          .length;
      await _updateTask(
        task,
        chunksTotal: chunks.length,
        chunksCompleted: completed,
      );
      onProgress?.call(total: chunks.length, completed: completed);
    });
    return run.progressQueue;
  }

  bool _isRetryable(Object error) {
    if (error is! ProviderRequestException) return true;
    return switch (error.message) {
      'rateLimited' || 'providerUnavailable' || 'requestFailed' => true,
      _ => false,
    };
  }

  String _renderSegmentedText(
    TranscriptionResult result, {
    required int offsetSeconds,
  }) {
    if (result.model.startsWith('fun-asr-flash')) return result.text;
    if (result.segments.isEmpty) return result.text;
    return result.segments
        .map(
          (segment) =>
              '[${_timeLabel(segment.startSeconds + offsetSeconds)} '
              '– ${_timeLabel(segment.endSeconds + offsetSeconds)}] '
              '${segment.text.trim()}',
        )
        .join('\n');
  }

  String _timeLabel(double seconds) {
    final rounded = seconds.floor();
    final minutes = rounded ~/ 60;
    final remaining = rounded % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  Future<TranscriptionTask?> _taskById(String taskId) async {
    for (final task in await _taskStore.list()) {
      if (task.id == taskId) return task;
    }
    return null;
  }

  Future<void> _resumeDashScopeTask(TranscriptionTask task) async {
    final provider = transcriptionProviderById(task.providerId);
    final remoteTaskId = task.remoteTaskId;
    if (provider == null || remoteTaskId == null) {
      await _updateTask(
        task,
        status: TranscriptionTaskStatus.failed,
        errorMessage: 'providerMissing',
      );
      return;
    }
    final run = _TaskRun();
    _taskRuns[task.id] = run;
    try {
      final key = await _requiredKey(provider.credentialRef);
      final config = provider.copyWith(
        batchModel: task.model,
        language: task.language,
      );
      final result = await _apiClient.resumeDashScopeFunAsr(
        config: config,
        apiKey: key,
        fileName: task.fileName,
        taskId: remoteTaskId,
      );
      if (run.stopRequested) return;
      final chunks = await _taskStore.listChunks(task.id);
      if (chunks.isNotEmpty) {
        await _taskStore.updateChunk(
          chunks.first.copyWith(
            status: TranscriptionTaskChunkStatus.succeeded,
            text: _renderSegmentedText(result, offsetSeconds: 0),
            clearErrorMessage: true,
          ),
        );
      }
      final latest = await _taskById(task.id);
      if (latest == null || run.stopRequested) return;
      await _updateTask(
        latest,
        status: TranscriptionTaskStatus.succeeded,
        chunksTotal: chunks.isEmpty ? 1 : chunks.length,
        chunksCompleted: chunks.isEmpty ? 1 : chunks.length,
        transcript: chunks.isEmpty
            ? _renderSegmentedText(result, offsetSeconds: 0)
            : (await _taskStore.listChunks(
                task.id,
              )).map((chunk) => chunk.text ?? '').join('\n'),
        segments: result.segments,
        clearErrorMessage: true,
      );
    } catch (error) {
      final latest = await _taskById(task.id);
      if (latest != null && !run.stopRequested) {
        await _updateTask(
          latest,
          status: TranscriptionTaskStatus.failed,
          errorMessage: _taskErrorCode(error),
        );
      }
    } finally {
      _taskRuns.remove(task.id);
    }
  }

  Future<TranscriptionTask> _updateTask(
    TranscriptionTask task, {
    TranscriptionTaskStatus? status,
    int? chunksTotal,
    int? chunksCompleted,
    String? transcript,
    List<TranscriptionSegment>? segments,
    String? errorMessage,
    String? sourcePath,
    String? remoteTaskId,
    bool clearErrorMessage = false,
  }) async {
    final updated = task.copyWith(
      status: status,
      updatedAt: DateTime.now(),
      chunksTotal: chunksTotal,
      chunksCompleted: chunksCompleted,
      transcript: transcript,
      segments: segments,
      errorMessage: errorMessage,
      sourcePath: sourcePath,
      remoteTaskId: remoteTaskId,
      clearErrorMessage: clearErrorMessage,
    );
    await _taskStore.update(updated);
    notifyListeners();
    return updated;
  }

  String _taskErrorCode(Object error) {
    if (error is TimeoutException) return 'transcriptionTimedOut';
    if (error is ProviderRequestException) return error.message;
    return 'requestFailed';
  }

  Future<String> _requiredKey(String reference) async {
    final key = await _credentialStore.read(reference);
    if (key == null || key.isEmpty) {
      throw const ProviderRequestException('credentialMissing');
    }
    return key;
  }

  void _ensureEnabled(bool enabled) {
    if (!enabled) throw const ProviderRequestException('providerDisabled');
  }

  @override
  void dispose() {
    _apiClient.close();
    super.dispose();
  }
}

class _TaskRun {
  bool stopRequested = false;
  Future<void> progressQueue = Future<void>.value();
}
