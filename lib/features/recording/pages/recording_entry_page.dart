import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../recording_models.dart';
import '../recording_session_controller.dart';

class RecordingEntryPage extends StatefulWidget {
  const RecordingEntryPage({super.key, required this.controller});

  final RecordingSessionController controller;

  @override
  State<RecordingEntryPage> createState() => _RecordingEntryPageState();
}

class _RecordingEntryPageState extends State<RecordingEntryPage> {
  final _titleController = TextEditingController();
  bool _realtimeEnabled = true;
  bool _busy = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      await widget.controller.start(
        title: _titleController.text,
        realtimeEnabled: _realtimeEnabled,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    setState(() => _busy = true);
    await widget.controller.stop();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final active = widget.controller.active;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.recordingTitle),
            leading: BackButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: active == null
                      ? _preparation(context)
                      : _recording(context, active),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _preparation(BuildContext context) => [
    const Icon(Icons.mic, size: 72),
    const SizedBox(height: 24),
    TextField(
      key: const Key('recording_title'),
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: '标题（可选）',
        hintText: '例如：项目周会',
      ),
    ),
    const SizedBox(height: 16),
    SwitchListTile(
      key: const Key('recording_realtime_enabled'),
      contentPadding: EdgeInsets.zero,
      value: _realtimeEnabled,
      onChanged: _busy
          ? null
          : (value) => setState(() => _realtimeEnabled = value),
      title: const Text('录音中实时转写'),
      subtitle: const Text('使用所选供应商的实时模型；本地录音不依赖网络。'),
    ),
    const SizedBox(height: 24),
    FilledButton.icon(
      key: const Key('recording_start'),
      onPressed: _busy ? null : _start,
      icon: const Icon(Icons.fiber_manual_record),
      label: const Text('开始录音'),
    ),
  ];

  List<Widget> _recording(BuildContext context, RecordingEntry entry) {
    final completed = entry.realtimeTranscript;
    final partial = widget.controller.partialText;
    return [
      Icon(
        entry.status == RecordingStatus.paused
            ? Icons.pause_circle
            : Icons.graphic_eq,
        size: 72,
        color: Theme.of(context).colorScheme.error,
      ),
      const SizedBox(height: 16),
      Text(
        _duration(widget.controller.elapsedMilliseconds),
        key: const Key('recording_elapsed'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.displaySmall,
      ),
      const SizedBox(height: 8),
      Text(
        _status(entry),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 24),
      if (completed.isNotEmpty || partial.isNotEmpty) ...[
        Text('实时文字（临时稿）', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SelectionArea(
          child: Text(
            [completed, partial].where((value) => value.isNotEmpty).join('\n'),
            key: const Key('recording_realtime_transcript'),
          ),
        ),
        const SizedBox(height: 24),
      ],
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('recording_pause_resume'),
              onPressed: _busy
                  ? null
                  : entry.status == RecordingStatus.paused
                  ? widget.controller.resume
                  : widget.controller.pause,
              icon: Icon(
                entry.status == RecordingStatus.paused
                    ? Icons.play_arrow
                    : Icons.pause,
              ),
              label: Text(entry.status == RecordingStatus.paused ? '继续' : '暂停'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              key: const Key('recording_stop'),
              onPressed: _busy ? null : _stop,
              icon: const Icon(Icons.stop),
              label: const Text('结束并保存'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const Text(
        '返回或切换页面不会结束录音；请通过“结束并保存”完成本地音频文件。',
        textAlign: TextAlign.center,
      ),
    ];
  }

  String _status(RecordingEntry entry) {
    if (entry.status == RecordingStatus.paused) return '已暂停';
    return switch (entry.realtimeStatus) {
      RealtimeRecordingStatus.connecting => '正在录音 · 正在连接转写服务',
      RealtimeRecordingStatus.streaming => '正在录音 · 实时转写中',
      RealtimeRecordingStatus.interrupted => '录音仍在继续 · 实时转写已中断',
      _ => '正在录音',
    };
  }

  String _duration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
