import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'openai_api_client.dart';
import 'provider_models.dart';
import 'provider_storage.dart';

class ProviderController extends ChangeNotifier {
  ProviderController({
    required ProviderSettingsStore settingsStore,
    required CredentialStore credentialStore,
    required OpenAiApiClient apiClient,
  }) : _settingsStore = settingsStore,
       _credentialStore = credentialStore,
       _apiClient = apiClient;

  factory ProviderController.inMemory() {
    return ProviderController(
      settingsStore: MemoryProviderSettingsStore(),
      credentialStore: MemoryCredentialStore(),
      apiClient: OpenAiApiClient(),
    );
  }

  static Future<ProviderController> createPersistent() async {
    final preferences = await SharedPreferences.getInstance();
    final controller = ProviderController(
      settingsStore: SharedPreferencesProviderSettingsStore(preferences),
      credentialStore: SecureCredentialStore(),
      apiClient: OpenAiApiClient(),
    );
    await controller.load();
    return controller;
  }

  final ProviderSettingsStore _settingsStore;
  final CredentialStore _credentialStore;
  final OpenAiApiClient _apiClient;

  TextProviderConfig _textConfig = TextProviderConfig.defaults();
  TranscriptionProviderConfig _transcriptionConfig =
      TranscriptionProviderConfig.defaults();
  bool _textCredentialConfigured = false;
  bool _transcriptionCredentialConfigured = false;

  TextProviderConfig get textConfig => _textConfig;
  TranscriptionProviderConfig get transcriptionConfig => _transcriptionConfig;
  bool get textCredentialConfigured => _textCredentialConfigured;
  bool get transcriptionCredentialConfigured =>
      _transcriptionCredentialConfigured;

  Future<void> load() async {
    _textConfig = await _settingsStore.readText();
    _transcriptionConfig = await _settingsStore.readTranscription();
    _textCredentialConfigured =
        (await _credentialStore.read(_textConfig.credentialRef))?.isNotEmpty ??
        false;
    _transcriptionCredentialConfigured =
        (await _credentialStore.read(
          _transcriptionConfig.credentialRef,
        ))?.isNotEmpty ??
        false;
    notifyListeners();
  }

  Future<void> saveText({
    required String name,
    required bool enabled,
    required String baseUrl,
    required String model,
    String? apiKey,
  }) async {
    _textConfig = _textConfig.copyWith(
      name: name.trim(),
      enabled: enabled,
      baseUrl: baseUrl.trim(),
      model: model.trim(),
    );
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      await _credentialStore.write(_textConfig.credentialRef, apiKey.trim());
      _textCredentialConfigured = true;
    }
    await _settingsStore.writeText(_textConfig);
    notifyListeners();
  }

  Future<void> saveTranscription({
    required String name,
    required bool enabled,
    required String baseUrl,
    required String batchModel,
    String? apiKey,
  }) async {
    _transcriptionConfig = _transcriptionConfig.copyWith(
      name: name.trim(),
      enabled: enabled,
      baseUrl: baseUrl.trim(),
      batchModel: batchModel.trim(),
    );
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      await _credentialStore.write(
        _transcriptionConfig.credentialRef,
        apiKey.trim(),
      );
      _transcriptionCredentialConfigured = true;
    }
    await _settingsStore.writeTranscription(_transcriptionConfig);
    notifyListeners();
  }

  Future<ApiOperationResult> testText() async {
    _ensureEnabled(_textConfig.enabled);
    final key = await _requiredKey(_textConfig.credentialRef);
    return _apiClient.testText(config: _textConfig, apiKey: key);
  }

  Future<TranscriptionResult> transcribe(SelectedAudioFile file) async {
    _ensureEnabled(_transcriptionConfig.enabled);
    final key = await _requiredKey(_transcriptionConfig.credentialRef);
    return _apiClient.transcribe(
      config: _transcriptionConfig,
      apiKey: key,
      file: file,
    );
  }

  Future<String> _requiredKey(String reference) async {
    final key = await _credentialStore.read(reference);
    if (key == null || key.isEmpty) {
      throw const ProviderRequestException('credentialMissing');
    }
    return key;
  }

  void _ensureEnabled(bool enabled) {
    if (!enabled) throw const ProviderRequestException('providerDisabled');
  }

  @override
  void dispose() {
    _apiClient.close();
    super.dispose();
  }
}
