import 'dart:typed_data';

enum TranscriptionCapability {
  batch,
  fileStreaming,
  realtime,
  diarization,
  segmentTimestamps,
  wordTimestamps,
  context,
  vocabulary,
  usage,
}

enum TranscriptionProviderType { openAiCompatible, dashScopeFunAsr }

enum TranscriptionFileMode { precision, fast }

enum TranscriptionTaskStatus { queued, running, succeeded, failed, stopped }

enum TranscriptionTaskChunkStatus {
  pending,
  running,
  succeeded,
  failed,
  stopped,
}

class TranscriptionTaskChunk {
  const TranscriptionTaskChunk({
    required this.taskId,
    required this.index,
    required this.status,
    required this.attempts,
    this.text,
    this.errorMessage,
  });

  final String taskId;
  final int index;
  final TranscriptionTaskChunkStatus status;
  final int attempts;
  final String? text;
  final String? errorMessage;

  TranscriptionTaskChunk copyWith({
    TranscriptionTaskChunkStatus? status,
    int? attempts,
    String? text,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return TranscriptionTaskChunk(
      taskId: taskId,
      index: index,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      text: text ?? this.text,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class TranscriptionTask {
  const TranscriptionTask({
    required this.id,
    required this.fileName,
    this.providerId = 'transcription-openai',
    this.providerType = TranscriptionProviderType.openAiCompatible,
    required this.providerName,
    required this.model,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.chunksTotal,
    required this.chunksCompleted,
    this.language = 'zh',
    this.diarizationEnabled = false,
    this.speakerCount,
    this.sourcePath,
    this.remoteTaskId,
    this.transcript,
    this.segments = const [],
    this.errorMessage,
  });

  final String id;
  final String fileName;
  final String providerId;
  final TranscriptionProviderType providerType;
  final String providerName;
  final String model;
  final TranscriptionTaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int chunksTotal;
  final int chunksCompleted;
  final String language;
  final bool diarizationEnabled;
  final int? speakerCount;
  final String? sourcePath;
  final String? remoteTaskId;
  final String? transcript;
  final List<TranscriptionSegment> segments;
  final String? errorMessage;

  bool get isTerminal =>
      status == TranscriptionTaskStatus.succeeded ||
      status == TranscriptionTaskStatus.failed;

  TranscriptionTask copyWith({
    TranscriptionTaskStatus? status,
    DateTime? updatedAt,
    int? chunksTotal,
    int? chunksCompleted,
    String? transcript,
    String? errorMessage,
    String? sourcePath,
    String? remoteTaskId,
    String? language,
    bool? diarizationEnabled,
    int? speakerCount,
    List<TranscriptionSegment>? segments,
    bool clearTranscript = false,
    bool clearErrorMessage = false,
  }) {
    return TranscriptionTask(
      id: id,
      fileName: fileName,
      providerId: providerId,
      providerType: providerType,
      providerName: providerName,
      model: model,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chunksTotal: chunksTotal ?? this.chunksTotal,
      chunksCompleted: chunksCompleted ?? this.chunksCompleted,
      language: language ?? this.language,
      diarizationEnabled: diarizationEnabled ?? this.diarizationEnabled,
      speakerCount: speakerCount ?? this.speakerCount,
      sourcePath: sourcePath ?? this.sourcePath,
      remoteTaskId: remoteTaskId ?? this.remoteTaskId,
      transcript: clearTranscript ? null : transcript ?? this.transcript,
      segments: segments ?? this.segments,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class TextProviderConfig {
  const TextProviderConfig({
    required this.id,
    required this.name,
    required this.enabled,
    required this.credentialRef,
    required this.baseUrl,
    required this.model,
  });

  factory TextProviderConfig.defaults() => const TextProviderConfig(
    id: 'text-openai',
    name: 'OpenAI',
    enabled: true,
    credentialRef: 'sekuxnote.text.openai',
    baseUrl: 'https://api.openai.com/v1',
    model: 'gpt-5.6-luna',
  );

  factory TextProviderConfig.fromJson(Map<String, Object?> json) {
    final defaults = TextProviderConfig.defaults();
    return TextProviderConfig(
      id: json['id'] as String? ?? defaults.id,
      name: json['name'] as String? ?? defaults.name,
      enabled: json['enabled'] as bool? ?? defaults.enabled,
      credentialRef: json['credentialRef'] as String? ?? defaults.credentialRef,
      baseUrl: json['baseUrl'] as String? ?? defaults.baseUrl,
      model: json['model'] as String? ?? defaults.model,
    );
  }

  final String id;
  final String name;
  final bool enabled;
  final String credentialRef;
  final String baseUrl;
  final String model;

  TextProviderConfig copyWith({
    String? name,
    bool? enabled,
    String? baseUrl,
    String? model,
  }) {
    return TextProviderConfig(
      id: id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      credentialRef: credentialRef,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'enabled': enabled,
    'credentialRef': credentialRef,
    'baseUrl': baseUrl,
    'model': model,
  };
}

class TranscriptionProviderConfig {
  const TranscriptionProviderConfig({
    required this.id,
    required this.type,
    required this.name,
    required this.enabled,
    required this.credentialRef,
    required this.baseUrl,
    required this.batchModel,
    this.fastFileModel,
    this.realtimeModel,
    required this.language,
    required this.chunkDurationSeconds,
    required this.maxConcurrentUploads,
    required this.capabilities,
    this.dashScopeApiUrl,
  });

  factory TranscriptionProviderConfig.defaults() =>
      const TranscriptionProviderConfig(
        id: 'transcription-openai',
        type: TranscriptionProviderType.openAiCompatible,
        name: 'OpenAI Audio',
        enabled: true,
        credentialRef: 'sekuxnote.transcription.openai',
        baseUrl: 'https://api.openai.com/v1',
        batchModel: 'gpt-4o-transcribe',
        realtimeModel: 'gpt-realtime-whisper',
        language: 'zh',
        chunkDurationSeconds: 60,
        maxConcurrentUploads: 2,
        capabilities: {
          TranscriptionCapability.batch,
          TranscriptionCapability.realtime,
          TranscriptionCapability.diarization,
          TranscriptionCapability.segmentTimestamps,
          TranscriptionCapability.usage,
        },
      );

  factory TranscriptionProviderConfig.dashScopeDefaults({required String id}) =>
      TranscriptionProviderConfig(
        id: id,
        type: TranscriptionProviderType.dashScopeFunAsr,
        name: '阿里百炼原生 ASR',
        enabled: true,
        credentialRef: 'sekuxnote.transcription.$id',
        baseUrl: '',
        batchModel: 'fun-asr',
        fastFileModel: 'fun-asr-flash-2026-06-15',
        realtimeModel: 'fun-asr-realtime',
        language: 'zh',
        chunkDurationSeconds: 60,
        maxConcurrentUploads: 1,
        capabilities: const {
          TranscriptionCapability.batch,
          TranscriptionCapability.fileStreaming,
          TranscriptionCapability.realtime,
          TranscriptionCapability.diarization,
          TranscriptionCapability.segmentTimestamps,
          TranscriptionCapability.wordTimestamps,
          TranscriptionCapability.context,
          TranscriptionCapability.vocabulary,
          TranscriptionCapability.usage,
        },
        dashScopeApiUrl: '',
      );

  factory TranscriptionProviderConfig.fromJson(Map<String, Object?> json) {
    final id = json['id'] as String? ?? 'transcription-openai';
    final type = TranscriptionProviderType.values.firstWhere(
      (type) => type.name == json['type'],
      orElse: () => TranscriptionProviderType.openAiCompatible,
    );
    final defaults = type == TranscriptionProviderType.dashScopeFunAsr
        ? TranscriptionProviderConfig.dashScopeDefaults(id: id)
        : TranscriptionProviderConfig.defaults();
    final values = (json['capabilities'] as List<Object?>? ?? const [])
        .whereType<String>()
        .map(
          (value) => TranscriptionCapability.values.where(
            (capability) => capability.name == value,
          ),
        )
        .where((matches) => matches.isNotEmpty)
        .map((matches) => matches.first)
        .toSet();
    if (type == TranscriptionProviderType.dashScopeFunAsr) {
      values.addAll(defaults.capabilities);
    }
    return TranscriptionProviderConfig(
      id: id,
      type: type,
      name: json['name'] as String? ?? defaults.name,
      enabled: json['enabled'] as bool? ?? defaults.enabled,
      credentialRef: json['credentialRef'] as String? ?? defaults.credentialRef,
      baseUrl: json['baseUrl'] as String? ?? defaults.baseUrl,
      batchModel: json['batchModel'] as String? ?? defaults.batchModel,
      fastFileModel: json['fastFileModel'] as String? ?? defaults.fastFileModel,
      realtimeModel: json['realtimeModel'] as String? ?? defaults.realtimeModel,
      language: json['language'] as String? ?? defaults.language,
      chunkDurationSeconds:
          json['chunkDurationSeconds'] as int? ?? defaults.chunkDurationSeconds,
      maxConcurrentUploads:
          json['maxConcurrentUploads'] as int? ?? defaults.maxConcurrentUploads,
      capabilities: values.isEmpty ? defaults.capabilities : values,
      dashScopeApiUrl:
          json['dashScopeApiUrl'] as String? ??
          _legacyDashScopeApiUrl(json['workspaceId'] as String?),
    );
  }

  final String id;
  final TranscriptionProviderType type;
  final String name;
  final bool enabled;
  final String credentialRef;
  final String baseUrl;
  final String batchModel;
  final String? fastFileModel;
  final String? realtimeModel;
  final String language;
  final int chunkDurationSeconds;
  final int maxConcurrentUploads;
  final Set<TranscriptionCapability> capabilities;
  final String? dashScopeApiUrl;

  TranscriptionProviderConfig copyWith({
    String? name,
    bool? enabled,
    String? baseUrl,
    String? batchModel,
    String? fastFileModel,
    String? realtimeModel,
    String? language,
    int? chunkDurationSeconds,
    int? maxConcurrentUploads,
    String? dashScopeApiUrl,
  }) {
    return TranscriptionProviderConfig(
      id: id,
      type: type,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      credentialRef: credentialRef,
      baseUrl: baseUrl ?? this.baseUrl,
      batchModel: batchModel ?? this.batchModel,
      fastFileModel: fastFileModel ?? this.fastFileModel,
      realtimeModel: realtimeModel ?? this.realtimeModel,
      language: language ?? this.language,
      chunkDurationSeconds: chunkDurationSeconds ?? this.chunkDurationSeconds,
      maxConcurrentUploads: maxConcurrentUploads ?? this.maxConcurrentUploads,
      capabilities: capabilities,
      dashScopeApiUrl: dashScopeApiUrl ?? this.dashScopeApiUrl,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'enabled': enabled,
    'credentialRef': credentialRef,
    'baseUrl': baseUrl,
    'batchModel': batchModel,
    'fastFileModel': fastFileModel,
    'realtimeModel': realtimeModel,
    'language': language,
    'chunkDurationSeconds': chunkDurationSeconds,
    'maxConcurrentUploads': maxConcurrentUploads,
    'capabilities': capabilities.map((capability) => capability.name).toList(),
    'dashScopeApiUrl': dashScopeApiUrl,
  };

  static String? _legacyDashScopeApiUrl(String? workspaceId) {
    final value = workspaceId?.trim() ?? '';
    return value.isEmpty
        ? null
        : 'https://$value.cn-beijing.maas.aliyuncs.com/api/v1';
  }
}

class TranscriptionProviderSettings {
  const TranscriptionProviderSettings({
    required this.providers,
    required this.defaultProviderId,
  });

  factory TranscriptionProviderSettings.defaults() {
    final provider = TranscriptionProviderConfig.defaults();
    return TranscriptionProviderSettings(
      providers: [provider],
      defaultProviderId: provider.id,
    );
  }

  factory TranscriptionProviderSettings.fromJson(Map<String, Object?> json) {
    final providers = (json['providers'] as List<Object?>? ?? const [])
        .whereType<Map>()
        .map(
          (value) => TranscriptionProviderConfig.fromJson(
            Map<String, Object?>.from(value),
          ),
        )
        .toList(growable: false);
    if (providers.isEmpty) return TranscriptionProviderSettings.defaults();
    final requestedDefault = json['defaultProviderId'] as String?;
    final defaultProviderId =
        providers.any((item) => item.id == requestedDefault)
        ? requestedDefault!
        : providers.first.id;
    return TranscriptionProviderSettings(
      providers: providers,
      defaultProviderId: defaultProviderId,
    );
  }

  final List<TranscriptionProviderConfig> providers;
  final String defaultProviderId;

  TranscriptionProviderConfig get defaultProvider => providers.firstWhere(
    (provider) => provider.id == defaultProviderId,
    orElse: () => providers.first,
  );

  TranscriptionProviderSettings copyWith({
    List<TranscriptionProviderConfig>? providers,
    String? defaultProviderId,
  }) => TranscriptionProviderSettings(
    providers: providers ?? this.providers,
    defaultProviderId: defaultProviderId ?? this.defaultProviderId,
  );

  Map<String, Object?> toJson() => {
    'providers': providers.map((provider) => provider.toJson()).toList(),
    'defaultProviderId': defaultProviderId,
  };
}

class ApiOperationResult {
  const ApiOperationResult({
    required this.model,
    required this.output,
    required this.usage,
  });

  final String model;
  final String output;
  final Map<String, Object?> usage;
}

class SelectedAudioFile {
  const SelectedAudioFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get sizeBytes => bytes.lengthInBytes;
}

class TranscriptionSegment {
  const TranscriptionSegment({
    required this.startSeconds,
    required this.endSeconds,
    required this.text,
    this.speakerId,
    this.words = const [],
  });

  final double startSeconds;
  final double endSeconds;
  final String text;
  final int? speakerId;
  final List<TranscriptionWord> words;

  Map<String, Object?> toJson() => {
    'startSeconds': startSeconds,
    'endSeconds': endSeconds,
    'text': text,
    'speakerId': speakerId,
    'words': words.map((word) => word.toJson()).toList(),
  };

  factory TranscriptionSegment.fromJson(Map<String, Object?> json) =>
      TranscriptionSegment(
        startSeconds: (json['startSeconds'] as num?)?.toDouble() ?? 0,
        endSeconds: (json['endSeconds'] as num?)?.toDouble() ?? 0,
        text: json['text'] as String? ?? '',
        speakerId: json['speakerId'] as int?,
        words: (json['words'] as List<Object?>? ?? const [])
            .whereType<Map>()
            .map(
              (word) =>
                  TranscriptionWord.fromJson(Map<String, Object?>.from(word)),
            )
            .toList(growable: false),
      );
}

class TranscriptionWord {
  const TranscriptionWord({
    required this.startSeconds,
    required this.endSeconds,
    required this.text,
    this.punctuation = '',
  });

  final double startSeconds;
  final double endSeconds;
  final String text;
  final String punctuation;

  Map<String, Object?> toJson() => {
    'startSeconds': startSeconds,
    'endSeconds': endSeconds,
    'text': text,
    'punctuation': punctuation,
  };

  factory TranscriptionWord.fromJson(Map<String, Object?> json) =>
      TranscriptionWord(
        startSeconds: (json['startSeconds'] as num?)?.toDouble() ?? 0,
        endSeconds: (json['endSeconds'] as num?)?.toDouble() ?? 0,
        text: json['text'] as String? ?? '',
        punctuation: json['punctuation'] as String? ?? '',
      );
}

class TranscriptionRequestOptions {
  const TranscriptionRequestOptions({
    required this.language,
    this.diarizationEnabled = false,
    this.speakerCount,
  });

  final String language;
  final bool diarizationEnabled;
  final int? speakerCount;
}

class TranscriptionResult {
  const TranscriptionResult({
    required this.fileName,
    required this.providerName,
    required this.model,
    required this.text,
    required this.usage,
    this.segments = const [],
  });

  final String fileName;
  final String providerName;
  final String model;
  final String text;
  final Map<String, Object?> usage;
  final List<TranscriptionSegment> segments;
}
