import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Placeholder for the record library (Gate A default home).
class RecordLibraryPage extends StatefulWidget {
  const RecordLibraryPage({
    super.key,
    this.onStartRecording,
    this.onTranscribeAudio,
  });

  final VoidCallback? onStartRecording;
  final VoidCallback? onTranscribeAudio;

  @override
  State<RecordLibraryPage> createState() => _RecordLibraryPageState();
}

class _RecordLibraryPageState extends State<RecordLibraryPage> {
  /// Proves IndexedStack keep-alive for tab-local UI state (FR-NAV-004).
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recordsTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_music_outlined,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.recordsEmptyTitle,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.recordsEmptyBody,
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
                  icon: const Icon(Icons.audio_file_outlined, size: 18),
                  label: Text(l10n.recordsTranscribeAudio),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.keepAliveCounterLabel,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '$_counter',
                  key: const Key('records_keep_alive_counter'),
                  style: theme.textTheme.headlineMedium,
                ),
                TextButton(
                  key: const Key('records_keep_alive_increment'),
                  onPressed: () => setState(() => _counter += 1),
                  child: Text(l10n.keepAliveIncrement),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
