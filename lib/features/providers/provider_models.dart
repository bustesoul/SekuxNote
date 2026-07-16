import 'dart:typed_data';

enum TranscriptionCapability { batch, diarization, usage }

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
    required this.name,
    required this.enabled,
    required this.credentialRef,
    required this.baseUrl,
    required this.batchModel,
    required this.capabilities,
  });

  factory TranscriptionProviderConfig.defaults() =>
      const TranscriptionProviderConfig(
        id: 'transcription-openai',
        name: 'OpenAI Audio',
        enabled: true,
        credentialRef: 'sekuxnote.transcription.openai',
        baseUrl: 'https://api.openai.com/v1',
        batchModel: 'gpt-4o-transcribe',
        capabilities: {
          TranscriptionCapability.batch,
          TranscriptionCapability.diarization,
          TranscriptionCapability.usage,
        },
      );

  factory TranscriptionProviderConfig.fromJson(Map<String, Object?> json) {
    final defaults = TranscriptionProviderConfig.defaults();
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
    return TranscriptionProviderConfig(
      id: json['id'] as String? ?? defaults.id,
      name: json['name'] as String? ?? defaults.name,
      enabled: json['enabled'] as bool? ?? defaults.enabled,
      credentialRef: json['credentialRef'] as String? ?? defaults.credentialRef,
      baseUrl: json['baseUrl'] as String? ?? defaults.baseUrl,
      batchModel: json['batchModel'] as String? ?? defaults.batchModel,
      capabilities: values.isEmpty ? defaults.capabilities : values,
    );
  }

  final String id;
  final String name;
  final bool enabled;
  final String credentialRef;
  final String baseUrl;
  final String batchModel;
  final Set<TranscriptionCapability> capabilities;

  TranscriptionProviderConfig copyWith({
    String? name,
    bool? enabled,
    String? baseUrl,
    String? batchModel,
  }) {
    return TranscriptionProviderConfig(
      id: id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      credentialRef: credentialRef,
      baseUrl: baseUrl ?? this.baseUrl,
      batchModel: batchModel ?? this.batchModel,
      capabilities: capabilities,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'enabled': enabled,
    'credentialRef': credentialRef,
    'baseUrl': baseUrl,
    'batchModel': batchModel,
    'capabilities': capabilities.map((capability) => capability.name).toList(),
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

class TranscriptionResult {
  const TranscriptionResult({
    required this.fileName,
    required this.providerName,
    required this.model,
    required this.text,
    required this.usage,
  });

  final String fileName;
  final String providerName;
  final String model;
  final String text;
  final Map<String, Object?> usage;
}
