import 'dart:async';

import 'package:flutter/material.dart';

import '../../providers/provider_controller.dart';
import '../../providers/provider_models.dart';
import '../../recording/recording_session_controller.dart';
import '../assistant_controller.dart';
import '../assistant_models.dart';
import '../record_ai_source_adapter.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({
    super.key,
    required this.controller,
    required this.providerController,
    required this.recordingController,
  });

  final AssistantController controller;
  final ProviderController providerController;
  final RecordingSessionController recordingController;

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<RecordAiSource> _selectedSources = [];
  String? _providerId;
  String? _modelId;
  bool _mentionPickerVisible = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _inputController
      ..removeListener(_onInputChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final text = _inputController.text;
    if (!text.endsWith('@') || _mentionPickerVisible) return;
    _mentionPickerVisible = true;
    unawaited(_pickSource().whenComplete(() => _mentionPickerVisible = false));
  }

  Future<List<RecordAiSource>> _sources() async {
    final tasks = await widget.providerController.listTranscriptionTasks();
    return [
      ...tasks.map(recordAiSourceFromTask).whereType<RecordAiSource>(),
      ...widget.recordingController.recordings
          .map(recordAiSourceFromRecording)
          .whereType<RecordAiSource>(),
    ];
  }

  Future<void> _pickSource() async {
    final sources = await _sources();
    if (!mounted) return;
    final source = await showModalBottomSheet<RecordAiSource>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RecordSourcePicker(sources: sources),
    );
    if (source == null || !mounted) return;
    if (_selectedSources.every((value) => value.sourceId != source.sourceId)) {
      setState(() => _selectedSources.add(source));
    }
    if (_inputController.text.endsWith('@')) {
      _inputController.text = _inputController.text.substring(
        0,
        _inputController.text.length - 1,
      );
      _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length,
      );
    }
  }

  Future<void> _send() async {
    final text = _inputController.text;
    if (text.trim().isEmpty && _selectedSources.isEmpty) return;
    final sources = List<RecordAiSource>.of(_selectedSources);
    _inputController.clear();
    setState(_selectedSources.clear);
    await widget.controller.send(
      content: text,
      sources: sources,
      providerId: _providerId,
      modelId: _modelId,
    );
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.controller,
      widget.providerController,
    ]),
    builder: (context, _) {
      _scrollToEnd();
      final providers = widget.providerController.textSettings.providers
          .where((value) => value.enabled)
          .toList(growable: false);
      final selectedProvider = widget.providerController.textProviderById(
        _providerId ?? widget.providerController.textSettings.defaultProviderId,
      );
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.controller.activeThread?.title ?? 'AI 助手'),
          actions: [
            PopupMenuButton<String>(
              key: const Key('assistant_history'),
              tooltip: '历史对话',
              onSelected: widget.controller.selectThread,
              itemBuilder: (context) => widget.controller.threads
                  .map(
                    (thread) => PopupMenuItem(
                      value: thread.id,
                      child: Text(thread.title),
                    ),
                  )
                  .toList(growable: false),
              icon: const Icon(Icons.history),
            ),
            IconButton(
              key: const Key('assistant_new_thread'),
              tooltip: '新对话',
              onPressed: widget.controller.generating
                  ? null
                  : widget.controller.newThread,
              icon: const Icon(Icons.add_comment_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: widget.controller.messages.isEmpty
                    ? const _AssistantEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: widget.controller.messages.length,
                        itemBuilder: (context, index) => _MessageBubble(
                          message: widget.controller.messages[index],
                        ),
                      ),
              ),
              Material(
                elevation: 8,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedSources.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _selectedSources
                                  .map(
                                    (source) => InputChip(
                                      avatar: const Icon(
                                        Icons.description_outlined,
                                        size: 16,
                                      ),
                                      label: Text(
                                        '${source.title} · ${source.revisionLabel}',
                                      ),
                                      onDeleted: () => setState(
                                        () => _selectedSources.remove(source),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                key: const Key('assistant_provider'),
                                initialValue: selectedProvider?.id,
                                isDense: true,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: '供应商',
                                ),
                                items: providers
                                    .map(
                                      (provider) => DropdownMenuItem(
                                        value: provider.id,
                                        child: Text(provider.name),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (value) => setState(() {
                                  _providerId = value;
                                  _modelId = null;
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                key: ValueKey(
                                  'assistant_model_${selectedProvider?.id}',
                                ),
                                initialValue: selectedProvider?.model,
                                isDense: true,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: '模型',
                                ),
                                items: _models(selectedProvider)
                                    .map(
                                      (model) => DropdownMenuItem(
                                        value: model,
                                        child: Text(model),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (value) => _modelId = value,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              key: const Key('assistant_attach_record'),
                              tooltip: '@记录',
                              onPressed: _pickSource,
                              icon: const Icon(Icons.alternate_email),
                            ),
                            Expanded(
                              child: TextField(
                                key: const Key('assistant_input'),
                                controller: _inputController,
                                minLines: 1,
                                maxLines: 6,
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                  hintText: '输入问题；键入 @ 可引用指定记录',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (widget.controller.generating)
                              IconButton.filledTonal(
                                key: const Key('assistant_cancel'),
                                onPressed: widget.controller.cancelGeneration,
                                icon: const Icon(Icons.stop),
                              )
                            else
                              IconButton.filled(
                                key: const Key('assistant_send'),
                                onPressed: providers.isEmpty ? null : _send,
                                icon: const Icon(Icons.arrow_upward),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  List<String> _models(TextProviderConfig? provider) {
    if (provider == null) return const [];
    return <String>{provider.model, ...provider.models}.toList(growable: false);
  }
}

class _AssistantEmptyState extends StatelessWidget {
  const _AssistantEmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 52),
          SizedBox(height: 16),
          Text('和你的记录一起思考', style: TextStyle(fontSize: 20)),
          SizedBox(height: 8),
          Text('直接提问，或输入 @ 选择录音转写和会议记录作为上下文。'),
        ],
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.role == 'user';
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: user
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.contexts.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: message.contexts
                    .map(
                      (context) => Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          '@${context.title} · ${context.revisionLabel}',
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            if (message.content.isNotEmpty)
              SelectionArea(child: Text(message.content)),
            if (message.isStreaming) ...[
              const SizedBox(height: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
            if (message.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                message.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (!user && message.providerId != null) ...[
              const SizedBox(height: 8),
              Text(
                '${message.providerId} · ${message.modelId}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecordSourcePicker extends StatefulWidget {
  const _RecordSourcePicker({required this.sources});

  final List<RecordAiSource> sources;

  @override
  State<_RecordSourcePicker> createState() => _RecordSourcePickerState();
}

class _RecordSourcePickerState extends State<_RecordSourcePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.sources
        .where(
          (source) => source.title.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList(growable: false);
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (context, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '@指定记录',
                  hintText: '搜索录音或会议记录',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('暂无可引用的转写文字'))
                  : ListView.builder(
                      controller: controller,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final source = filtered[index];
                        return ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(source.title),
                          subtitle: Text(
                            '${source.revisionLabel} · 约 ${source.characterCount} 字',
                          ),
                          onTap: () => Navigator.pop(context, source),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
