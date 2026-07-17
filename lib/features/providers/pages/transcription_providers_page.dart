import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../provider_controller.dart';
import '../provider_models.dart';
import 'provider_settings_page.dart';

class TranscriptionProvidersPage extends StatelessWidget {
  const TranscriptionProvidersPage({
    super.key,
    required this.controller,
    this.onOpenTranscriptionWorkbench,
  });

  final ProviderController controller;
  final VoidCallback? onOpenTranscriptionWorkbench;

  Future<void> _add(BuildContext context) async {
    final type = await showModalBottomSheet<TranscriptionProviderType>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    key: const Key('transcription_provider_picker_back'),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '添加转写供应商',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.api_outlined),
              title: const Text('OpenAI 兼容'),
              subtitle: const Text('Groq、OpenAI 或其他兼容 Audio API'),
              onTap: () => Navigator.pop(
                context,
                TranscriptionProviderType.openAiCompatible,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.graphic_eq),
              title: const Text('阿里百炼（原生 ASR）'),
              subtitle: const Text('选择 Fun-ASR 模型；支持句段、词级时间戳和说话人分离'),
              onTap: () => Navigator.pop(
                context,
                TranscriptionProviderType.dashScopeFunAsr,
              ),
            ),
          ],
        ),
      ),
    );
    if (type == null || !context.mounted) return;
    final provider = await controller.addTranscriptionProvider(type);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProviderSettingsPage(
          controller: controller,
          kind: ProviderSettingsKind.transcription,
          transcriptionProviderId: provider.id,
          onOpenTranscriptionWorkbench: onOpenTranscriptionWorkbench,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTranscriptionTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('transcription_provider_add'),
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('添加供应商'),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final settings = controller.transcriptionSettings;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: settings.providers.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final provider = settings.providers[index];
              final isDefault = provider.id == settings.defaultProviderId;
              return ListTile(
                key: Key('transcription_provider_${provider.id}'),
                leading: Icon(
                  provider.type == TranscriptionProviderType.dashScopeFunAsr
                      ? Icons.graphic_eq
                      : Icons.api_outlined,
                ),
                title: Text(provider.name),
                subtitle: Text(
                  provider.type == TranscriptionProviderType.dashScopeFunAsr
                      ? '阿里百炼原生 · ${provider.batchModel}'
                      : '${provider.baseUrl} · ${provider.batchModel}',
                ),
                trailing: IconButton(
                  tooltip: isDefault ? '默认供应商' : '设为默认',
                  icon: Icon(
                    isDefault ? Icons.star : Icons.star_border,
                    color: isDefault
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: isDefault
                      ? null
                      : () => controller.setDefaultTranscriptionProvider(
                          provider.id,
                        ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProviderSettingsPage(
                      controller: controller,
                      kind: ProviderSettingsKind.transcription,
                      transcriptionProviderId: provider.id,
                      onOpenTranscriptionWorkbench:
                          onOpenTranscriptionWorkbench,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
