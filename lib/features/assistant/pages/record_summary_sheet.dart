import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../providers/provider_controller.dart';
import '../../providers/provider_models.dart';
import '../assistant_controller.dart';
import '../assistant_models.dart';

class RecordSummarySheet extends StatefulWidget {
  const RecordSummarySheet({
    super.key,
    required this.source,
    required this.controller,
    required this.providerController,
  });

  final RecordAiSource source;
  final AssistantController controller;
  final ProviderController providerController;

  @override
  State<RecordSummarySheet> createState() => _RecordSummarySheetState();
}

class _RecordSummarySheetState extends State<RecordSummarySheet> {
  String? _providerId;
  String? _modelId;
  late Future<List<NoteArtifact>> _artifacts;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _artifacts = widget.controller.listArtifacts(widget.source);
  }

  Future<void> _generate() async {
    setState(() {});
    await widget.controller.generateSummary(
      widget.source,
      providerId: _providerId,
      modelId: _modelId,
    );
    if (!mounted) return;
    setState(_refresh);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.controller,
      widget.providerController,
    ]),
    builder: (context, _) {
      final settings = widget.providerController.textSettings;
      final provider = widget.providerController.textProviderById(
        _providerId ?? settings.defaultProviderId,
      );
      return FractionallySizedBox(
        heightFactor: 0.96,
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('record_summary_back'),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'AI 总结 · ${widget.source.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      '${widget.source.revisionLabel} · 约 ${widget.source.characterCount} 字',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: provider?.id,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: '文字 AI 供应商',
                            ),
                            items: settings.providers
                                .where((value) => value.enabled)
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value.id,
                                    child: Text(value.name),
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
                            key: ValueKey('summary_model_${provider?.id}'),
                            initialValue: provider?.model,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: '模型'),
                            items: _models(provider)
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) => _modelId = value,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.controller.generating)
                      OutlinedButton.icon(
                        onPressed: widget.controller.cancelGeneration,
                        icon: const Icon(Icons.stop),
                        label: const Text('取消生成'),
                      )
                    else
                      FilledButton.icon(
                        key: const Key('record_generate_summary'),
                        onPressed: provider == null ? null : _generate,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('生成新总结'),
                      ),
                    const SizedBox(height: 20),
                    FutureBuilder<List<NoteArtifact>>(
                      future: _artifacts,
                      builder: (context, snapshot) {
                        final artifacts =
                            snapshot.data ?? const <NoteArtifact>[];
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (artifacts.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('尚未生成总结。生成后将持久保存在本机。'),
                          );
                        }
                        return Column(
                          children: artifacts
                              .map(
                                (artifact) => _ArtifactCard(artifact: artifact),
                              )
                              .toList(growable: false),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  List<String> _models(TextProviderConfig? provider) => provider == null
      ? const []
      : <String>{provider.model, ...provider.models}.toList(growable: false);
}

bool isMarkdownSummary(String content) {
  final value = content.trim();
  if (value.isEmpty) return false;
  final blockPatterns = <RegExp>[
    RegExp(r'^#{1,6}\s+\S', multiLine: true),
    RegExp(r'^\s*[-*+]\s+\S', multiLine: true),
    RegExp(r'^\s*\d+[.)]\s+\S', multiLine: true),
    RegExp(r'^>\s+\S', multiLine: true),
    RegExp(r'^```[^\n]*$', multiLine: true),
    RegExp(r'^\s*---+\s*$', multiLine: true),
    RegExp(r'^\s*\|?.+\|.+\|?\s*\n\s*\|?\s*:?-{3,}', multiLine: true),
  ];
  if (blockPatterns.any((pattern) => pattern.hasMatch(value))) return true;
  return RegExp(r'(\*\*|__)[^\n]+(\*\*|__)').hasMatch(value) ||
      RegExp(r'`[^`\n]+`').hasMatch(value) ||
      RegExp(r'!?\[[^\]]+\]\([^)]+\)').hasMatch(value);
}

enum _ArtifactDisplayMode { source, rendered }

class _ArtifactCard extends StatefulWidget {
  const _ArtifactCard({required this.artifact});

  final NoteArtifact artifact;

  @override
  State<_ArtifactCard> createState() => _ArtifactCardState();
}

class _ArtifactCardState extends State<_ArtifactCard> {
  late _ArtifactDisplayMode _displayMode;

  NoteArtifact get artifact => widget.artifact;
  bool get _isMarkdown => isMarkdownSummary(artifact.markdown);

  @override
  void initState() {
    super.initState();
    _displayMode = isMarkdownSummary(artifact.markdown)
        ? _ArtifactDisplayMode.rendered
        : _ArtifactDisplayMode.source;
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${artifact.providerId} · ${artifact.modelId}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              _StatusChip(status: artifact.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '来源版本：${artifact.sourceRevisionId}\n生成时间：${artifact.createdAt.toLocal()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (artifact.markdown.isNotEmpty) ...[
            const Divider(height: 24),
            if (_isMarkdown)
              Align(
                alignment: Alignment.centerRight,
                child: SegmentedButton<_ArtifactDisplayMode>(
                  key: Key('summary_view_toggle_${artifact.id}'),
                  segments: const [
                    ButtonSegment(
                      value: _ArtifactDisplayMode.source,
                      label: Text('原文'),
                      icon: Icon(Icons.code, size: 16),
                    ),
                    ButtonSegment(
                      value: _ArtifactDisplayMode.rendered,
                      label: Text('渲染'),
                      icon: Icon(Icons.article_outlined, size: 16),
                    ),
                  ],
                  selected: {_displayMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) =>
                      setState(() => _displayMode = value.first),
                ),
              ),
            if (_isMarkdown) const SizedBox(height: 12),
            if (_isMarkdown && _displayMode == _ArtifactDisplayMode.rendered)
              MarkdownBody(
                key: Key('summary_markdown_${artifact.id}'),
                data: artifact.markdown,
                selectable: true,
              )
            else
              SelectionArea(
                key: Key('summary_source_${artifact.id}'),
                child: Text(artifact.markdown),
              ),
          ],
          if (artifact.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              artifact.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final NoteArtifactStatus status;

  @override
  Widget build(BuildContext context) => Chip(
    visualDensity: VisualDensity.compact,
    label: Text(switch (status) {
      NoteArtifactStatus.generating => '生成中',
      NoteArtifactStatus.ready => '已保存',
      NoteArtifactStatus.stale => '基于旧稿',
      NoteArtifactStatus.failed => '失败',
    }),
  );
}
