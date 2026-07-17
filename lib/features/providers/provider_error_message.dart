import 'dart:async';

import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import 'openai_api_client.dart';

String providerErrorMessage(AppLocalizations l10n, Object error) {
  if (error is TimeoutException) {
    return l10n.providerErrorTranscriptionTimedOut;
  }
  if (error is PlatformException && error.code.startsWith('ENTITLEMENT_')) {
    return l10n.providerErrorFilePickerPermission;
  }
  final code = error is ProviderRequestException
      ? error.message
      : 'requestFailed';
  return switch (code) {
    'credentialMissing' => l10n.providerErrorCredentialMissing,
    'providerMissing' => '此任务关联的转写供应商已不存在。',
    'dashScopeApiUrlMissing' => '请在阿里百炼 Fun-ASR 供应商中填写 DashScope API URL。',
    'providerDisabled' => l10n.providerErrorProviderDisabled,
    'invalidBaseUrl' => l10n.providerErrorInvalidBaseUrl,
    'badRequest' => l10n.providerErrorBadRequest,
    'unauthorized' => l10n.providerErrorUnauthorized,
    'forbidden' => l10n.providerErrorForbidden,
    'rateLimited' => l10n.providerErrorRateLimited,
    'providerUnavailable' => l10n.providerErrorUnavailable,
    'audioFileTooLarge' => l10n.providerErrorAudioFileTooLarge,
    'invalidProviderResponse' => l10n.providerErrorInvalidResponse,
    'transcriptionTimedOut' => l10n.providerErrorTranscriptionTimedOut,
    'taskInterrupted' => l10n.providerErrorTaskInterrupted,
    'sourceAudioMissing' => l10n.providerErrorSourceAudioMissing,
    'audioChunkingUnavailable' => l10n.providerErrorAudioChunkingUnavailable,
    'audioChunkingFailed' => l10n.providerErrorAudioChunkingFailed,
    'invalidChunkDuration' => l10n.providerErrorAudioChunkingFailed,
    _ => l10n.providerErrorRequestFailed,
  };
}
