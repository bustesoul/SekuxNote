import '../../app/shell/app_session_controller.dart';
import '../../l10n/app_localizations.dart';
import 'provider_models.dart';

String transcriptionProgressDescription(
  AppLocalizations l10n,
  AppSessionController session,
) {
  var stage = switch (session.transcriptionStage) {
    TranscriptionProgressStage.uploading => l10n.transcriptionStageUploading,
    TranscriptionProgressStage.providerProcessing =>
      l10n.transcriptionStageProcessing(session.transcriptionProviderName),
    TranscriptionProgressStage.generatingText =>
      l10n.transcriptionStageGenerating,
    TranscriptionProgressStage.receivingText =>
      l10n.transcriptionStageReceiving(
        session.transcriptionPartialText.runes.length,
      ),
    TranscriptionProgressStage.completed => l10n.transcriptionStageCompleted,
  };
  if (session.transcriptionChunksTotal > 1) {
    stage = l10n.transcriptionStageWithChunks(
      stage,
      session.transcriptionChunksCompleted,
      session.transcriptionChunksTotal,
    );
  }
  return l10n.transcriptionProgressBanner(
    session.transcriptionFileName,
    stage,
    session.transcriptionElapsedSeconds,
  );
}
