import '../../l10n/app_localizations.dart';
import 'openai_api_client.dart';

String providerErrorMessage(AppLocalizations l10n, Object error) {
  final code = error is ProviderRequestException
      ? error.message
      : 'requestFailed';
  return switch (code) {
    'credentialMissing' => l10n.providerErrorCredentialMissing,
    'providerDisabled' => l10n.providerErrorProviderDisabled,
    'invalidBaseUrl' => l10n.providerErrorInvalidBaseUrl,
    'unauthorized' => l10n.providerErrorUnauthorized,
    'rateLimited' => l10n.providerErrorRateLimited,
    'providerUnavailable' => l10n.providerErrorUnavailable,
    'audioFileTooLarge' => l10n.providerErrorAudioFileTooLarge,
    'invalidProviderResponse' => l10n.providerErrorInvalidResponse,
    _ => l10n.providerErrorRequestFailed,
  };
}
