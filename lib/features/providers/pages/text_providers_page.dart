import 'package:flutter/material.dart';

import '../provider_controller.dart';
import '../provider_models.dart';
import 'provider_settings_page.dart';

class TextProvidersPage extends StatelessWidget {
  const TextProvidersPage({super.key, required this.controller});

  final ProviderController controller;

  Future<void> _add(BuildContext context) async {
    final provider = await controller.addTextProvider();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProviderSettingsPage(
          controller: controller,
          kind: ProviderSettingsKind.text,
          textProviderId: provider.id,
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    TextProviderConfig provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除文字 AI 供应商？'),
        content: Text('将删除 ${provider.name} 的本地配置和 API Key。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteTextProvider(provider.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('文字 AI 供应商')),
    floatingActionButton: FloatingActionButton.extended(
      key: const Key('text_provider_add'),
      onPressed: () => _add(context),
      icon: const Icon(Icons.add),
      label: const Text('添加供应商'),
    ),
    body: ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final settings = controller.textSettings;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: settings.providers.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final provider = settings.providers[index];
            final isDefault = provider.id == settings.defaultProviderId;
            return ListTile(
              key: Key('text_provider_${provider.id}'),
              leading: const Icon(Icons.smart_toy_outlined),
              title: Text(provider.name),
              subtitle: Text(
                '${provider.protocol == TextProviderProtocol.responses ? 'Responses' : 'Chat Completions'} · ${provider.model}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: isDefault ? '默认供应商' : '设为默认',
                    onPressed: isDefault
                        ? null
                        : () => controller.setDefaultTextProvider(provider.id),
                    icon: Icon(
                      isDefault ? Icons.star : Icons.star_border,
                      color: isDefault
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  if (settings.providers.length > 1)
                    IconButton(
                      tooltip: '删除',
                      onPressed: () => _delete(context, provider),
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProviderSettingsPage(
                    controller: controller,
                    kind: ProviderSettingsKind.text,
                    textProviderId: provider.id,
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
