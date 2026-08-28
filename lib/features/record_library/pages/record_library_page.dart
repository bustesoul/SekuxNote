import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/openai_api_client.dart';
import '../../assistant/assistant_controller.dart';
import '../../assistant/assistant_models.dart';
import '../../assistant/pages/record_summary_sheet.dart';
import '../../assistant/record_ai_source_adapter.dart';
import '../../providers/provider_controller.dart';
import '../../providers/provider_error_message.dart';
import '../../providers/provider_models.dart';
import '../../recording/recording_models.dart';
import '../../recording/recording_session_controller.dart';

enum RecordLibraryMode { home, library }

class RecordLibraryPage extends StatefulWidget {
  const RecordLibraryPage({
    super.key,
    required this.providerController,
    required this.assistantController,
    required this.recordingController,
    required this.mode,
    this.onStartRecording,
    this.onTranscribeAudio,
  });

  final ProviderController providerController;
  final AssistantController assistantController;
  final RecordingSessionController recordingController;
  final RecordLibraryMode mode;
  final VoidCallback? onStartRecording;
  final VoidCallback? onTranscribeAudio;

  @override
  State<RecordLibraryPage> createState() => _RecordLibraryPageState();
}

class _RecordLibraryPageState extends State<RecordLibraryPage> {
  final _searchController = TextEditingController();
  String _query = '';

  bool get _isHome => widget.mode == RecordLibraryMode.home;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isHome ? l10n.tabHome : l10n.tabRecords)),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          widget.providerController,
          widget.recordingController,
        ]),
        builder: (context, _) => FutureBuilder<List<TranscriptionTask>>(
          future: widget.providerController.listTranscriptionTasks(),
          builder: (context, snapshot) {
            final tasks = snapshot.data ?? const <TranscriptionTask>[];
            final recordings = widget.recordingController.recordings;
            final records = <_RecordListItem>[
              ...tasks.map(_RecordListItem.task),
              ...recordings.map(_RecordListItem.recording),
            ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final normalizedQuery = _query.trim().toLowerCase();
            final matching = normalizedQuery.isEmpty
                ? records
                : records
                      .where(
                        (record) => record.title.toLowerCase().contains(
                          normalizedQuery,
                        ),
                      )
                      .toList(growable: false);
            final visible = _isHome
                ? matching.take(3).toList(growable: false)
                : matching;
            final isEmpty = records.isEmpty;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (_isHome) ...[
                      Icon(
                        Icons.library_music_outlined,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEmpty
                            ? l10n.recordsEmptyTitle
                            : l10n.homeRecentRecords,
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEmpty
                            ? l10n.recordsEmptyBody
                            : l10n.homeRecentRecordsBody,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const Key('records_start_recording'),
                        onPressed: widget.onStartRecording,
                        icon: const Icon(Icons.fiber_manual_record, size: 18),
                        label: Text(l10n.recordsStartButton),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('records_transcribe_audio'),
                        onPressed: widget.onTranscribeAudio,
                        icon: const Icon(Icons.audio_file_outlined),
                        label: Text(l10n.recordsTranscribeAudio),
                      ),
                    ] else ...[
                      TextField(
                        key: const Key('record_title_search'),
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: l10n.recordTitleSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: l10n.recordTitleSearchClear,
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                        ),
                      ),
                    ],
                    if (visible.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      for (final record in visible)
                        _recordCard(context, l10n, record),
                    ] else if (isEmpty && !_isHome) ...[
                      const SizedBox(height: 48),
                      Icon(
                        Icons.library_music_outlined,
                        size: 44,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.recordsEmptyTitle, textAlign: TextAlign.center),
                    ] else if (!isEmpty && !_isHome) ...[
                      const SizedBox(height: 48),
                      Icon(
                        Icons.search_off,
                        size: 44,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.recordTitleSearchEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _recordCard(
    BuildContext context,
    AppLocalizations l10n,
    _RecordListItem item,
  ) {
    final task = item.transcriptionTask;
    final canDelete = _canDelete(item);
    final desktop =
        MediaQuery.sizeOf(context).width >= 800 ||
        switch (Theme.of(context).platform) {
          TargetPlatform.macOS ||
          TargetPlatform.windows ||
          TargetPlatform.linux => true,
          _ => false,
        };
    final card = task != null
        ? Card(
            child: ListTile(
              key: Key('transcription_task_${task.id}'),
              leading: Icon(_taskIcon(task.status)),
              title: Text(task.fileName),
              subtitle: Text(
                '${_taskStatusLabel(l10n, task.status)} · '
                '${task.chunksCompleted}/${task.chunksTotal == 0 ? '?' : task.chunksTotal}',
              ),
              trailing: desktop && canDelete
                  ? _desktopDeleteMenu(context, l10n, item)
                  : const Icon(Icons.chevron_right),
              onTap: () => _showTaskDetails(context, task),
            ),
          )
        : Card(
            child: ListTile(
              key: Key('recording_${item.recordingEntry!.id}'),
              leading: Icon(
                item.recordingEntry!.status == RecordingStatus.ready
                    ? Icons.mic_none
                    : item.recordingEntry!.status == RecordingStatus.recovered
                    ? Icons.restore
                    : Icons.error_outline,
              ),
              title: Text(item.recordingEntry!.title),
              subtitle: Text(
                '${_recordingStatus(item.recordingEntry!.status)} · '
                '${_timeLabel(item.recordingEntry!.durationMilliseconds / 1000)}'
                '${item.recordingEntry!.realtimeTranscript.isEmpty ? '' : ' · 有实时临时稿'}',
              ),
              trailing: desktop && canDelete
                  ? _desktopDeleteMenu(context, l10n, item)
                  : const Icon(Icons.chevron_right),
              onTap: () => _showRecordingDetails(context, item.recordingEntry!),
            ),
          );
    if (desktop || !canDelete) return card;
    return Dismissible(
      key: Key('record_dismiss_${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _confirmAndDeleteRecord(context, l10n, item);
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      child: card,
    );
  }

  Widget _desktopDeleteMenu(
    BuildContext context,
    AppLocalizations l10n,
    _RecordListItem item,
  ) {
    final label = item.transcriptionTask != null
        ? l10n.transcriptionTaskDelete
        : l10n.recordingDelete;
    return PopupMenuButton<_RecordMenuAction>(
      key: Key('record_actions_${item.id}'),
      tooltip: label,
      onSelected: (_) =>
          unawaited(_confirmAndDeleteRecord(context, l10n, item)),
      itemBuilder: (context) => [
        PopupMenuItem(
          key: Key('record_action_delete_${item.id}'),
          value: _RecordMenuAction.delete,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text(label),
            ],
          ),
        ),
      ],
    );
  }

  bool _canDelete(_RecordListItem item) {
    final task = item.transcriptionTask;
    if (task != null) return task.isTerminal;
    return widget.recordingController.active?.id != item.recordingEntry!.id;
  }

  Future<bool> _confirmAndDeleteRecord(
    BuildContext pageContext,
    AppLocalizations l10n,
    _RecordListItem item,
  ) async {
    final task = item.transcriptionTask;
    final confirmed = await showDialog<bool>(
      context: pageContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          task != null
              ? l10n.transcriptionTaskDeleteConfirmTitle
              : l10n.recordingDeleteConfirmTitle,
        ),
        content: Text(
          task != null
              ? l10n.transcriptionTaskDeleteConfirmBody
              : l10n.recordingDeleteConfirmBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            key: Key(
              task != null
                  ? 'transcription_task_delete_confirm_${task.id}'
                  : 'recording_delete_confirm_${item.recordingEntry!.id}',
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              task != null
                  ? l10n.transcriptionTaskDelete
                  : l10n.recordingDelete,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    if (task != null) {
      await widget.providerController.deleteTranscriptionTask(task.id);
    } else {
      await widget.recordingController.deleteRecording(item.recordingEntry!.id);
    }
    if (pageContext.mounted) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        SnackBar(
          content: Text(
            task != null
                ? l10n.transcriptionTaskDeleted
                : l10n.recordingDeleted,
          ),
        ),
      );
    }
    return true;
  }

  Future<void> _showTaskDetails(
    BuildContext pageContext,
    TranscriptionTask task,
  ) {
    final l10n = AppLocalizations.of(pageContext);
    return showModalBottomSheet<void>(
      context: pageContext,
      isScrollControlled: true,
      builder: (sheetContext) => _detailSheet(
        sheetContext,
        title: task.fileName,
        backKey: const Key('task_detail_back'),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Text('${task.providerName} · ${task.model}'),
            const SizedBox(height: 8),
            Text(
              '${l10n.transcriptionTaskStatusLabel}: '
              '${_taskStatusLabel(l10n, task.status)}',
            ),
            Text(
              '${l10n.transcriptionTaskChunkProgress}: '
              '${task.chunksCompleted}/${task.chunksTotal == 0 ? '?' : task.chunksTotal}',
            ),
            if (task.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                providerErrorMessage(
                  l10n,
                  ProviderRequestException(task.errorMessage!),
                ),
              ),
            ],
            if (task.transcript != null) ...[
              const SizedBox(height: 16),
              Text(l10n.transcriptionResultTitle),
              const SizedBox(height: 8),
              SelectionArea(child: Text(task.transcript!)),
            ],
            if (task.segments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '结构化句段',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final segment in task.segments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${segment.speakerId == null ? '' : '说话人 ${segment.speakerId} · '}'
                    '[${_timeLabel(segment.startSeconds)} – ${_timeLabel(segment.endSeconds)}] '
                    '${segment.text}',
                  ),
                ),
            ],
            if (recordAiSourceFromTask(task) case final source?) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                key: Key('task_summary_${task.id}'),
                onPressed: () => _showSummary(pageContext, source),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AI 总结'),
              ),
            ],
            const SizedBox(height: 24),
            if (task.status == TranscriptionTaskStatus.running)
              OutlinedButton.icon(
                onPressed: () async {
                  await widget.providerController.stopTranscriptionTask(
                    task.id,
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(l10n.transcriptionTaskStop),
              )
            else if (task.status == TranscriptionTaskStatus.failed ||
                task.status == TranscriptionTaskStatus.stopped)
              if (task.sourcePath == null)
                Text(
                  providerErrorMessage(
                    l10n,
                    const ProviderRequestException('sourceAudioMissing'),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () async {
                    unawaited(
                      widget.providerController.retryTranscriptionTask(task.id),
                    );
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.transcriptionTaskRetry),
                ),
            if (task.isTerminal) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                key: Key('transcription_task_delete_${task.id}'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(sheetContext).colorScheme.error,
                ),
                onPressed: () async {
                  final deleted = await _confirmAndDeleteRecord(
                    pageContext,
                    l10n,
                    _RecordListItem.task(task),
                  );
                  if (deleted && sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.transcriptionTaskDelete),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showRecordingDetails(
    BuildContext pageContext,
    RecordingEntry recording,
  ) {
    final l10n = AppLocalizations.of(pageContext);
    return showModalBottomSheet<void>(
      context: pageContext,
      isScrollControlled: true,
      builder: (sheetContext) => _detailSheet(
        sheetContext,
        title: recording.title,
        backKey: const Key('recording_detail_back'),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Text('原始音频：${recording.audioPath}'),
            const SizedBox(height: 16),
            const Text('实时文字（临时稿）'),
            const SizedBox(height: 8),
            SelectionArea(child: Text(recording.realtimeTranscript)),
            if (recordAiSourceFromRecording(recording) case final source?) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                key: Key('recording_summary_${recording.id}'),
                onPressed: () => _showSummary(pageContext, source),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AI 总结'),
              ),
            ],
            if (widget.recordingController.active?.id != recording.id) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                key: Key('recording_delete_${recording.id}'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(sheetContext).colorScheme.error,
                ),
                onPressed: () async {
                  final deleted = await _confirmAndDeleteRecord(
                    pageContext,
                    l10n,
                    _RecordListItem.recording(recording),
                  );
                  if (deleted && sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.recordingDelete),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailSheet(
    BuildContext context, {
    required String title,
    required Key backKey,
    required Widget child,
  }) {
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
                    key: backKey,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
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
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Future<void> _showSummary(BuildContext context, RecordAiSource source) async {
    if (source.revisionLabel.contains('临时稿')) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('使用实时临时稿生成总结？'),
          content: const Text('这条记录还没有会后最终稿。总结会明确绑定当前实时转写版本。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('继续'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RecordSummarySheet(
        source: source,
        controller: widget.assistantController,
        providerController: widget.providerController,
      ),
    );
  }

  String _recordingStatus(RecordingStatus status) => switch (status) {
    RecordingStatus.recording => '正在录音',
    RecordingStatus.paused => '已暂停',
    RecordingStatus.ready => '已保存',
    RecordingStatus.recovered => '异常退出后已恢复',
    RecordingStatus.failed => '录音失败',
  };

  IconData _taskIcon(TranscriptionTaskStatus status) => switch (status) {
    TranscriptionTaskStatus.queued => Icons.schedule_outlined,
    TranscriptionTaskStatus.running => Icons.sync,
    TranscriptionTaskStatus.succeeded => Icons.check_circle_outline,
    TranscriptionTaskStatus.failed => Icons.error_outline,
    TranscriptionTaskStatus.stopped => Icons.stop_circle_outlined,
  };

  String _taskStatusLabel(
    AppLocalizations l10n,
    TranscriptionTaskStatus status,
  ) => switch (status) {
    TranscriptionTaskStatus.queued => l10n.transcriptionTaskQueued,
    TranscriptionTaskStatus.running => l10n.transcriptionTaskRunning,
    TranscriptionTaskStatus.succeeded => l10n.transcriptionTaskSucceeded,
    TranscriptionTaskStatus.failed => l10n.transcriptionTaskFailed,
    TranscriptionTaskStatus.stopped => l10n.transcriptionTaskStopped,
  };

  String _timeLabel(double seconds) {
    final value = seconds.floor();
    return '${(value ~/ 60).toString().padLeft(2, '0')}:'
        '${(value % 60).toString().padLeft(2, '0')}';
  }
}

class _RecordListItem {
  const _RecordListItem._({this.transcriptionTask, this.recordingEntry});

  factory _RecordListItem.task(TranscriptionTask task) =>
      _RecordListItem._(transcriptionTask: task);

  factory _RecordListItem.recording(RecordingEntry recording) =>
      _RecordListItem._(recordingEntry: recording);

  final TranscriptionTask? transcriptionTask;
  final RecordingEntry? recordingEntry;

  String get id => transcriptionTask?.id ?? recordingEntry!.id;

  String get title => transcriptionTask?.fileName ?? recordingEntry!.title;

  DateTime get createdAt =>
      transcriptionTask?.createdAt ?? recordingEntry!.createdAt;
}

enum _RecordMenuAction { delete }
