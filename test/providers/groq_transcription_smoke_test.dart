import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sekuxnote/features/providers/openai_api_client.dart';
import 'package:sekuxnote/features/providers/provider_models.dart';

void main() {
  final enabled = Platform.environment['SEKUXNOTE_GROQ_SMOKE'] == '1';

  test(
    'MANUAL Groq Whisper transcribes the Chinese M4A through OpenAiApiClient',
    () async {
      final apiKey = Platform.environment['GROQ_API_KEY'];
      expect(apiKey, isNotEmpty, reason: 'GROQ_API_KEY is required');
      final bytes = await File(
        'test_assets/zh_aishell4_6min.m4a',
      ).readAsBytes();
      final client = OpenAiApiClient();
      addTearDown(client.close);

      final result = await client.transcribe(
        config: TranscriptionProviderConfig.defaults().copyWith(
          name: 'Groq Whisper',
          baseUrl: 'https://api.groq.com/openai/v1',
          batchModel: 'whisper-large-v3-turbo',
        ),
        apiKey: apiKey!,
        file: SelectedAudioFile(name: 'zh_aishell4_6min.m4a', bytes: bytes),
      );

      expect(result.text, isNotEmpty);
    },
    skip: !enabled,
  );
}
