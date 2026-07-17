import 'package:flutter/material.dart';

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
      return SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.96,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'AI 总结 · ${widget.source.title}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
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
                      decoration: const InputDecoration(labelText: '文字 AI 供应商'),
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
                  final artifacts = snapshot.data ?? const <NoteArtifact>[];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (artifacts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('尚未生成总结。生成后将持久保存在本机。'),
                    );
                  }
                  return Column(
                    children: artifacts
                        .map((artifact) => _ArtifactCard(artifact: artifact))
                        .toList(growable: false),
                  );
                },
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

class _ArtifactCard extends StatelessWidget {
  const _ArtifactCard({required this.artifact});

  final NoteArtifact artifact;

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
            SelectionArea(child: Text(artifact.markdown)),
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
