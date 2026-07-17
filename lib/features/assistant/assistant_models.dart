class RecordAiSource {
  const RecordAiSource({
    required this.sourceId,
    required this.title,
    required this.sourceRevisionId,
    required this.revisionLabel,
    required this.text,
    required this.contentHash,
  });

  final String sourceId;
  final String title;
  final String sourceRevisionId;
  final String revisionLabel;
  final String text;
  final String contentHash;

  int get characterCount => text.length;
}

class AssistantContextReference {
  const AssistantContextReference({
    required this.sourceId,
    required this.title,
    required this.sourceRevisionId,
    required this.revisionLabel,
    required this.snapshotText,
    required this.contentHash,
  });

  factory AssistantContextReference.fromSource(RecordAiSource source) =>
      AssistantContextReference(
        sourceId: source.sourceId,
        title: source.title,
        sourceRevisionId: source.sourceRevisionId,
        revisionLabel: source.revisionLabel,
        snapshotText: source.text,
        contentHash: source.contentHash,
      );

  factory AssistantContextReference.fromJson(Map<String, Object?> json) =>
      AssistantContextReference(
        sourceId: json['sourceId'] as String,
        title: json['title'] as String,
        sourceRevisionId: json['sourceRevisionId'] as String,
        revisionLabel: json['revisionLabel'] as String,
        snapshotText: json['snapshotText'] as String,
        contentHash: json['contentHash'] as String,
      );

  final String sourceId;
  final String title;
  final String sourceRevisionId;
  final String revisionLabel;
  final String snapshotText;
  final String contentHash;

  Map<String, Object?> toJson() => {
    'sourceId': sourceId,
    'title': title,
    'sourceRevisionId': sourceRevisionId,
    'revisionLabel': revisionLabel,
    'snapshotText': snapshotText,
    'contentHash': contentHash,
  };
}

class AssistantThread {
  const AssistantThread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssistantThread copyWith({String? title, DateTime? updatedAt}) =>
      AssistantThread(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.providerId,
    this.modelId,
    this.contexts = const [],
    this.isStreaming = false,
    this.errorMessage,
  });

  final String id;
  final String threadId;
  final String role;
  final String content;
  final DateTime createdAt;
  final String? providerId;
  final String? modelId;
  final List<AssistantContextReference> contexts;
  final bool isStreaming;
  final String? errorMessage;

  AssistantMessage copyWith({
    String? content,
    String? providerId,
    String? modelId,
    bool? isStreaming,
    String? errorMessage,
    bool clearError = false,
  }) => AssistantMessage(
    id: id,
    threadId: threadId,
    role: role,
    content: content ?? this.content,
    createdAt: createdAt,
    providerId: providerId ?? this.providerId,
    modelId: modelId ?? this.modelId,
    contexts: contexts,
    isStreaming: isStreaming ?? this.isStreaming,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

enum NoteArtifactStatus { generating, ready, stale, failed }

class NoteArtifact {
  const NoteArtifact({
    required this.id,
    required this.sourceId,
    required this.sourceTitle,
    required this.sourceRevisionId,
    required this.sourceContentHash,
    required this.providerId,
    required this.modelId,
    required this.status,
    required this.markdown,
    required this.createdAt,
    required this.updatedAt,
    this.errorMessage,
  });

  final String id;
  final String sourceId;
  final String sourceTitle;
  final String sourceRevisionId;
  final String sourceContentHash;
  final String providerId;
  final String modelId;
  final NoteArtifactStatus status;
  final String markdown;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? errorMessage;

  bool isStaleFor(RecordAiSource source) =>
      source.sourceRevisionId != sourceRevisionId ||
      source.contentHash != sourceContentHash;

  NoteArtifact copyWith({
    NoteArtifactStatus? status,
    String? markdown,
    DateTime? updatedAt,
    String? errorMessage,
    bool clearError = false,
  }) => NoteArtifact(
    id: id,
    sourceId: sourceId,
    sourceTitle: sourceTitle,
    sourceRevisionId: sourceRevisionId,
    sourceContentHash: sourceContentHash,
    providerId: providerId,
    modelId: modelId,
    status: status ?? this.status,
    markdown: markdown ?? this.markdown,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

String stableContentHash(String text) {
  var hash = 0xcbf29ce484222325;
  for (final value in text.codeUnits) {
    hash ^= value;
    hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
  }
  return hash.toRadixString(16);
}
