import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../provider_controller.dart';
import '../provider_error_message.dart';
import '../provider_models.dart';

class TranscriptionWorkbenchPage extends StatefulWidget {
  const TranscriptionWorkbenchPage({super.key, required this.controller});

  final ProviderController controller;

  @override
  State<TranscriptionWorkbenchPage> createState() =>
      _TranscriptionWorkbenchPageState();
}

class _TranscriptionWorkbenchPageState
    extends State<TranscriptionWorkbenchPage> {
  SelectedAudioFile? _file;
  TranscriptionResult? _result;
  bool _busy = false;

  Future<void> _pickFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['m4a', 'mp3', 'wav'],
        withData: true,
      );
      final selected = picked?.files.single;
      final bytes = selected?.bytes;
      if (selected == null || bytes == null) return;
      setState(() {
        _file = SelectedAudioFile(name: selected.name, bytes: bytes);
        _result = null;
      });
    } catch (error) {
      if (mounted) {
        _showError(providerErrorMessage(AppLocalizations.of(context), error));
      }
    }
  }

  Future<void> _confirmAndTranscribe() async {
    final file = _file;
    if (file == null) return;
    final l10n = AppLocalizations.of(context);
    final config = widget.controller.transcriptionConfig;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.transcriptionConfirmTitle),
        content: Text(
          l10n.transcriptionConfirmBody(
            file.name,
            _formatBytes(file.sizeBytes),
            config.name,
            config.batchModel,
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
    try {
      final result = await widget.controller.transcribe(file);
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) {
        _showError(providerErrorMessage(AppLocalizations.of(context), error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyResult() async {
    final result = _result;
    if (result == null) return;
    await Clipboard.setData(ClipboardData(text: result.text));
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
    final result = _result;
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
                if (file != null) ...[
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
                if (result != null) ...[
                  const SizedBox(height: 32),
                  Text(
                    l10n.transcriptionResultTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('${result.providerName} · ${result.model}'),
                  if (result.usage.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.providerUsage}: ${jsonEncode(result.usage)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  SelectionArea(child: Text(result.text)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _copyResult,
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(l10n.transcriptionCopy),
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
}
