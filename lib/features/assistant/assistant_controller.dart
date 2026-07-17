import 'dart:async';

import 'package:flutter/foundation.dart';

import '../providers/provider_controller.dart';
import '../providers/provider_models.dart';
import 'assistant_models.dart';
import 'assistant_storage.dart';

class AssistantController extends ChangeNotifier {
  AssistantController({
    required AssistantStore store,
    required ProviderController providerController,
  }) : _store = store,
       _providerController = providerController;

  static Future<AssistantController> createPersistent(
    ProviderController providerController,
  ) async {
    final controller = AssistantController(
      store: await SqliteAssistantStore.open(),
      providerController: providerController,
    );
    await controller.load();
    return controller;
  }

  factory AssistantController.inMemory(ProviderController providerController) =>
      AssistantController(
        store: MemoryAssistantStore(),
        providerController: providerController,
      );

  final AssistantStore _store;
  final ProviderController _providerController;
  final List<AssistantThread> _threads = [];
  final List<AssistantMessage> _messages = [];
  AssistantThread? _activeThread;
  int _generationToken = 0;
  bool _generating = false;

  List<AssistantThread> get threads => List.unmodifiable(_threads);
  List<AssistantMessage> get messages => List.unmodifiable(_messages);
  AssistantThread? get activeThread => _activeThread;
  bool get generating => _generating;

  Future<void> load() async {
    _threads
      ..clear()
      ..addAll(await _store.listThreads());
    if (_threads.isEmpty) {
      await newThread();
      return;
    }
    await selectThread(_threads.first.id);
  }

  Future<void> newThread() async {
    final now = DateTime.now();
    final thread = AssistantThread(
      id: 'thread-${now.microsecondsSinceEpoch}',
      title: '新对话',
      createdAt: now,
      updatedAt: now,
    );
    await _store.saveThread(thread);
    _threads.insert(0, thread);
    _activeThread = thread;
    _messages.clear();
    notifyListeners();
  }

  Future<void> selectThread(String id) async {
    final thread = _threads.where((value) => value.id == id).firstOrNull;
    if (thread == null) return;
    cancelGeneration();
    _activeThread = thread;
    _messages
      ..clear()
      ..addAll(await _store.listMessages(id));
    for (var index = 0; index < _messages.length; index++) {
      final message = _messages[index];
      if (!message.isStreaming) continue;
      final interrupted = message.copyWith(
        isStreaming: false,
        errorMessage: '上次生成被应用退出中断',
      );
      _messages[index] = interrupted;
      await _store.saveMessage(interrupted);
    }
    notifyListeners();
  }

  Future<void> send({
    required String content,
    required List<RecordAiSource> sources,
    String? providerId,
    String? modelId,
  }) async {
    final text = content.trim();
    if ((text.isEmpty && sources.isEmpty) || _generating) return;
    final thread = _activeThread;
    if (thread == null) return;
    final config = _providerController.textProviderById(
      providerId ?? _providerController.textSettings.defaultProviderId,
    );
    if (config == null) throw StateError('providerMissing');
    final chosenModel = modelId?.trim().isNotEmpty == true
        ? modelId!.trim()
        : config.model;
    final now = DateTime.now();
    final user = AssistantMessage(
      id: 'message-${now.microsecondsSinceEpoch}-user',
      threadId: thread.id,
      role: 'user',
      content: text,
      createdAt: now,
      contexts: sources
          .map(AssistantContextReference.fromSource)
          .toList(growable: false),
    );
    var assistant = AssistantMessage(
      id: 'message-${now.microsecondsSinceEpoch}-assistant',
      threadId: thread.id,
      role: 'assistant',
      content: '',
      createdAt: now.add(const Duration(microseconds: 1)),
      providerId: config.id,
      modelId: chosenModel,
      isStreaming: true,
    );
    _messages.addAll([user, assistant]);
    await _store.saveMessage(user);
    await _store.saveMessage(assistant);
    await _touchThread(text.isEmpty ? sources.first.title : text);
    _generating = true;
    final token = ++_generationToken;
    notifyListeners();
    try {
      await for (final chunk in _providerController.streamText(
        providerId: config.id,
        model: chosenModel,
        messages: _requestMessages(),
      )) {
        if (token != _generationToken) break;
        if (chunk.text.isNotEmpty) {
          assistant = assistant.copyWith(
            content: assistant.content + chunk.text,
            modelId: chunk.model,
          );
          _replaceMessage(assistant);
          notifyListeners();
        }
      }
      if (token != _generationToken) {
        assistant = assistant.copyWith(
          isStreaming: false,
          errorMessage: '已取消生成',
        );
      } else if (assistant.content.trim().isEmpty) {
        assistant = assistant.copyWith(
          isStreaming: false,
          errorMessage: '供应商返回了空内容',
        );
      } else {
        assistant = assistant.copyWith(isStreaming: false, clearError: true);
      }
    } catch (error) {
      assistant = assistant.copyWith(
        isStreaming: false,
        errorMessage: error.toString(),
      );
    } finally {
      _replaceMessage(assistant);
      await _store.saveMessage(assistant);
      if (token == _generationToken) _generating = false;
      notifyListeners();
    }
  }

  List<TextChatMessage> _requestMessages() {
    const maxContextCharacters = 60000;
    var remaining = maxContextCharacters;
    final selected = <TextChatMessage>[];
    for (final message in _messages.reversed) {
      if (message.role == 'assistant' && message.content.isEmpty) continue;
      var content = message.content;
      if (message.contexts.isNotEmpty) {
        final contextBuffer = StringBuffer(
          '以下是用户明确选择的 SekuxNote 记录上下文。只依据上下文回答记录事实；'
          '没有依据时明确说明。\n',
        );
        for (final context in message.contexts) {
          contextBuffer
            ..writeln(
              '\n<record title="${context.title}" revision="${context.sourceRevisionId}">',
            )
            ..writeln(context.snapshotText)
            ..writeln('</record>');
        }
        content =
            '$contextBuffer\n用户问题：${content.isEmpty ? '请分析以上记录。' : content}';
      }
      if (content.length > remaining) {
        content = content.substring(content.length - remaining);
      }
      selected.add(TextChatMessage(role: message.role, content: content));
      remaining -= content.length;
      if (remaining <= 0) break;
    }
    return selected.reversed.toList(growable: false);
  }

  Future<void> _touchThread(String seed) async {
    final thread = _activeThread!;
    final normalized = seed.replaceAll(RegExp(r'\s+'), ' ');
    final title = thread.title == '新对话'
        ? normalized.substring(0, normalized.length.clamp(0, 28))
        : thread.title;
    final updated = thread.copyWith(title: title, updatedAt: DateTime.now());
    _activeThread = updated;
    final index = _threads.indexWhere((value) => value.id == updated.id);
    if (index >= 0) _threads[index] = updated;
    _threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _store.saveThread(updated);
  }

  void _replaceMessage(AssistantMessage message) {
    final index = _messages.indexWhere((value) => value.id == message.id);
    if (index >= 0) _messages[index] = message;
  }

  void cancelGeneration() {
    if (!_generating) return;
    _generationToken++;
    _generating = false;
    notifyListeners();
  }

  Future<List<NoteArtifact>> listArtifacts(RecordAiSource source) async {
    final values = await _store.listArtifacts(source.sourceId);
    return values
        .map(
          (artifact) =>
              artifact.isStaleFor(source) &&
                  artifact.status == NoteArtifactStatus.ready
              ? artifact.copyWith(status: NoteArtifactStatus.stale)
              : artifact,
        )
        .toList(growable: false);
  }

  Future<NoteArtifact> generateSummary(
    RecordAiSource source, {
    String? providerId,
    String? modelId,
  }) async {
    final config = _providerController.textProviderById(
      providerId ?? _providerController.textSettings.defaultProviderId,
    );
    if (config == null) throw StateError('providerMissing');
    final chosenModel = modelId?.trim().isNotEmpty == true
        ? modelId!.trim()
        : config.model;
    final now = DateTime.now();
    var artifact = NoteArtifact(
      id: 'note-${now.microsecondsSinceEpoch}',
      sourceId: source.sourceId,
      sourceTitle: source.title,
      sourceRevisionId: source.sourceRevisionId,
      sourceContentHash: source.contentHash,
      providerId: config.id,
      modelId: chosenModel,
      status: NoteArtifactStatus.generating,
      markdown: '',
      createdAt: now,
      updatedAt: now,
    );
    await _store.saveArtifact(artifact);
    final token = ++_generationToken;
    _generating = true;
    notifyListeners();
    try {
      final sourceText = source.text.length > 80000
          ? source.text.substring(0, 80000)
          : source.text;
      await for (final chunk in _providerController.streamText(
        providerId: config.id,
        model: chosenModel,
        messages: [
          const TextChatMessage(
            role: 'system',
            content:
                '你是 SekuxNote 会议纪要助手。输出 Markdown，包含摘要、关键议题、决定、行动项和待确认事项。不得补造原文没有的事实。',
          ),
          TextChatMessage(
            role: 'user',
            content:
                '记录标题：${source.title}\n来源版本：${source.revisionLabel}\n\n$sourceText',
          ),
        ],
      )) {
        if (token != _generationToken) break;
        if (chunk.text.isNotEmpty) {
          artifact = artifact.copyWith(
            markdown: artifact.markdown + chunk.text,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
      }
      artifact = token != _generationToken
          ? artifact.copyWith(
              status: NoteArtifactStatus.failed,
              updatedAt: DateTime.now(),
              errorMessage: '已取消生成',
            )
          : artifact.markdown.trim().isEmpty
          ? artifact.copyWith(
              status: NoteArtifactStatus.failed,
              updatedAt: DateTime.now(),
              errorMessage: '供应商返回了空内容',
            )
          : artifact.copyWith(
              status: NoteArtifactStatus.ready,
              updatedAt: DateTime.now(),
              clearError: true,
            );
    } catch (error) {
      artifact = artifact.copyWith(
        status: NoteArtifactStatus.failed,
        updatedAt: DateTime.now(),
        errorMessage: error.toString(),
      );
    } finally {
      await _store.saveArtifact(artifact);
      if (token == _generationToken) _generating = false;
      notifyListeners();
    }
    return artifact;
  }

  @override
  void dispose() {
    _generationToken++;
    final store = _store;
    if (store is SqliteAssistantStore) unawaited(store.close());
    super.dispose();
  }
}
