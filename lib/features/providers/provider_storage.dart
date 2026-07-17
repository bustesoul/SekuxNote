import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../app/storage/app_data_directory.dart';
import 'provider_models.dart';

abstract interface class ProviderSettingsStore {
  Future<TextProviderSettings> readTextSettings();
  Future<TranscriptionProviderSettings> readTranscriptionSettings();
  Future<void> writeTextSettings(TextProviderSettings settings);
  Future<void> writeTranscriptionSettings(
    TranscriptionProviderSettings settings,
  );
}

/// The persistent provider store is a single sandboxed SQLite database.
///
/// API keys live in [provider_credentials] by the user's explicit local-only
/// storage choice; they are not copied into settings JSON or sent to analytics.
abstract interface class TranscriptionTaskStore {
  Future<void> create(TranscriptionTask task);
  Future<void> update(TranscriptionTask task);
  Future<void> deleteTask(String taskId);
  Future<List<TranscriptionTask>> list();
  Future<void> createChunks(List<TranscriptionTaskChunk> chunks);
  Future<void> updateChunk(TranscriptionTaskChunk chunk);
  Future<List<TranscriptionTaskChunk>> listChunks(String taskId);
}

class SqliteProviderStore
    implements ProviderSettingsStore, CredentialStore, TranscriptionTaskStore {
  SqliteProviderStore._(this._database);

  static const _databaseName = 'sekuxnote.sqlite';
  static const _textKey = 'text';
  static const _transcriptionKey = 'transcription';

  final Database _database;

  static Future<SqliteProviderStore> open() async {
    final directory = await getSekuxNoteDataDirectory();
    return openAtPath('${directory.path}/$_databaseName');
  }

  static Future<SqliteProviderStore> openAtPath(String path) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final database = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 7,
        onCreate: (database, _) async {
          await _createProviderTables(database);
          await _createTaskTable(database);
          await _createTaskChunkTable(database);
        },
        onUpgrade: (database, oldVersion, _) async {
          if (oldVersion < 2) {
            await _createTaskTable(database);
            await _createTaskChunkTable(database);
            return;
          }
          if (oldVersion < 3) {
            await database.execute(
              'ALTER TABLE transcription_tasks ADD COLUMN source_path TEXT',
            );
            await _createTaskChunkTable(database);
          }
          if (oldVersion < 4) {
            await database.execute(
              "ALTER TABLE transcription_tasks ADD COLUMN task_language TEXT NOT NULL DEFAULT 'zh'",
            );
          }
          if (oldVersion < 5) {
            await database.execute(
              "ALTER TABLE transcription_tasks ADD COLUMN provider_id TEXT NOT NULL DEFAULT 'transcription-openai'",
            );
            await database.execute(
              "ALTER TABLE transcription_tasks ADD COLUMN provider_type TEXT NOT NULL DEFAULT 'openAiCompatible'",
            );
            await database.execute(
              'ALTER TABLE transcription_tasks ADD COLUMN segments_json TEXT',
            );
          }
          if (oldVersion < 6) {
            await database.execute(
              'ALTER TABLE transcription_tasks ADD COLUMN diarization_enabled INTEGER NOT NULL DEFAULT 0',
            );
            await database.execute(
              'ALTER TABLE transcription_tasks ADD COLUMN speaker_count INTEGER',
            );
          }
          if (oldVersion < 7) {
            await database.execute(
              'ALTER TABLE transcription_tasks ADD COLUMN remote_task_id TEXT',
            );
          }
        },
      ),
    );
    return SqliteProviderStore._(database);
  }

  @override
  Future<TextProviderSettings> readTextSettings() async {
    final value = await _readConfig(_textKey);
    if (value == null) return TextProviderSettings.defaults();
    if (value.containsKey('providers')) {
      return TextProviderSettings.fromJson(value);
    }
    final legacy = TextProviderConfig.fromJson(value);
    return TextProviderSettings(
      providers: [legacy],
      defaultProviderId: legacy.id,
    );
  }

  Future<TextProviderConfig> readText() async =>
      (await readTextSettings()).defaultProvider;

  @override
  Future<TranscriptionProviderSettings> readTranscriptionSettings() async {
    final value = await _readConfig(_transcriptionKey);
    if (value == null) return TranscriptionProviderSettings.defaults();
    // Version 1–4 stored one provider directly under this same key.
    if (value.containsKey('providers')) {
      return TranscriptionProviderSettings.fromJson(value);
    }
    final legacy = TranscriptionProviderConfig.fromJson(value);
    return TranscriptionProviderSettings(
      providers: [legacy],
      defaultProviderId: legacy.id,
    );
  }

  /// Compatibility bridge for the pre-multi-provider test and callers.
  Future<TranscriptionProviderConfig> readTranscription() async =>
      (await readTranscriptionSettings()).defaultProvider;

  @override
  Future<void> writeTextSettings(TextProviderSettings settings) async {
    await _writeConfig(_textKey, settings.toJson());
  }

  Future<void> writeText(TextProviderConfig config) => writeTextSettings(
    TextProviderSettings(providers: [config], defaultProviderId: config.id),
  );

  @override
  Future<void> writeTranscriptionSettings(
    TranscriptionProviderSettings settings,
  ) async {
    await _writeConfig(_transcriptionKey, settings.toJson());
  }

  Future<void> writeTranscription(TranscriptionProviderConfig config) =>
      writeTranscriptionSettings(
        TranscriptionProviderSettings(
          providers: [config],
          defaultProviderId: config.id,
        ),
      );

  @override
  Future<String?> read(String reference) async {
    final rows = await _database.query(
      'provider_credentials',
      columns: ['secret'],
      where: 'reference = ?',
      whereArgs: [reference],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['secret'] as String;
  }

  @override
  Future<void> write(String reference, String secret) {
    return _database.insert('provider_credentials', {
      'reference': reference,
      'secret': secret,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> delete(String reference) {
    return _database.delete(
      'provider_credentials',
      where: 'reference = ?',
      whereArgs: [reference],
    );
  }

  @override
  Future<void> create(TranscriptionTask task) async {
    await _database.insert('transcription_tasks', _taskValues(task));
  }

  @override
  Future<void> update(TranscriptionTask task) async {
    await _database.update(
      'transcription_tasks',
      _taskValues(task),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _database.transaction((transaction) async {
      await transaction.delete(
        'transcription_task_chunks',
        where: 'task_id = ?',
        whereArgs: [taskId],
      );
      await transaction.delete(
        'transcription_tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );
    });
  }

  @override
  Future<List<TranscriptionTask>> list() async {
    final rows = await _database.query(
      'transcription_tasks',
      orderBy: 'created_at DESC',
    );
    return rows.map(_taskFromRow).toList(growable: false);
  }

  @override
  Future<void> createChunks(List<TranscriptionTaskChunk> chunks) async {
    final batch = _database.batch();
    for (final chunk in chunks) {
      batch.insert('transcription_task_chunks', _chunkValues(chunk));
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateChunk(TranscriptionTaskChunk chunk) async {
    await _database.update(
      'transcription_task_chunks',
      _chunkValues(chunk),
      where: 'task_id = ? AND chunk_index = ?',
      whereArgs: [chunk.taskId, chunk.index],
    );
  }

  @override
  Future<List<TranscriptionTaskChunk>> listChunks(String taskId) async {
    final rows = await _database.query(
      'transcription_task_chunks',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'chunk_index ASC',
    );
    return rows.map(_chunkFromRow).toList(growable: false);
  }

  Future<void> close() => _database.close();

  Future<Map<String, Object?>?> _readConfig(String kind) async {
    final rows = await _database.query(
      'provider_settings',
      columns: ['config_json'],
      where: 'kind = ?',
      whereArgs: [kind],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Map<String, Object?>.from(
      jsonDecode(rows.single['config_json']! as String) as Map,
    );
  }

  Future<void> _writeConfig(String kind, Map<String, Object?> config) {
    return _database.insert('provider_settings', {
      'kind': kind,
      'config_json': jsonEncode(config),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> _createProviderTables(Database database) async {
    await database.execute(
      'CREATE TABLE provider_settings ('
      'kind TEXT PRIMARY KEY, config_json TEXT NOT NULL)',
    );
    await database.execute(
      'CREATE TABLE provider_credentials ('
      'reference TEXT PRIMARY KEY, secret TEXT NOT NULL)',
    );
  }

  static Future<void> _createTaskTable(Database database) {
    return database.execute(
      'CREATE TABLE transcription_tasks ('
      'id TEXT PRIMARY KEY, '
      'file_name TEXT NOT NULL, '
      "provider_id TEXT NOT NULL DEFAULT 'transcription-openai', "
      "provider_type TEXT NOT NULL DEFAULT 'openAiCompatible', "
      'provider_name TEXT NOT NULL, '
      'model TEXT NOT NULL, '
      'status TEXT NOT NULL, '
      'created_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL, '
      'chunks_total INTEGER NOT NULL, '
      'chunks_completed INTEGER NOT NULL, '
      "task_language TEXT NOT NULL DEFAULT 'zh', "
      'diarization_enabled INTEGER NOT NULL DEFAULT 0, '
      'speaker_count INTEGER, '
      'source_path TEXT, '
      'remote_task_id TEXT, '
      'transcript TEXT, '
      'segments_json TEXT, '
      'error_message TEXT)',
    );
  }

  static Future<void> _createTaskChunkTable(Database database) {
    return database.execute(
      'CREATE TABLE transcription_task_chunks ('
      'task_id TEXT NOT NULL, '
      'chunk_index INTEGER NOT NULL, '
      'status TEXT NOT NULL, '
      'attempts INTEGER NOT NULL, '
      'text TEXT, '
      'error_message TEXT, '
      'PRIMARY KEY (task_id, chunk_index))',
    );
  }

  Map<String, Object?> _taskValues(TranscriptionTask task) => {
    'id': task.id,
    'file_name': task.fileName,
    'provider_id': task.providerId,
    'provider_type': task.providerType.name,
    'provider_name': task.providerName,
    'model': task.model,
    'status': task.status.name,
    'created_at': task.createdAt.millisecondsSinceEpoch,
    'updated_at': task.updatedAt.millisecondsSinceEpoch,
    'chunks_total': task.chunksTotal,
    'chunks_completed': task.chunksCompleted,
    'task_language': task.language,
    'diarization_enabled': task.diarizationEnabled ? 1 : 0,
    'speaker_count': task.speakerCount,
    'source_path': task.sourcePath,
    'remote_task_id': task.remoteTaskId,
    'transcript': task.transcript,
    'segments_json': jsonEncode(
      task.segments.map((segment) => segment.toJson()).toList(),
    ),
    'error_message': task.errorMessage,
  };

  TranscriptionTask _taskFromRow(Map<String, Object?> row) {
    final statusName = row['status']! as String;
    final status = TranscriptionTaskStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => TranscriptionTaskStatus.failed,
    );
    return TranscriptionTask(
      id: row['id']! as String,
      fileName: row['file_name']! as String,
      providerId: row['provider_id'] as String? ?? 'transcription-openai',
      providerType: TranscriptionProviderType.values.firstWhere(
        (type) => type.name == row['provider_type'],
        orElse: () => TranscriptionProviderType.openAiCompatible,
      ),
      providerName: row['provider_name']! as String,
      model: row['model']! as String,
      status: status,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
      chunksTotal: row['chunks_total']! as int,
      chunksCompleted: row['chunks_completed']! as int,
      language: row['task_language'] as String? ?? 'zh',
      diarizationEnabled: (row['diarization_enabled'] as int? ?? 0) == 1,
      speakerCount: row['speaker_count'] as int?,
      sourcePath: row['source_path'] as String?,
      remoteTaskId: row['remote_task_id'] as String?,
      transcript: row['transcript'] as String?,
      segments: _segmentsFromJson(row['segments_json'] as String?),
      errorMessage: row['error_message'] as String?,
    );
  }

  List<TranscriptionSegment> _segmentsFromJson(String? value) {
    if (value == null || value.isEmpty) return const [];
    try {
      return (jsonDecode(value) as List)
          .whereType<Map>()
          .map(
            (item) =>
                TranscriptionSegment.fromJson(Map<String, Object?>.from(item)),
          )
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Map<String, Object?> _chunkValues(TranscriptionTaskChunk chunk) => {
    'task_id': chunk.taskId,
    'chunk_index': chunk.index,
    'status': chunk.status.name,
    'attempts': chunk.attempts,
    'text': chunk.text,
    'error_message': chunk.errorMessage,
  };

  TranscriptionTaskChunk _chunkFromRow(Map<String, Object?> row) {
    final statusName = row['status']! as String;
    return TranscriptionTaskChunk(
      taskId: row['task_id']! as String,
      index: row['chunk_index']! as int,
      status: TranscriptionTaskChunkStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => TranscriptionTaskChunkStatus.failed,
      ),
      attempts: row['attempts']! as int,
      text: row['text'] as String?,
      errorMessage: row['error_message'] as String?,
    );
  }
}

class MemoryProviderSettingsStore implements ProviderSettingsStore {
  TextProviderSettings _text = TextProviderSettings.defaults();
  TranscriptionProviderSettings _transcription =
      TranscriptionProviderSettings.defaults();

  @override
  Future<TextProviderSettings> readTextSettings() async => _text;

  Future<TextProviderConfig> readText() async => _text.defaultProvider;

  @override
  Future<TranscriptionProviderSettings> readTranscriptionSettings() async =>
      _transcription;

  @override
  Future<void> writeTextSettings(TextProviderSettings settings) async {
    _text = settings;
  }

  Future<void> writeText(TextProviderConfig config) async {
    _text = TextProviderSettings(
      providers: [config],
      defaultProviderId: config.id,
    );
  }

  @override
  Future<void> writeTranscriptionSettings(
    TranscriptionProviderSettings settings,
  ) async {
    _transcription = settings;
  }
}

abstract interface class CredentialStore {
  Future<String?> read(String reference);
  Future<void> write(String reference, String secret);
  Future<void> delete(String reference);
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

class MemoryTranscriptionTaskStore implements TranscriptionTaskStore {
  final Map<String, TranscriptionTask> _tasks = {};
  final Map<String, Map<int, TranscriptionTaskChunk>> _chunks = {};

  @override
  Future<void> create(TranscriptionTask task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<List<TranscriptionTask>> list() async {
    final tasks = _tasks.values.toList()
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return tasks;
  }

  @override
  Future<void> update(TranscriptionTask task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.remove(taskId);
    _chunks.remove(taskId);
  }

  @override
  Future<void> createChunks(List<TranscriptionTaskChunk> chunks) async {
    for (final chunk in chunks) {
      _chunks.putIfAbsent(chunk.taskId, () => {})[chunk.index] = chunk;
    }
  }

  @override
  Future<List<TranscriptionTaskChunk>> listChunks(String taskId) async {
    final chunks = _chunks[taskId]?.values.toList() ?? [];
    chunks.sort((first, second) => first.index.compareTo(second.index));
    return chunks;
  }

  @override
  Future<void> updateChunk(TranscriptionTaskChunk chunk) async {
    _chunks.putIfAbsent(chunk.taskId, () => {})[chunk.index] = chunk;
  }
}
