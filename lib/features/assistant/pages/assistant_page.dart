import 'package:flutter/material.dart';

import '../../../app/shell/app_session_controller.dart';
import '../../../l10n/app_localizations.dart';

/// Placeholder for the general AI assistant tab (self-built UI).
class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key, required this.session});

  final AppSessionController session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.assistantTitle)),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.assistantHeadline,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.assistantBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.demoTaskTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.demoTaskRunning
                          ? l10n.demoTaskRunning(session.demoElapsedSeconds)
                          : l10n.demoTaskIdle,
                      key: const Key('demo_task_status'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (session.demoTaskRunning)
                      OutlinedButton(
                        key: const Key('demo_task_stop'),
                        onPressed: session.stopDemoLongTask,
                        child: Text(l10n.demoTaskStop),
                      )
                    else
                      FilledButton(
                        key: const Key('demo_task_start'),
                        onPressed: session.startDemoLongTask,
                        child: Text(l10n.demoTaskStart),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
