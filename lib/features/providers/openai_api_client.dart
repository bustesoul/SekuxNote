import 'dart:convert';

import 'package:http/http.dart' as http;

import 'provider_models.dart';

class ProviderRequestException implements Exception {
  const ProviderRequestException(this.message);

  final String message;
}

class OpenAiApiClient {
  OpenAiApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ApiOperationResult> testText({
    required TextProviderConfig config,
    required String apiKey,
  }) async {
    final response =
        await _sendJson(_endpoint(config.baseUrl, 'responses'), apiKey, {
          'model': config.model,
          'input': 'Reply exactly: SekuxNote text API test passed.',
          'store': false,
          'max_output_tokens': 32,
        });
    final body = _decodeJson(response.body);
    return ApiOperationResult(
      model: body['model'] as String? ?? config.model,
      output: _responseText(body),
      usage: _usage(body),
    );
  }

  Future<TranscriptionResult> transcribe({
    required TranscriptionProviderConfig config,
    required String apiKey,
    required SelectedAudioFile file,
  }) async {
    if (file.sizeBytes >= 25 * 1024 * 1024) {
      throw const ProviderRequestException('audioFileTooLarge');
    }

    final request =
        http.MultipartRequest(
            'POST',
            _endpoint(config.baseUrl, 'audio/transcriptions'),
          )
          ..headers['Authorization'] = 'Bearer $apiKey'
          ..fields['model'] = config.batchModel
          ..fields['response_format'] =
              config.batchModel == 'gpt-4o-transcribe-diarize'
              ? 'diarized_json'
              : 'json'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              file.bytes,
              filename: file.name,
            ),
          );

    if (config.batchModel == 'gpt-4o-transcribe-diarize') {
      request.fields['chunking_strategy'] = 'auto';
    }

    final streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);
    _ensureSuccess(response);
    final body = _decodeJson(response.body);
    return TranscriptionResult(
      fileName: file.name,
      providerName: config.name,
      model: config.batchModel,
      text: body['text'] as String? ?? '',
      usage: _usage(body),
    );
  }

  Future<http.Response> _sendJson(
    Uri uri,
    String apiKey,
    Map<String, Object?> body,
  ) async {
    final response = await _client
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
    return response;
  }

  Uri _endpoint(String baseUrl, String path) {
    final normalized = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse('$normalized/$path');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const ProviderRequestException('invalidBaseUrl');
    }
    return uri;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final message = switch (response.statusCode) {
      401 => 'unauthorized',
      413 => 'audioFileTooLarge',
      429 => 'rateLimited',
      >= 500 => 'providerUnavailable',
      _ => 'requestFailed',
    };
    throw ProviderRequestException(message);
  }

  Map<String, Object?> _decodeJson(String value) {
    try {
      return Map<String, Object?>.from(jsonDecode(value) as Map);
    } on FormatException {
      throw const ProviderRequestException('invalidProviderResponse');
    }
  }

  Map<String, Object?> _usage(Map<String, Object?> body) {
    final usage = body['usage'];
    return usage is Map ? Map<String, Object?>.from(usage) : const {};
  }

  String _responseText(Map<String, Object?> body) {
    final output = body['output'];
    if (output is! List) return '';
    final parts = <String>[];
    for (final item in output.whereType<Map>()) {
      final content = item['content'];
      if (content is! List) continue;
      for (final value in content.whereType<Map>()) {
        if (value['type'] == 'output_text' && value['text'] is String) {
          parts.add(value['text'] as String);
        }
      }
    }
    return parts.join();
  }

  void close() => _client.close();
}
