import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Placeholder for the recording preparation / in-session flow entry.
///
/// Does not own a recording session. Future mic sessions must live at app
/// service level so leaving this route cannot stop capture.
class RecordingEntryPage extends StatelessWidget {
  const RecordingEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recordingTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.errorContainer,
                  ),
                  child: Icon(
                    Icons.mic,
                    size: 40,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.recordingPlaceholderHeadline,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.recordingPlaceholderBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(l10n.recordingBack),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
