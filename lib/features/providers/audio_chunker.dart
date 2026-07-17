import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'openai_api_client.dart';
import 'provider_models.dart';

abstract interface class AudioChunker {
  Future<List<SelectedAudioFile>> split(
    SelectedAudioFile source, {
    required int chunkDurationSeconds,
  });
}

/// Uses macOS AVFoundation so the release app does not depend on an external
/// ffmpeg installation. Chunks are temporary and removed after the task ends.
class PlatformAudioChunker implements AudioChunker {
  static const _channel = MethodChannel('com.sekuxnote/audio_chunker');

  @override
  Future<List<SelectedAudioFile>> split(
    SelectedAudioFile source, {
    required int chunkDurationSeconds,
  }) async {
    if (!Platform.isMacOS) {
      throw const ProviderRequestException('audioChunkingUnavailable');
    }
    if (chunkDurationSeconds <= 0) {
      throw const ProviderRequestException('invalidChunkDuration');
    }

    final directory = await getApplicationSupportDirectory();
    final taskDirectory = Directory(
      '${directory.path}/transcription_chunks/'
      '${DateTime.now().microsecondsSinceEpoch}',
    );
    await taskDirectory.create(recursive: true);
    final extension = _extensionFor(source.name);
    final input = File('${taskDirectory.path}/source.$extension');
    await input.writeAsBytes(source.bytes, flush: true);
    final outputDirectory = Directory('${taskDirectory.path}/chunks');
    await outputDirectory.create();

    try {
      final paths = await _channel.invokeListMethod<String>('split', {
        'inputPath': input.path,
        'outputDirectory': outputDirectory.path,
        'chunkDurationSeconds': chunkDurationSeconds,
      });
      if (paths == null || paths.isEmpty) {
        throw const ProviderRequestException('audioChunkingFailed');
      }
      return await Future.wait(
        paths.map((path) async {
          final file = File(path);
          return SelectedAudioFile(
            name: file.uri.pathSegments.last,
            bytes: await file.readAsBytes(),
          );
        }),
      );
    } finally {
      await taskDirectory.delete(recursive: true);
    }
  }

  static String _extensionFor(String fileName) {
    final match = RegExp(r'\.([A-Za-z0-9]+)$').firstMatch(fileName);
    return match?.group(1)?.toLowerCase() ?? 'm4a';
  }
}
