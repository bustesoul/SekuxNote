import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'provider_models.dart';

abstract interface class ProviderSettingsStore {
  Future<TextProviderConfig> readText();
  Future<TranscriptionProviderConfig> readTranscription();
  Future<void> writeText(TextProviderConfig config);
  Future<void> writeTranscription(TranscriptionProviderConfig config);
}

class SharedPreferencesProviderSettingsStore implements ProviderSettingsStore {
  SharedPreferencesProviderSettingsStore(this._preferences);

  static const _textKey = 'provider.text.openai';
  static const _transcriptionKey = 'provider.transcription.openai';

  final SharedPreferences _preferences;

  @override
  Future<TextProviderConfig> readText() async {
    final value = _preferences.getString(_textKey);
    if (value == null) return TextProviderConfig.defaults();
    return TextProviderConfig.fromJson(
      Map<String, Object?>.from(jsonDecode(value) as Map),
    );
  }

  @override
  Future<TranscriptionProviderConfig> readTranscription() async {
    final value = _preferences.getString(_transcriptionKey);
    if (value == null) return TranscriptionProviderConfig.defaults();
    return TranscriptionProviderConfig.fromJson(
      Map<String, Object?>.from(jsonDecode(value) as Map),
    );
  }

  @override
  Future<void> writeText(TextProviderConfig config) async {
    await _preferences.setString(_textKey, jsonEncode(config.toJson()));
  }

  @override
  Future<void> writeTranscription(TranscriptionProviderConfig config) async {
    await _preferences.setString(
      _transcriptionKey,
      jsonEncode(config.toJson()),
    );
  }
}

class MemoryProviderSettingsStore implements ProviderSettingsStore {
  TextProviderConfig _text = TextProviderConfig.defaults();
  TranscriptionProviderConfig _transcription =
      TranscriptionProviderConfig.defaults();

  @override
  Future<TextProviderConfig> readText() async => _text;

  @override
  Future<TranscriptionProviderConfig> readTranscription() async =>
      _transcription;

  @override
  Future<void> writeText(TextProviderConfig config) async {
    _text = config;
  }

  @override
  Future<void> writeTranscription(TranscriptionProviderConfig config) async {
    _transcription = config;
  }
}

abstract interface class CredentialStore {
  Future<String?> read(String reference);
  Future<void> write(String reference, String secret);
  Future<void> delete(String reference);
}

class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String reference) => _storage.read(key: reference);

  @override
  Future<void> write(String reference, String secret) {
    return _storage.write(key: reference, value: secret);
  }

  @override
  Future<void> delete(String reference) => _storage.delete(key: reference);
}

class MemoryCredentialStore implements CredentialStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String reference) async => _values[reference];

  @override
  Future<void> write(String reference, String secret) async {
    _values[reference] = secret;
  }

  @override
  Future<void> delete(String reference) async {
    _values.remove(reference);
  }
}
