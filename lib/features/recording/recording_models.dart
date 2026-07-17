enum RecordingStatus { recording, paused, ready, recovered, failed }

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

  RecordingEntry copyWith({
    RecordingStatus? status,
    DateTime? updatedAt,
    int? durationMilliseconds,
    RealtimeRecordingStatus? realtimeStatus,
    String? realtimeTranscript,
    String? errorMessage,
    bool clearError = false,
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
  };
}
