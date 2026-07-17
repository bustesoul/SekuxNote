enum RecordingStatus { recording, paused, ready, recovered, failed }

enum AudioIntegrityStatus { recording, valid, recovered, corrupt, unknown }

enum RealtimeRecordingStatus {
  disabled,
  connecting,
  streaming,
  interrupted,
  completed,
}

class RecordingEntry {
  const RecordingEntry({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.audioPath,
    required this.durationMilliseconds,
    required this.realtimeEnabled,
    required this.realtimeStatus,
    this.realtimeTranscript = '',
    this.errorMessage,
    this.sampleRate = 16000,
    this.channels = 1,
    this.bitsPerSample = 16,
    this.pcmBytes = 0,
    this.audioFileSize,
    this.audioIntegrityStatus = AudioIntegrityStatus.unknown,
  });

  final String id;
  final String title;
  final RecordingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String audioPath;
  final int durationMilliseconds;
  final bool realtimeEnabled;
  final RealtimeRecordingStatus realtimeStatus;
  final String realtimeTranscript;
  final String? errorMessage;
  final int sampleRate;
  final int channels;
  final int bitsPerSample;
  final int pcmBytes;
  final int? audioFileSize;
  final AudioIntegrityStatus audioIntegrityStatus;

  RecordingEntry copyWith({
    RecordingStatus? status,
    DateTime? updatedAt,
    int? durationMilliseconds,
    RealtimeRecordingStatus? realtimeStatus,
    String? realtimeTranscript,
    String? errorMessage,
    bool clearError = false,
    int? pcmBytes,
    int? audioFileSize,
    AudioIntegrityStatus? audioIntegrityStatus,
  }) => RecordingEntry(
    id: id,
    title: title,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    audioPath: audioPath,
    durationMilliseconds: durationMilliseconds ?? this.durationMilliseconds,
    realtimeEnabled: realtimeEnabled,
    realtimeStatus: realtimeStatus ?? this.realtimeStatus,
    realtimeTranscript: realtimeTranscript ?? this.realtimeTranscript,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    sampleRate: sampleRate,
    channels: channels,
    bitsPerSample: bitsPerSample,
    pcmBytes: pcmBytes ?? this.pcmBytes,
    audioFileSize: audioFileSize ?? this.audioFileSize,
    audioIntegrityStatus: audioIntegrityStatus ?? this.audioIntegrityStatus,
  );

  factory RecordingEntry.fromJson(Map<String, Object?> json) => RecordingEntry(
    id: json['id'] as String,
    title: json['title'] as String? ?? '未命名录音',
    status: RecordingStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => RecordingStatus.recovered,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    audioPath: json['audioPath'] as String,
    durationMilliseconds: json['durationMilliseconds'] as int? ?? 0,
    realtimeEnabled: json['realtimeEnabled'] as bool? ?? false,
    realtimeStatus: RealtimeRecordingStatus.values.firstWhere(
      (value) => value.name == json['realtimeStatus'],
      orElse: () => RealtimeRecordingStatus.interrupted,
    ),
    realtimeTranscript: json['realtimeTranscript'] as String? ?? '',
    errorMessage: json['errorMessage'] as String?,
    sampleRate: json['sampleRate'] as int? ?? 16000,
    channels: json['channels'] as int? ?? 1,
    bitsPerSample: json['bitsPerSample'] as int? ?? 16,
    pcmBytes: json['pcmBytes'] as int? ?? 0,
    audioFileSize: json['audioFileSize'] as int?,
    audioIntegrityStatus: AudioIntegrityStatus.values.firstWhere(
      (value) => value.name == json['audioIntegrityStatus'],
      orElse: () => AudioIntegrityStatus.unknown,
    ),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'audioPath': audioPath,
    'durationMilliseconds': durationMilliseconds,
    'realtimeEnabled': realtimeEnabled,
    'realtimeStatus': realtimeStatus.name,
    'realtimeTranscript': realtimeTranscript,
    'errorMessage': errorMessage,
    'sampleRate': sampleRate,
    'channels': channels,
    'bitsPerSample': bitsPerSample,
    'pcmBytes': pcmBytes,
    'audioFileSize': audioFileSize,
    'audioIntegrityStatus': audioIntegrityStatus.name,
  };
}
