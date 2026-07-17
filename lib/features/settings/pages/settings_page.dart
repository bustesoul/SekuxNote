import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../providers/pages/provider_settings_page.dart';
import '../../providers/pages/transcription_providers_page.dart';
import '../../providers/provider_controller.dart';
import '../../../l10n/app_localizations.dart';

/// Placeholder settings hub (text AI / transcription / privacy to follow).
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.providerController,
    this.onOpenTranscriptionWorkbench,
  });

  final ProviderController providerController;
  final VoidCallback? onOpenTranscriptionWorkbench;

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
          ListTile(
            key: const Key('settings_transcription_provider'),
            leading: const Icon(Icons.graphic_eq),
            title: Text(l10n.settingsTranscriptionTitle),
            subtitle: Text(l10n.settingsTranscriptionSubtitle),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TranscriptionProvidersPage(
                  controller: providerController,
                  onOpenTranscriptionWorkbench: onOpenTranscriptionWorkbench,
                ),
              ),
            ),
          ),
          ListTile(
            key: const Key('settings_text_provider'),
            leading: const Icon(Icons.smart_toy_outlined),
            title: Text(l10n.settingsTextAiTitle),
            subtitle: Text(l10n.settingsTextAiSubtitle),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProviderSettingsPage(
                  controller: providerController,
                  kind: ProviderSettingsKind.text,
                ),
              ),
            ),
          ),
          ListTile(
            enabled: false,
            leading: const Icon(Icons.shield_outlined),
            title: Text(l10n.settingsPrivacyTitle),
            subtitle: Text(l10n.settingsPrivacySubtitle),
          ),
        ],
      ),
    );
  }
}
