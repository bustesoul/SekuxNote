import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'provider_models.dart';

abstract interface class TaskAudioStore {
  Future<String> save(String taskId, SelectedAudioFile source);
  Future<SelectedAudioFile> read(String path, {required String fileName});
  Future<void> delete(String taskId);
}

/// Keeps the imported source only so a failed task can retry unfinished chunks.
class SandboxedTaskAudioStore implements TaskAudioStore {
  @override
  Future<String> save(String taskId, SelectedAudioFile source) async {
    final directory = await getApplicationSupportDirectory();
    final extension =
        RegExp(r'\.([A-Za-z0-9]+)$').firstMatch(source.name)?.group(1) ?? 'm4a';
    final file = File('${directory.path}/task_audio/$taskId/source.$extension');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(source.bytes, flush: true);
    return file.path;
  }

  @override
  Future<SelectedAudioFile> read(
    String path, {
    required String fileName,
  }) async {
    return SelectedAudioFile(
      name: fileName,
      bytes: await File(path).readAsBytes(),
    );
  }

  @override
  Future<void> delete(String taskId) async {
    final directory = await getApplicationSupportDirectory();
    final taskDirectory = Directory('${directory.path}/task_audio/$taskId');
    if (await taskDirectory.exists()) {
      await taskDirectory.delete(recursive: true);
    }
  }
}

class MemoryTaskAudioStore implements TaskAudioStore {
  final Map<String, SelectedAudioFile> _files = {};

  @override
  Future<SelectedAudioFile> read(
    String path, {
    required String fileName,
  }) async => _files[path]!;

  @override
  Future<String> save(String taskId, SelectedAudioFile source) async {
    final path = 'memory://$taskId';
    _files[path] = source;
    return path;
  }

  @override
  Future<void> delete(String taskId) async {
    _files.remove('memory://$taskId');
  }
}
