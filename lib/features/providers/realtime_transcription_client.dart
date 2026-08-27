import 'dart:typed_data';

class RealtimeTranscriptEvent {
  const RealtimeTranscriptEvent({
    required this.sentenceId,
    required this.text,
    required this.isFinal,
    required this.beginMilliseconds,
    this.endMilliseconds,
  });

  final int sentenceId;
  final String text;
  final bool isFinal;
  final int beginMilliseconds;
  final int? endMilliseconds;
}

/// Shared contract for Fun-ASR realtime and Gemini Live transcription.
abstract class RealtimeTranscriptionClient {
  Stream<RealtimeTranscriptEvent> get events;

  Future<void> connect({String? context});

  void sendAudio(Uint8List bytes);

  Future<void> finish();

  Future<void> dispose();
}
