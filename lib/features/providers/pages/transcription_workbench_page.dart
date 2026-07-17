import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../app/shell/app_session_controller.dart';
import '../provider_controller.dart';
import '../provider_debug_log.dart';
import '../provider_error_message.dart';
import '../provider_models.dart';
import '../openai_api_client.dart';

class TranscriptionWorkbenchPage extends StatefulWidget {
  const TranscriptionWorkbenchPage({
    super.key,
    required this.controller,
    required this.session,
  });

  final ProviderController controller;
  final AppSessionController session;

  @override
  State<TranscriptionWorkbenchPage> createState() =>
      _TranscriptionWorkbenchPageState();
}

class _TranscriptionWorkbenchPageState
    extends State<TranscriptionWorkbenchPage> {
  SelectedAudioFile? _file;
  TranscriptionTask? _task;
  bool _busy = false;
  late final TextEditingController _languageController;
  late final TextEditingController _speakerCountController;
  late String _providerId;
  bool _diarizationEnabled = false;
  TranscriptionFileMode _fileMode = TranscriptionFileMode.precision;

  TranscriptionProviderConfig get _provider =>
      widget.controller.transcriptionProviderById(_providerId) ??
      widget.controller.transcriptionConfig;
  bool get _isDashScope =>
      _provider.type == TranscriptionProviderType.dashScopeFunAsr;

  @override
  void initState() {
    super.initState();
    _languageController = TextEditingController(
      text: widget.controller.transcriptionConfig.language,
    );
    _speakerCountController = TextEditingController();
    _providerId = widget.controller.transcriptionSettings.defaultProviderId;
    _diarizationEnabled = _isDashScope;
  }

  @override
  void dispose() {
    _languageController.dispose();
    _speakerCountController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      await ProviderDebugLog.record('file_picker.opening');
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['m4a', 'mp3', 'wav'],
        withData: true,
      );
      final selected = picked?.files.single;
      final bytes = selected?.bytes;
      if (selected == null || bytes == null) {
        await ProviderDebugLog.record('file_picker.cancelled');
        return;
      }
      await ProviderDebugLog.record(
        'file_picker.selected',
        details: {'fileName': selected.name, 'fileBytes': bytes.length},
      );
      setState(() {
        _file = SelectedAudioFile(name: selected.name, bytes: bytes);
        _task = null;
      });
    } catch (error) {
      await ProviderDebugLog.record(
        'file_picker.error',
        details: {'type': error.runtimeType, 'message': error.toString()},
      );
      if (mounted) {
        _showError(providerErrorMessage(AppLocalizations.of(context), error));
      }
    }
  }

  Future<void> _confirmAndTranscribe() async {
    final file = _file;
    if (file == null) return;
    final language = _languageController.text.trim().toLowerCase();
    if (!RegExp(r'^[a-z]{2}$').hasMatch(language)) {
      _showError(
        AppLocalizations.of(context).providerTranscriptionLanguageHint,
      );
      return;
    }
    final speakerCount = int.tryParse(_speakerCountController.text.trim());
    if (_isDashScope &&
        _fileMode == TranscriptionFileMode.precision &&
        _diarizationEnabled &&
        _speakerCountController.text.trim().isNotEmpty &&
        (speakerCount == null || speakerCount < 2 || speakerCount > 100)) {
      _showError('预计说话人数必须为 2–100，或留空自动判断。');
      return;
    }
    final l10n = AppLocalizations.of(context);
    final config = _provider;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.transcriptionConfirmTitle),
        content: Text(
          l10n.transcriptionConfirmBody(
            file.name,
            _formatBytes(file.sizeBytes),
            config.name,
            _fileMode == TranscriptionFileMode.fast
                ? config.fastFileModel ?? config.batchModel
                : config.batchModel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.transcriptionConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    widget.session.startTranscription(file.name);
    try {
      final task = await widget.controller.startTranscriptionTask(
        file,
        providerId: _providerId,
        language: language,
        diarizationEnabled:
            _isDashScope &&
            _fileMode == TranscriptionFileMode.precision &&
            _diarizationEnabled,
        speakerCount:
            _isDashScope &&
                _fileMode == TranscriptionFileMode.precision &&
                _diarizationEnabled
            ? speakerCount
            : null,
        fileMode: _fileMode,
        onProgress: ({required total, required completed}) {
          widget.session.updateTranscriptionProgress(
            total: total,
            completed: completed,
          );
        },
        onPartialText: widget.session.updateTranscriptionPartialText,
      );
      if (mounted) setState(() => _task = task);
    } catch (error) {
      if (mounted) {
        _showError(providerErrorMessage(AppLocalizations.of(context), error));
      }
    } finally {
      widget.session.finishTranscription();
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyResult() async {
    final transcript = _task?.transcript;
    if (transcript == null) return;
    await Clipboard.setData(ClipboardData(text: transcript));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).transcriptionCopied),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final file = _file;
    final task = _task;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.transcriptionWorkbenchTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                FilledButton.icon(
                  key: const Key('transcription_choose_file'),
                  onPressed: _busy ? null : _pickFile,
                  icon: const Icon(Icons.audio_file_outlined),
                  label: Text(l10n.transcriptionChooseFile),
                ),
                const SizedBox(height: 16),
                Text(
                  file == null
                      ? l10n.transcriptionNoFile
                      : l10n.transcriptionSelectedFile(
                          file.name,
                          _formatBytes(file.sizeBytes),
                        ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('transcription_provider_select'),
                  initialValue: _providerId,
                  decoration: const InputDecoration(labelText: '转写供应商'),
                  items: widget.controller.transcriptionSettings.providers
                      .where((provider) => provider.enabled)
                      .map(
                        (provider) => DropdownMenuItem(
                          value: provider.id,
                          child: Text(provider.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _busy
                      ? null
                      : (value) {
                          if (value == null) return;
                          final provider = widget.controller
                              .transcriptionProviderById(value);
                          setState(() {
                            _providerId = value;
                            _languageController.text =
                                provider?.language ?? 'zh';
                            _diarizationEnabled =
                                provider?.type ==
                                TranscriptionProviderType.dashScopeFunAsr;
                            _speakerCountController.clear();
                            _fileMode = TranscriptionFileMode.precision;
                          });
                        },
                ),
                if (file != null) ...[
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('transcription_language'),
                    controller: _languageController,
                    enabled: !_busy,
                    textCapitalization: TextCapitalization.none,
                    decoration: InputDecoration(
                      labelText: l10n.providerTranscriptionLanguageLabel,
                      helperText: l10n.providerTranscriptionLanguageHint,
                    ),
                  ),
                  if (_isDashScope) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TranscriptionFileMode>(
                      key: const Key('transcription_file_mode'),
                      initialValue: _fileMode,
                      decoration: const InputDecoration(labelText: '文件转写方式'),
                      items: const [
                        DropdownMenuItem(
                          value: TranscriptionFileMode.precision,
                          child: Text('文件精转（异步任务，可说话人分离）'),
                        ),
                        DropdownMenuItem(
                          value: TranscriptionFileMode.fast,
                          child: Text('短文件快转（SSE，最长 5 分钟）'),
                        ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) => setState(() {
                              _fileMode =
                                  value ?? TranscriptionFileMode.precision;
                              if (_fileMode == TranscriptionFileMode.fast) {
                                _diarizationEnabled = false;
                                _speakerCountController.clear();
                              }
                            }),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      key: const Key('transcription_diarization'),
                      contentPadding: EdgeInsets.zero,
                      value: _diarizationEnabled,
                      onChanged:
                          _busy || _fileMode == TranscriptionFileMode.fast
                          ? null
                          : (value) =>
                                setState(() => _diarizationEnabled = value),
                      title: const Text('说话人分离'),
                      subtitle: const Text('单声道会议录音可输出说话人编号。'),
                    ),
                    if (_diarizationEnabled)
                      TextField(
                        key: const Key('transcription_speaker_count'),
                        controller: _speakerCountController,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '预计说话人数（可选）',
                          helperText: '2–100；留空由模型自动判断。',
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton(
                    key: const Key('transcription_start'),
                    onPressed: _busy ? null : _confirmAndTranscribe,
                    child: Text(
                      _busy
                          ? l10n.transcriptionUploading
                          : l10n.transcriptionConfirmAction,
                    ),
                  ),
                ],
                ListenableBuilder(
                  listenable: widget.session,
                  builder: (context, _) {
                    if (!widget.session.transcriptionRunning) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LinearProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            l10n.transcriptionTaskBanner(
                              widget.session.transcriptionFileName,
                              widget.session.transcriptionChunksCompleted,
                              widget.session.transcriptionChunksTotal,
                              widget.session.transcriptionElapsedSeconds,
                            ),
                          ),
                          if (widget
                              .session
                              .transcriptionPartialText
                              .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              widget.session.transcriptionPartialText,
                              key: const Key('transcription_partial_text'),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                if (task != null) ...[
                  const SizedBox(height: 32),
                  Text(
                    task.status == TranscriptionTaskStatus.succeeded
                        ? l10n.transcriptionResultTitle
                        : l10n.transcriptionTaskFailedTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('${task.providerName} · ${task.model}'),
                  const SizedBox(height: 12),
                  if (task.status == TranscriptionTaskStatus.succeeded) ...[
                    SelectionArea(child: Text(task.transcript ?? '')),
                    if (task.segments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('结构化句段'),
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
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _copyResult,
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(l10n.transcriptionCopy),
                    ),
                  ] else
                    Text(
                      providerErrorMessage(
                        l10n,
                        ProviderRequestException(
                          task.errorMessage ?? 'requestFailed',
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';

  String _timeLabel(double seconds) {
    final value = seconds.floor();
    return '${(value ~/ 60).toString().padLeft(2, '0')}:'
        '${(value % 60).toString().padLeft(2, '0')}';
  }
}
