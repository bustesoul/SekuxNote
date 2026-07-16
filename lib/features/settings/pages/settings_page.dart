import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../l10n/app_localizations.dart';

/// Placeholder settings hub (text AI / transcription / privacy to follow).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _showAbout(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: l10n.appName,
      applicationVersion: '${info.version}+${info.buildNumber}',
      applicationLegalese: l10n.settingsAboutLegalese,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            key: const Key('settings_about'),
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAboutTitle),
            subtitle: Text(l10n.settingsAboutSubtitle),
            onTap: () => _showAbout(context),
          ),
          const Divider(height: 1),
          _UpcomingTile(
            icon: Icons.graphic_eq,
            title: l10n.settingsTranscriptionTitle,
            subtitle: l10n.settingsTranscriptionSubtitle,
            theme: theme,
          ),
          _UpcomingTile(
            icon: Icons.smart_toy_outlined,
            title: l10n.settingsTextAiTitle,
            subtitle: l10n.settingsTextAiSubtitle,
            theme: theme,
          ),
          _UpcomingTile(
            icon: Icons.shield_outlined,
            title: l10n.settingsPrivacyTitle,
            subtitle: l10n.settingsPrivacySubtitle,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(subtitle),
      enabled: false,
    );
  }
}
