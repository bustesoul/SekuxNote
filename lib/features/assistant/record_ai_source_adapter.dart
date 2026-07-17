import '../providers/provider_models.dart';
import '../recording/recording_models.dart';
import 'assistant_models.dart';

RecordAiSource? recordAiSourceFromTask(TranscriptionTask task) {
  final text = task.transcript?.trim() ?? '';
  if (task.status != TranscriptionTaskStatus.succeeded || text.isEmpty) {
    return null;
  }
  return RecordAiSource(
    sourceId: 'transcription-task:${task.id}',
    title: task.fileName,
    sourceRevisionId: 'transcription-task:${task.id}:batch-final',
    revisionLabel: '会后转写最终稿',
    text: text,
    contentHash: stableContentHash(text),
  );
}

RecordAiSource? recordAiSourceFromRecording(RecordingEntry recording) {
  final text = recording.realtimeTranscript.trim();
  if (text.isEmpty) return null;
  return RecordAiSource(
    sourceId: 'recording:${recording.id}',
    title: recording.title,
    sourceRevisionId: 'recording:${recording.id}:realtime-provisional',
    revisionLabel: '实时转写临时稿',
    text: text,
    contentHash: stableContentHash(text),
  );
}
