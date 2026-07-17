import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../app/storage/app_data_directory.dart';
import 'assistant_models.dart';

abstract interface class AssistantStore {
  Future<List<AssistantThread>> listThreads();
  Future<void> saveThread(AssistantThread thread);
  Future<List<AssistantMessage>> listMessages(String threadId);
  Future<void> saveMessage(AssistantMessage message);
  Future<List<NoteArtifact>> listArtifacts(String sourceId);
  Future<void> saveArtifact(NoteArtifact artifact);
}

class SqliteAssistantStore implements AssistantStore {
  SqliteAssistantStore._(this._database);

  final Database _database;

  static Future<SqliteAssistantStore> open() async {
    final directory = await getSekuxNoteDataDirectory();
    return openAtPath('${directory.path}/sekuxnote.sqlite');
  }

  static Future<SqliteAssistantStore> openAtPath(String path) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final database = await databaseFactory.openDatabase(path);
    await _createTables(database);
    return SqliteAssistantStore._(database);
  }

  static Future<void> _createTables(Database database) async {
    await database.execute(
      'CREATE TABLE IF NOT EXISTS assistant_threads ('
      'id TEXT PRIMARY KEY, title TEXT NOT NULL, created_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL)',
    );
    await database.execute(
      'CREATE TABLE IF NOT EXISTS assistant_messages ('
      'id TEXT PRIMARY KEY, thread_id TEXT NOT NULL, role TEXT NOT NULL, '
      'content TEXT NOT NULL, created_at INTEGER NOT NULL, provider_id TEXT, '
      'model_id TEXT, contexts_json TEXT NOT NULL, is_streaming INTEGER NOT NULL, '
      'error_message TEXT)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS assistant_messages_thread_idx '
      'ON assistant_messages(thread_id, created_at)',
    );
    await database.execute(
      'CREATE TABLE IF NOT EXISTS note_artifacts ('
      'id TEXT PRIMARY KEY, source_id TEXT NOT NULL, source_title TEXT NOT NULL, '
      'source_revision_id TEXT NOT NULL, source_content_hash TEXT NOT NULL, '
      'provider_id TEXT NOT NULL, model_id TEXT NOT NULL, status TEXT NOT NULL, '
      'markdown TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, '
      'error_message TEXT)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS note_artifacts_source_idx '
      'ON note_artifacts(source_id, created_at DESC)',
    );
  }

  @override
  Future<List<AssistantThread>> listThreads() async {
    final rows = await _database.query(
      'assistant_threads',
      orderBy: 'updated_at DESC',
    );
    return rows
        .map(
          (row) => AssistantThread(
            id: row['id']! as String,
            title: row['title']! as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row['created_at']! as int,
            ),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              row['updated_at']! as int,
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveThread(AssistantThread thread) =>
      _database.insert('assistant_threads', {
        'id': thread.id,
        'title': thread.title,
        'created_at': thread.createdAt.millisecondsSinceEpoch,
        'updated_at': thread.updatedAt.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<List<AssistantMessage>> listMessages(String threadId) async {
    final rows = await _database.query(
      'assistant_messages',
      where: 'thread_id = ?',
      whereArgs: [threadId],
      orderBy: 'created_at ASC',
    );
    return rows.map(_messageFromRow).toList(growable: false);
  }

  AssistantMessage _messageFromRow(Map<String, Object?> row) {
    final values = jsonDecode(row['contexts_json']! as String) as List;
    return AssistantMessage(
      id: row['id']! as String,
      threadId: row['thread_id']! as String,
      role: row['role']! as String,
      content: row['content']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      providerId: row['provider_id'] as String?,
      modelId: row['model_id'] as String?,
      contexts: values
          .whereType<Map>()
          .map(
            (value) => AssistantContextReference.fromJson(
              Map<String, Object?>.from(value),
            ),
          )
          .toList(growable: false),
      isStreaming: (row['is_streaming']! as int) == 1,
      errorMessage: row['error_message'] as String?,
    );
  }

  @override
  Future<void> saveMessage(AssistantMessage message) =>
      _database.insert('assistant_messages', {
        'id': message.id,
        'thread_id': message.threadId,
        'role': message.role,
        'content': message.content,
        'created_at': message.createdAt.millisecondsSinceEpoch,
        'provider_id': message.providerId,
        'model_id': message.modelId,
        'contexts_json': jsonEncode(
          message.contexts.map((value) => value.toJson()).toList(),
        ),
        'is_streaming': message.isStreaming ? 1 : 0,
        'error_message': message.errorMessage,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<List<NoteArtifact>> listArtifacts(String sourceId) async {
    final rows = await _database.query(
      'note_artifacts',
      where: 'source_id = ?',
      whereArgs: [sourceId],
      orderBy: 'created_at DESC',
    );
    return rows
        .map(
          (row) => NoteArtifact(
            id: row['id']! as String,
            sourceId: row['source_id']! as String,
            sourceTitle: row['source_title']! as String,
            sourceRevisionId: row['source_revision_id']! as String,
            sourceContentHash: row['source_content_hash']! as String,
            providerId: row['provider_id']! as String,
            modelId: row['model_id']! as String,
            status: NoteArtifactStatus.values.firstWhere(
              (value) => value.name == row['status'],
              orElse: () => NoteArtifactStatus.failed,
            ),
            markdown: row['markdown']! as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row['created_at']! as int,
            ),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              row['updated_at']! as int,
            ),
            errorMessage: row['error_message'] as String?,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveArtifact(NoteArtifact artifact) =>
      _database.insert('note_artifacts', {
        'id': artifact.id,
        'source_id': artifact.sourceId,
        'source_title': artifact.sourceTitle,
        'source_revision_id': artifact.sourceRevisionId,
        'source_content_hash': artifact.sourceContentHash,
        'provider_id': artifact.providerId,
        'model_id': artifact.modelId,
        'status': artifact.status.name,
        'markdown': artifact.markdown,
        'created_at': artifact.createdAt.millisecondsSinceEpoch,
        'updated_at': artifact.updatedAt.millisecondsSinceEpoch,
        'error_message': artifact.errorMessage,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> close() => _database.close();
}

class MemoryAssistantStore implements AssistantStore {
  final Map<String, AssistantThread> _threads = {};
  final Map<String, AssistantMessage> _messages = {};
  final Map<String, NoteArtifact> _artifacts = {};

  @override
  Future<List<AssistantThread>> listThreads() async {
    final values = _threads.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
  }

  @override
  Future<void> saveThread(AssistantThread thread) async {
    _threads[thread.id] = thread;
  }

  @override
  Future<List<AssistantMessage>> listMessages(String threadId) async {
    final values =
        _messages.values.where((value) => value.threadId == threadId).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return values;
  }

  @override
  Future<void> saveMessage(AssistantMessage message) async {
    _messages[message.id] = message;
  }

  @override
  Future<List<NoteArtifact>> listArtifacts(String sourceId) async {
    final values =
        _artifacts.values.where((value) => value.sourceId == sourceId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  @override
  Future<void> saveArtifact(NoteArtifact artifact) async {
    _artifacts[artifact.id] = artifact;
  }
}
