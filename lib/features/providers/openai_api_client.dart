import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'provider_debug_log.dart';
import 'provider_models.dart';

class ProviderRequestException implements Exception {
  const ProviderRequestException(this.message);

  final String message;
}

/// Routes transcription requests to the selected provider protocol.
///
/// The original class name remains to avoid an unrelated public API rename.
class OpenAiApiClient {
  OpenAiApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _transcriptionTimeout = Duration(minutes: 10);
  static const _dashScopeApi = 'https://dashscope.aliyuncs.com';

  Future<ApiOperationResult> testText({
    required TextProviderConfig config,
    required String apiKey,
  }) async {
    if (config.protocol == TextProviderProtocol.chatCompletions) {
      final response = await _sendJson(
        _endpoint(config.baseUrl, 'chat/completions'),
        apiKey,
        {
          'model': config.model,
          'messages': [
            {
              'role': 'user',
              'content': 'Reply exactly: SekuxNote text API test passed.',
            },
          ],
          'stream': false,
          'max_tokens': 32,
        },
      );
      final body = _decodeJson(response.body);
      final choices = body['choices'];
      final output = choices is List && choices.isNotEmpty
          ? _map(_map(choices.first)['message'])['content'] as String? ?? ''
          : '';
      return ApiOperationResult(
        model: body['model'] as String? ?? config.model,
        output: output,
        usage: _usage(body),
      );
    }
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

  Stream<TextGenerationChunk> streamText({
    required TextProviderConfig config,
    required String apiKey,
    required String model,
    required List<TextChatMessage> messages,
  }) async* {
    final isResponses = config.protocol == TextProviderProtocol.responses;
    final request =
        http.Request(
            'POST',
            _endpoint(
              config.baseUrl,
              isResponses ? 'responses' : 'chat/completions',
            ),
          )
          ..headers.addAll({
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          })
          ..body = jsonEncode(
            isResponses
                ? {
                    'model': model,
                    'input': messages.map((value) => value.toJson()).toList(),
                    'stream': true,
                    'store': false,
                  }
                : {
                    'model': model,
                    'messages': messages
                        .map((value) => value.toJson())
                        .toList(),
                    'stream': true,
                  },
          );
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 45));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      await ProviderDebugLog.record(
        'text_generation.failure',
        details: {
          'host': request.url.host,
          'statusCode': response.statusCode,
          'error': _responseDiagnostic(body),
        },
      );
      _ensureStatusCode(response.statusCode);
    }
    String? responseModel;
    var usage = const <String, Object?>{};
    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (!line.startsWith('data:')) continue;
      final data = line.substring(5).trim();
      if (data.isEmpty || data == '[DONE]') continue;
      final event = _decodeJson(data);
      responseModel = event['model'] as String? ?? responseModel;
      final nextUsage = _usage(event);
      if (nextUsage.isNotEmpty) usage = nextUsage;
      String delta = '';
      if (isResponses) {
        if (event['type'] == 'response.output_text.delta') {
          delta = event['delta'] as String? ?? '';
        }
        final completed = _map(event['response']);
        responseModel = completed['model'] as String? ?? responseModel;
        final completedUsage = _usage(completed);
        if (completedUsage.isNotEmpty) usage = completedUsage;
      } else {
        final choices = event['choices'];
        if (choices is List && choices.isNotEmpty) {
          final choice = _map(choices.first);
          delta = _map(choice['delta'])['content'] as String? ?? '';
        }
      }
      if (delta.isNotEmpty) {
        yield TextGenerationChunk(text: delta, model: responseModel);
      }
    }
    yield TextGenerationChunk(
      text: '',
      model: responseModel ?? model,
      usage: usage,
      done: true,
    );
  }

  Future<TranscriptionResult> transcribe({
    required TranscriptionProviderConfig config,
    required String apiKey,
    required SelectedAudioFile file,
    TranscriptionRequestOptions? options,
    void Function(String text)? onPartialText,
    Future<void> Function(String taskId)? onRemoteTaskCreated,
  }) {
    final requestOptions =
        options ?? TranscriptionRequestOptions(language: config.language);
    return switch (config.type) {
      TranscriptionProviderType.openAiCompatible => _transcribeOpenAi(
        config: config,
        apiKey: apiKey,
        file: file,
        options: requestOptions,
      ),
      TranscriptionProviderType.dashScopeFunAsr =>
        config.batchModel.startsWith('fun-asr-flash')
            ? _transcribeDashScopeFunAsrFlash(
                config: config,
                apiKey: apiKey,
                file: file,
                onPartialText: onPartialText,
              )
            : _transcribeDashScopeFunAsr(
                config: config,
                apiKey: apiKey,
                file: file,
                options: requestOptions,
                onRemoteTaskCreated: onRemoteTaskCreated,
              ),
      TranscriptionProviderType.geminiTranscribe => _transcribeGemini(
        config: config,
        apiKey: apiKey,
        file: file,
        options: requestOptions,
      ),
    };
  }

  Future<TranscriptionResult> _transcribeDashScopeFunAsrFlash({
    required TranscriptionProviderConfig config,
    required String apiKey,
    required SelectedAudioFile file,
    void Function(String text)? onPartialText,
  }) async {
    final apiBaseUrl = config.dashScopeApiUrl?.trim() ?? '';
    final apiBase = Uri.tryParse(apiBaseUrl);
    if (apiBase == null || !apiBase.hasScheme || apiBase.host.isEmpty) {
      throw const ProviderRequestException('dashScopeApiUrlMissing');
    }
    final encodedAudio = base64Encode(file.bytes);
    final dataUri = 'data:${_audioContentType(file.name)};base64,$encodedAudio';
    if (utf8.encode(dataUri).length > 10 * 1024 * 1024) {
      throw const ProviderRequestException('audioFileTooLarge');
    }
    final base = apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final request =
        http.Request(
            'POST',
            Uri.parse('$base/services/aigc/multimodal-generation/generation'),
          )
          ..headers.addAll({
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'X-DashScope-SSE': 'enable',
          })
          ..body = jsonEncode({
            'model': config.batchModel,
            'input': {
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'input_audio',
                      'input_audio': {'data': dataUri},
                    },
                  ],
                },
              ],
            },
            'parameters': {'format': _audioExtension(file.name)},
          });
    await ProviderDebugLog.record(
      'dashscope_flash.start',
      details: {'model': config.batchModel, 'fileBytes': file.sizeBytes},
    );
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      await ProviderDebugLog.record(
        'provider_request.failure',
        details: {
          'stage': 'dashscope.flash',
          'host': request.url.host,
          'statusCode': response.statusCode,
          'error': _responseDiagnostic(body),
        },
      );
      _ensureStatusCode(response.statusCode);
    }

    var text = '';
    var usage = const <String, Object?>{};
    var committedText = '';
    var lastEndSeconds = 0.0;
    final segments = <TranscriptionSegment>[];
    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .timeout(_transcriptionTimeout);
    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final value = line.substring(5).trim();
      if (value.isEmpty || value == '[DONE]') continue;
      final event = _decodeJson(value);
      final output = _map(event['output']);
      final nextText = output['text'] as String? ?? '';
      if (nextText.isNotEmpty) {
        text = nextText;
        onPartialText?.call(text);
      }
      final sentence = _map(output['sentence']);
      if (sentence['sentence_end'] == true) {
        final rawSegment = _dashScopeFlashSegment(sentence);
        final snapshot = nextText.isNotEmpty ? nextText : rawSegment.text;
        final segmentText = snapshot.startsWith(committedText)
            ? snapshot.substring(committedText.length).trim()
            : rawSegment.text.trim();
        if (segmentText.isNotEmpty) {
          final startSeconds = rawSegment.startSeconds < lastEndSeconds
              ? lastEndSeconds
              : rawSegment.startSeconds;
          segments.add(
            TranscriptionSegment(
              startSeconds: startSeconds,
              endSeconds: rawSegment.endSeconds,
              text: segmentText,
              words: rawSegment.words
                  .where((word) => word.startSeconds >= startSeconds)
                  .toList(growable: false),
            ),
          );
          lastEndSeconds = rawSegment.endSeconds;
        }
        committedText = snapshot;
      }
      final nextUsage = _map(event['usage']);
      if (nextUsage.isNotEmpty) usage = nextUsage;
    }
    if (text.isEmpty && segments.isEmpty) {
      throw const ProviderRequestException('invalidProviderResponse');
    }
    return TranscriptionResult(
      fileName: file.name,
      providerName: config.name,
      model: config.batchModel,
      text: text,
      usage: usage,
      segments: segments,
    );
  }

  Future<TranscriptionResult> _transcribeOpenAi({
    required TranscriptionProviderConfig config,
    required String apiKey,
    required SelectedAudioFile file,
    required TranscriptionRequestOptions options,
  }) async {
    if (file.sizeBytes >= 25 * 1024 * 1024) {
      throw const ProviderRequestException('audioFileTooLarge');
    }
    final endpoint = _endpoint(config.baseUrl, 'audio/transcriptions');
    final request = http.MultipartRequest('POST', endpoint)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = config.batchModel
      ..fields['response_format'] =
          config.batchModel == 'gpt-4o-transcribe-diarize'
          ? 'diarized_json'
          : 'verbose_json'
      ..fields['language'] = options.language
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes,
          filename: file.name,
          contentType: _audioContentType(file.name),
        ),
      );
    if (config.batchModel == 'gpt-4o-transcribe-diarize') {
      request.fields['chunking_strategy'] = 'auto';
    } else {
      request.fields['timestamp_granularities[]'] = 'segment';
    }
    await ProviderDebugLog.record(
      'openai_transcription.start',
      details: {'model': config.batchModel, 'fileBytes': file.sizeBytes},
    );
    final response = await _sendMultipart(request);
    final body = _decodeJson(response.body);
    return TranscriptionResult(
      fileName: file.name,
      providerName: config.name,
      model: config.batchModel,
      text: body['text'] as String? ?? '',
      usage: _usage(body),
      segments: _openAiSegments(body),
    );
  }

  /// Gemini 3.5 Transcribe via the Interactions API.
  ///
  /// Files under 12 MB go inline as base64. Larger files use the Files API
  /// first, then `interactions.create` with the returned URI.
  static const _geminiInlineLimitBytes = 12 * 1024 * 1024;

  Future<TranscriptionResult> _transcribeGemini({
    required TranscriptionProviderConfig config,
    required String apiKey,
    required SelectedAudioFile file,
    required TranscriptionRequestOptions options,
  }) async {
    await ProviderDebugLog.record(
      'gemini_transcription.start',
      details: {'model': config.batchModel, 'fileBytes': file.sizeBytes},
    );
    final mimeType = _geminiMimeType(file.name);
    final Map<String, Object?> audioInput;
    if (file.sizeBytes <= _geminiInlineLimitBytes) {
      audioInput = {
        'type': 'audio',
        'data': base64Encode(file.bytes),
        'mime_type': mimeType,
      };
    } else {
      final uploaded = await _uploadGeminiFile(
        config: config,
        apiKey: apiKey,
        file: file,
        mimeType: mimeType,
      );
      audioInput = {
        'type': 'audio',
        'uri': uploaded['uri'],
        'mime_type': uploaded['mime_type'] ?? mimeType,
      };
    }
    final response = await _sendGeminiJson(
      uri: _geminiEndpoint(config.baseUrl, 'v1beta/interactions'),
      apiKey: apiKey,
      body: {
        'model': config.batchModel,
        'input': [audioInput],
        'generation_config': {
          'transcription_config': geminiTranscriptionConfig(options),
        },
      },
    );
    final body = _decodeJson(response.body);
    final parsed = parseGeminiTranscription(body);
    if (parsed.text.trim().isEmpty && parsed.segments.isEmpty) {
      throw const ProviderRequestException('invalidProviderResponse');
    }
    return TranscriptionResult(
      fileName: file.name,
      providerName: config.name,
      model: config.batchModel,
      text: parsed.text,
      usage: _usage(body),
      segments: parsed.segments,
    );
  }

  Future<Map<String, Object?>> _uploadGeminiFile({
    required TranscriptionProviderConfig config,
    required String apiKey,
    required SelectedAudioFile file,
    required String mimeType,
  }) async {
    final start = await _client
        .post(
          _geminiEndpoint(config.baseUrl, 'upload/v1beta/files'),
          headers: {
            'x-goog-api-key': apiKey,
            'X-Goog-Upload-Protocol': 'resumable',
            'X-Goog-Upload-Command': 'start',
            'X-Goog-Upload-Header-Content-Length': '${file.sizeBytes}',
            'X-Goog-Upload-Header-Content-Type': mimeType,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'file': {'display_name': file.name},
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (start.statusCode < 200 || start.statusCode >= 300) {
      await ProviderDebugLog.record(
        'provider_request.failure',
        details: {
          'stage': 'gemini.upload_start',
          'statusCode': start.statusCode,
          'error': _responseDiagnostic(start.body),
        },
      );
      _ensureStatusCode(start.statusCode);
    }
    final uploadUrl = start.headers['x-goog-upload-url'];
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw const ProviderRequestException('invalidProviderResponse');
    }
    final uploaded = await _client
        .put(
          Uri.parse(uploadUrl),
          headers: {
            'Content-Length': '${file.sizeBytes}',
            'X-Goog-Upload-Offset': '0',
            'X-Goog-Upload-Command': 'upload, finalize',
            'Content-Type': mimeType,
          },
          body: file.bytes,
        )
        .timeout(_transcriptionTimeout);
    if (uploaded.statusCode < 200 || uploaded.statusCode >= 300) {
      await ProviderDebugLog.record(
        'provider_request.failure',
        details: {
          'stage': 'gemini.upload_finalize',
          'statusCode': uploaded.statusCode,
          'error': _responseDiagnostic(uploaded.body),
        },
      );
      _ensureStatusCode(uploaded.statusCode);
    }
    var fileInfo = _map(_decodeJson(uploaded.body)['file']);
    if (fileInfo.isEmpty) fileInfo = _decodeJson(uploaded.body);
    final name = fileInfo['name'] as String?;
    var state = (fileInfo['state'] as String? ?? '').toUpperCase();
    var uri = fileInfo['uri'] as String?;
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while ((uri == null || uri.isEmpty || state == 'PROCESSING') &&
        name != null &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final polled = await _client
          .get(
            _geminiEndpoint(config.baseUrl, 'v1beta/$name'),
            headers: {'x-goog-api-key': apiKey},
          )
          .timeout(const Duration(seconds: 15));
      _ensureSuccess(polled);
      final body = _decodeJson(polled.body);
      state = (body['state'] as String? ?? '').toUpperCase();
      uri = body['uri'] as String? ?? uri;
      fileInfo = body;
    }
    if (uri == null || uri.isEmpty) {
      throw const ProviderRequestException('invalidProviderResponse');
    }
    return {
      'uri': uri,
      'mime_type': fileInfo['mimeType'] ?? fileInfo['mime_type'] ?? mimeType,
    };
  }

  Future<http.Response> _sendGeminiJson({
    required Uri uri,
    required String apiKey,
    required Map<String, Object?> body,
  }) async {
    final response = await _client
        .post(
          uri,
          headers: {
            'x-goog-api-key': apiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_transcriptionTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await ProviderDebugLog.record(
        'provider_request.failure',
        details: {
          'stage': 'gemini.interactions',
          'host': uri.host,
          'statusCode': response.statusCode,
          'error': _responseDiagnostic(response.body),
        },
      );
    }
    _ensureSuccess(response);
    return response;
  }

  Uri _geminiEndpoint(String baseUrl, String path) {
    final raw = baseUrl.trim().isEmpty
        ? 'https://generativelanguage.googleapis.com'
        : baseUrl.trim();
    final normalized = raw
        .replaceFirst(RegExp(r'/+$'), '')
        .replaceFirst(RegExp(r'/v1beta$'), '');
    final uri = Uri.tryParse('$normalized/$path');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const ProviderRequestException('invalidBaseUrl');
    }
    return uri;
  }

  String _geminiMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'wav' => 'audio/wav',
      'mp3' => 'audio/mp3',
      'mpeg' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'aac' => 'audio/aac',
      'flac' => 'audio/flac',
      'ogg' => 'audio/ogg',
      'webm' => 'audio/webm',
      _ => 'application/octet-stream',
    };
  }

  Future<TranscriptionResult> _transcribeDashScopeFunAsr({
    required TranscriptionProviderConfig config,
    required String apiKey,
    required SelectedAudioFile file,
    required TranscriptionRequestOptions options,
    Future<void> Function(String taskId)? onRemoteTaskCreated,
  }) async {
    final apiBaseUrl = config.dashScopeApiUrl?.trim() ?? '';
    final apiBase = Uri.tryParse(apiBaseUrl);
    if (apiBase == null || !apiBase.hasScheme || apiBase.host.isEmpty) {
      throw const ProviderRequestException('dashScopeApiUrlMissing');
    }
    await ProviderDebugLog.record(
      'dashscope_transcription.start',
      details: {'model': config.batchModel, 'fileBytes': file.sizeBytes},
    );
    final temporaryUrl = await _uploadDashScopeTemporaryFile(
      apiKey: apiKey,
      file: file,
      model: config.batchModel,
    );
    final base = apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final parameters = <String, Object?>{
      'channel_id': [0],
      'language_hints': [options.language],
    };
    if (options.diarizationEnabled) {
      parameters['diarization_enabled'] = true;
      if (options.speakerCount != null) {
        parameters['speaker_count'] = options.speakerCount!;
      }
    }
    final submit = await _client
        .post(
          Uri.parse('$base/services/audio/asr/transcription'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'X-DashScope-Async': 'enable',
            'X-DashScope-OssResourceResolve': 'enable',
          },
          body: jsonEncode({
            'model': config.batchModel,
            'input': {
              'file_urls': [temporaryUrl],
            },
            'parameters': parameters,
          }),
        )
        .timeout(const Duration(seconds: 30));
    await _recordDashScopeFailure(
      stage: 'dashscope.task_submit',
      response: submit,
    );
    _ensureSuccess(submit);
    final submitBody = _decodeJson(submit.body);
    final output = _map(submitBody['output']);
    final taskId = output['task_id'] as String?;
    if (taskId == null || taskId.isEmpty) {
      throw const ProviderRequestException('invalidProviderResponse');
    }
    await onRemoteTaskCreated?.call(taskId);
    final task = await _waitForDashScopeTask(
      baseUrl: base,
      taskId: taskId,
      apiKey: apiKey,
    );
    return _dashScopeTaskResult(
      task: task,
      config: config,
      fileName: file.name,
    );
  }

  Future<TranscriptionResult> resumeDashScopeFunAsr({
    required TranscriptionProviderConfig config,
    required String apiKey,
    required String fileName,
    required String taskId,
  }) async {
    final apiBaseUrl = config.dashScopeApiUrl?.trim() ?? '';
    final apiBase = Uri.tryParse(apiBaseUrl);
    if (apiBase == null || !apiBase.hasScheme || apiBase.host.isEmpty) {
      throw const ProviderRequestException('dashScopeApiUrlMissing');
    }
    final task = await _waitForDashScopeTask(
      baseUrl: apiBaseUrl.replaceFirst(RegExp(r'/+$'), ''),
      taskId: taskId,
      apiKey: apiKey,
    );
    return _dashScopeTaskResult(task: task, config: config, fileName: fileName);
  }

  Future<TranscriptionResult> _dashScopeTaskResult({
    required Map<String, Object?> task,
    required TranscriptionProviderConfig config,
    required String fileName,
  }) async {
    final taskOutput = _map(task['output']);
    final results = taskOutput['results'];
    if (results is! List || results.isEmpty) {
      throw const ProviderRequestException('invalidProviderResponse');
    }
    final result = _map(results.first);
    if (result['subtask_status'] != 'SUCCEEDED') {
      throw const ProviderRequestException('requestFailed');
    }
    final transcriptionUrl = result['transcription_url'] as String?;
    if (transcriptionUrl == null || transcriptionUrl.isEmpty) {
      throw const ProviderRequestException('invalidProviderResponse');
    }
    final transcriptionResponse = await _client
        .get(Uri.parse(transcriptionUrl))
        .timeout(const Duration(seconds: 30));
    await _recordDashScopeFailure(
      stage: 'dashscope.result_download',
      response: transcriptionResponse,
    );
    _ensureSuccess(transcriptionResponse);
    final transcription = _decodeJson(transcriptionResponse.body);
    final segments = _dashScopeSegments(transcription);
    final transcripts = transcription['transcripts'];
    final text = transcripts is List && transcripts.isNotEmpty
        ? _map(transcripts.first)['text'] as String? ?? ''
        : segments.map((segment) => segment.text).join('\n');
    return TranscriptionResult(
      fileName: fileName,
      providerName: config.name,
      model: config.batchModel,
      text: text,
      usage: _map(task['usage']),
      segments: segments,
    );
  }

  Future<String> _uploadDashScopeTemporaryFile({
    required String apiKey,
    required SelectedAudioFile file,
    required String model,
  }) async {
    final policyResponse = await _client
        .get(
          Uri.parse(
            '$_dashScopeApi/api/v1/uploads',
          ).replace(queryParameters: {'action': 'getPolicy', 'model': model}),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 30));
    await _recordDashScopeFailure(
      stage: 'dashscope.upload_policy',
      response: policyResponse,
    );
    _ensureSuccess(policyResponse);
    final policy = _map(_decodeJson(policyResponse.body)['data']);
    final host = policy['upload_host'] as String?;
    final directory = policy['upload_dir'] as String?;
    if (host == null || directory == null) {
      throw const ProviderRequestException('invalidProviderResponse');
    }
    final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final key = '$directory/${DateTime.now().microsecondsSinceEpoch}-$safeName';
    await _sendDashScopeOssForm(
      uri: Uri.parse(host),
      fields: {
        'OSSAccessKeyId': policy['oss_access_key_id'] as String? ?? '',
        'policy': policy['policy'] as String? ?? '',
        'Signature': policy['signature'] as String? ?? '',
        'key': key,
        'x-oss-object-acl': policy['x_oss_object_acl'] as String? ?? 'private',
        'x-oss-forbid-overwrite':
            policy['x_oss_forbid_overwrite'] as String? ?? 'true',
        'success_action_status': '200',
      },
      file: file,
      filename: safeName,
    );
    return 'oss://$key';
  }

  Future<Map<String, Object?>> _waitForDashScopeTask({
    required String baseUrl,
    required String taskId,
    required String apiKey,
  }) async {
    final deadline = DateTime.now().add(_transcriptionTimeout);
    while (true) {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/tasks/$taskId'),
            headers: {'Authorization': 'Bearer $apiKey'},
          )
          .timeout(const Duration(seconds: 30));
      await _recordDashScopeFailure(
        stage: 'dashscope.task_poll',
        response: response,
      );
      _ensureSuccess(response);
      final body = _decodeJson(response.body);
      final status = _map(body['output'])['task_status'] as String?;
      if (status == 'SUCCEEDED') return body;
      if (status == 'FAILED' || status == 'CANCELED') {
        throw const ProviderRequestException('requestFailed');
      }
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('DashScope transcription task timeout');
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  Future<http.Response> _sendMultipart(
    http.MultipartRequest request, {
    String diagnosticStage = 'transcription.upload',
  }) => _sendRequest(request, diagnosticStage: diagnosticStage);

  /// OSS's PostObject parser requires every part to start with
  /// Content-Disposition. package:http emits Content-Type first for a file
  /// part, which OSS rejects as malformed multipart data.
  Future<http.Response> _sendDashScopeOssForm({
    required Uri uri,
    required Map<String, String> fields,
    required SelectedAudioFile file,
    required String filename,
  }) {
    final boundary = '----SekuxNote${Random.secure().nextInt(1 << 32)}';
    final body = BytesBuilder(copy: false);
    void writeText(String value) => body.add(utf8.encode(value));

    for (final field in fields.entries) {
      writeText('--$boundary\r\n');
      writeText(
        'Content-Disposition: form-data; '
        'name="${_formHeaderValue(field.key)}"\r\n\r\n',
      );
      writeText(field.value);
      writeText('\r\n');
    }
    writeText('--$boundary\r\n');
    writeText(
      'Content-Disposition: form-data; name="file"; '
      'filename="${_formHeaderValue(filename)}"\r\n',
    );
    writeText('Content-Type: ${_audioContentType(file.name)}\r\n\r\n');
    body.add(file.bytes);
    writeText('\r\n--$boundary--\r\n');

    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'multipart/form-data; boundary=$boundary'
      ..bodyBytes = body.toBytes();
    return _sendRequest(request, diagnosticStage: 'dashscope.upload');
  }

  Future<http.Response> _sendRequest(
    http.BaseRequest request, {
    required String diagnosticStage,
  }) async {
    try {
      final streamed = await _client
          .send(request)
          .timeout(_transcriptionTimeout);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await ProviderDebugLog.record(
          'provider_request.failure',
          details: {
            'stage': diagnosticStage,
            'host': request.url.host,
            'statusCode': response.statusCode,
            'error': _responseDiagnostic(response.body),
          },
        );
      }
      _ensureSuccess(response);
      return response;
    } catch (error) {
      await ProviderDebugLog.record(
        'transcription.error',
        details: {'type': error.runtimeType, 'message': error.toString()},
      );
      rethrow;
    }
  }

  String _formHeaderValue(String value) =>
      value.replaceAll(RegExp(r'[\r\n]'), '').replaceAll('"', '%22');

  Future<void> _recordDashScopeFailure({
    required String stage,
    required http.Response response,
  }) async {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    await ProviderDebugLog.record(
      'provider_request.failure',
      details: {
        'stage': stage,
        'host': response.request?.url.host ?? 'unknown',
        'statusCode': response.statusCode,
        'error': _responseDiagnostic(response.body),
      },
    );
  }

  /// Keeps local diagnostics actionable without persisting response bodies,
  /// which may contain user content or short-lived provider credentials.
  String _responseDiagnostic(String body) {
    for (final line in const LineSplitter().convert(body)) {
      if (!line.startsWith('data:')) continue;
      final data = line.substring(5).trim();
      if (data.isEmpty) continue;
      final diagnostic = _jsonDiagnostic(data);
      if (diagnostic.isNotEmpty) return diagnostic;
    }
    final jsonDiagnostic = _jsonDiagnostic(body);
    if (jsonDiagnostic.isNotEmpty) return jsonDiagnostic;
    return _compactDiagnostic(
      code: _xmlElement(body, 'Code'),
      message: _xmlElement(body, 'Message'),
      requestId: _xmlElement(body, 'RequestId'),
    );
  }

  String _jsonDiagnostic(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final map = Map<String, Object?>.from(decoded);
        final error = map['error'];
        final errorMap = error is Map ? Map<String, Object?>.from(error) : null;
        return _compactDiagnostic(
          code: map['code'] ?? errorMap?['code'] ?? errorMap?['type'],
          message: map['message'] ?? errorMap?['message'] ?? error,
          requestId: map['request_id'] ?? map['requestId'],
        );
      }
    } on FormatException {
      // OSS sends XML errors; handled below.
    }
    return '';
  }

  String _compactDiagnostic({
    Object? code,
    Object? message,
    Object? requestId,
  }) {
    final values = <String>[
      if (code?.toString().trim().isNotEmpty == true) 'code=$code',
      if (message?.toString().trim().isNotEmpty == true) 'message=$message',
      if (requestId?.toString().trim().isNotEmpty == true)
        'requestId=$requestId',
    ];
    final result = values.join('; ');
    return result.length <= 500 ? result : '${result.substring(0, 500)}…';
  }

  String? _xmlElement(String body, String name) {
    final match = RegExp('<$name>([^<]+)</$name>').firstMatch(body);
    return match?.group(1);
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
    _ensureStatusCode(response.statusCode);
  }

  Never _ensureStatusCode(int statusCode) {
    final message = switch (statusCode) {
      400 => 'badRequest',
      401 => 'unauthorized',
      403 => 'forbidden',
      413 => 'audioFileTooLarge',
      429 => 'rateLimited',
      >= 500 => 'providerUnavailable',
      _ => 'requestFailed',
    };
    throw ProviderRequestException(message);
  }

  String _audioExtension(String fileName) {
    final value = fileName.split('.').last.toLowerCase();
    return switch (value) {
      'm4a' => 'm4a',
      'mp3' => 'mp3',
      'wav' => 'wav',
      _ => value,
    };
  }

  TranscriptionSegment _dashScopeFlashSegment(Map<String, Object?> sentence) {
    final words = (sentence['words'] as List<Object?>? ?? const [])
        .whereType<Map>()
        .map((item) {
          final word = _map(item);
          return TranscriptionWord(
            startSeconds:
                ((word['begin_time'] as num?)?.toDouble() ?? 0) / 1000,
            endSeconds: ((word['end_time'] as num?)?.toDouble() ?? 0) / 1000,
            text: word['text'] as String? ?? '',
            punctuation: word['punctuation'] as String? ?? '',
          );
        })
        .toList(growable: false);
    return TranscriptionSegment(
      startSeconds: ((sentence['begin_time'] as num?)?.toDouble() ?? 0) / 1000,
      endSeconds: ((sentence['end_time'] as num?)?.toDouble() ?? 0) / 1000,
      text: sentence['text'] as String? ?? '',
      words: words,
    );
  }

  MediaType _audioContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'm4a' => MediaType('audio', 'mp4'),
      'mp3' => MediaType('audio', 'mpeg'),
      'wav' => MediaType('audio', 'wav'),
      _ => MediaType('application', 'octet-stream'),
    };
  }

  Map<String, Object?> _decodeJson(String value) {
    try {
      return Map<String, Object?>.from(jsonDecode(value) as Map);
    } on FormatException {
      throw const ProviderRequestException('invalidProviderResponse');
    }
  }

  Map<String, Object?> _map(Object? value) => value is Map
      ? Map<String, Object?>.from(value)
      : const <String, Object?>{};

  Map<String, Object?> _usage(Map<String, Object?> body) => _map(body['usage']);

  List<TranscriptionSegment> _openAiSegments(Map<String, Object?> body) {
    final values = body['segments'];
    if (values is! List) return const [];
    return values
        .whereType<Map>()
        .map((value) {
          final segment = _map(value);
          return TranscriptionSegment(
            startSeconds: (segment['start'] as num?)?.toDouble() ?? 0,
            endSeconds: (segment['end'] as num?)?.toDouble() ?? 0,
            text: segment['text'] as String? ?? '',
          );
        })
        .where((segment) => segment.text.trim().isNotEmpty)
        .toList();
  }

  List<TranscriptionSegment> _dashScopeSegments(Map<String, Object?> body) {
    final transcripts = body['transcripts'];
    if (transcripts is! List) return const [];
    final segments = <TranscriptionSegment>[];
    for (final transcript in transcripts.whereType<Map>()) {
      final sentences = _map(transcript)['sentences'];
      if (sentences is! List) continue;
      for (final value in sentences.whereType<Map>()) {
        final sentence = _map(value);
        final words = (sentence['words'] as List<Object?>? ?? const [])
            .whereType<Map>()
            .map((item) {
              final word = _map(item);
              return TranscriptionWord(
                startSeconds:
                    ((word['begin_time'] as num?)?.toDouble() ?? 0) / 1000,
                endSeconds:
                    ((word['end_time'] as num?)?.toDouble() ?? 0) / 1000,
                text: word['text'] as String? ?? '',
                punctuation: word['punctuation'] as String? ?? '',
              );
            })
            .toList(growable: false);
        segments.add(
          TranscriptionSegment(
            startSeconds:
                ((sentence['begin_time'] as num?)?.toDouble() ?? 0) / 1000,
            endSeconds:
                ((sentence['end_time'] as num?)?.toDouble() ?? 0) / 1000,
            text: sentence['text'] as String? ?? '',
            speakerId: sentence['speaker_id'] as int?,
            words: words,
          ),
        );
      }
    }
    return segments.where((segment) => segment.text.trim().isNotEmpty).toList();
  }

  String _responseText(Map<String, Object?> body) {
    final output = body['output'];
    if (output is! List) return '';
    final parts = <String>[];
    for (final item in output.whereType<Map>()) {
      final content = _map(item)['content'];
      if (content is! List) continue;
      for (final value in content.whereType<Map>()) {
        final item = _map(value);
        if (item['type'] == 'output_text' && item['text'] is String) {
          parts.add(item['text'] as String);
        }
      }
    }
    return parts.join();
  }

  void close() => _client.close();
}

List<String> geminiLanguageCodes(String language) {
  final value = language.trim();
  if (value.isEmpty || value.toLowerCase() == 'auto') return const [];
  if (value.contains('-')) return [value];
  const mapped = {
    'zh': 'zh-CN',
    'en': 'en-US',
    'ja': 'ja-JP',
    'ko': 'ko-KR',
    'fr': 'fr-FR',
    'de': 'de-DE',
    'es': 'es-ES',
    'pt': 'pt-BR',
    'it': 'it-IT',
    'ru': 'ru-RU',
    'ar': 'ar-EG',
    'hi': 'hi-IN',
    'th': 'th-TH',
    'vi': 'vi-VN',
    'id': 'id-ID',
    'ms': 'ms-MY',
    'tr': 'tr-TR',
    'nl': 'nl-NL',
    'pl': 'pl-PL',
    'sv': 'sv-SE',
  };
  return [mapped[value.toLowerCase()] ?? value];
}

Map<String, Object?> geminiTranscriptionConfig(
  TranscriptionRequestOptions options,
) {
  final config = <String, Object?>{
    'language_codes': geminiLanguageCodes(options.language),
  };
  if (options.customVocabulary.isNotEmpty) {
    config['custom_vocabulary'] = options.customVocabulary
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(1000)
        .toList(growable: false);
  }
  final useSmart = options.smartFormatting && !options.diarizationEnabled;
  if (useSmart) {
    config['mode'] = {'type': 'smart'};
  } else {
    final mode = <String, Object?>{'type': 'verbatim'};
    if (options.diarizationEnabled) {
      mode['diarization_mode'] = 'speaker';
    }
    mode['timestamp_granularities'] = ['word'];
    config['mode'] = mode;
  }
  return config;
}

class GeminiTranscriptionParse {
  const GeminiTranscriptionParse({
    required this.text,
    required this.segments,
  });

  final String text;
  final List<TranscriptionSegment> segments;
}

GeminiTranscriptionParse parseGeminiTranscription(Map<String, Object?> body) {
  final words = <_GeminiWord>[];
  final textParts = <String>[];

  void walk(Object? node) {
    if (node is List) {
      for (final item in node) {
        walk(item);
      }
      return;
    }
    if (node is! Map) return;
    final map = Map<String, Object?>.from(node);
    final type = map['type'] as String? ?? '';
    final text = map['text'] as String?;
    if ((type == 'text' || type == 'output_text') &&
        text != null &&
        text.isNotEmpty) {
      textParts.add(text);
    }
    final annotations = map['annotations'];
    if (annotations is List) {
      for (final annotation in annotations.whereType<Map>()) {
        final item = Map<String, Object?>.from(annotation);
        final annotationType = item['type'] as String? ?? '';
        if (annotationType != 'word_info' && annotationType != 'wordInfo') {
          continue;
        }
        final wordText = item['text'] as String? ?? '';
        if (wordText.isEmpty) continue;
        words.add(
          _GeminiWord(
            text: wordText,
            speakerId: _geminiSpeakerId(
              item['speaker'] ?? item['speaker_id'] ?? item['speakerId'],
            ),
            startSeconds: _geminiOffsetSeconds(
              item['start_offset'] ?? item['startOffset'] ?? item['start'],
            ),
            endSeconds: _geminiOffsetSeconds(
              item['end_offset'] ?? item['endOffset'] ?? item['end'],
            ),
          ),
        );
      }
    }
    for (final value in map.values) {
      if (value is Map || value is List) walk(value);
    }
  }

  walk(body['steps'] ?? body['output'] ?? body);
  final outputText = body['output_text'] as String? ??
      body['outputText'] as String? ??
      '';
  final text = outputText.trim().isNotEmpty
      ? outputText
      : textParts.join().trim();
  if (words.isEmpty) {
    return GeminiTranscriptionParse(
      text: text,
      segments: text.trim().isEmpty
          ? const []
          : [
              TranscriptionSegment(
                startSeconds: 0,
                endSeconds: 0,
                text: text,
              ),
            ],
    );
  }
  return GeminiTranscriptionParse(
    text: text.trim().isNotEmpty
        ? text
        : words.map((word) => word.text).join(' '),
    segments: _geminiSegmentsFromWords(words),
  );
}

class _GeminiWord {
  const _GeminiWord({
    required this.text,
    required this.startSeconds,
    required this.endSeconds,
    this.speakerId,
  });

  final String text;
  final double startSeconds;
  final double endSeconds;
  final int? speakerId;
}

int? _geminiSpeakerId(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  final match = RegExp(r'(\d+)').firstMatch(value.toString());
  return match == null ? null : int.tryParse(match.group(1)!);
}

double _geminiOffsetSeconds(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  final raw = value.toString().trim().toLowerCase();
  if (raw.endsWith('ms')) {
    return (double.tryParse(raw.substring(0, raw.length - 2)) ?? 0) / 1000;
  }
  if (raw.endsWith('s')) {
    return double.tryParse(raw.substring(0, raw.length - 1)) ?? 0;
  }
  return double.tryParse(raw) ?? 0;
}

List<TranscriptionSegment> _geminiSegmentsFromWords(List<_GeminiWord> words) {
  final segments = <TranscriptionSegment>[];
  var bucket = <_GeminiWord>[];

  void flush() {
    if (bucket.isEmpty) return;
    segments.add(
      TranscriptionSegment(
        startSeconds: bucket.first.startSeconds,
        endSeconds: bucket.last.endSeconds,
        text: bucket.map((word) => word.text).join(' '),
        speakerId: bucket.first.speakerId,
        words: bucket
            .map(
              (word) => TranscriptionWord(
                startSeconds: word.startSeconds,
                endSeconds: word.endSeconds,
                text: word.text,
              ),
            )
            .toList(growable: false),
      ),
    );
    bucket = [];
  }

  for (final word in words) {
    if (bucket.isNotEmpty && bucket.first.speakerId != word.speakerId) {
      flush();
    }
    bucket.add(word);
  }
  flush();
  return segments;
}
