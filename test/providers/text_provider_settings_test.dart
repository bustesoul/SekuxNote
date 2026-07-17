import 'package:flutter_test/flutter_test.dart';
import 'package:sekuxnote/features/providers/provider_controller.dart';
import 'package:sekuxnote/features/providers/provider_models.dart';

void main() {
  test(
    'multiple text providers keep an explicit default provider and model',
    () async {
      final controller = ProviderController.inMemory();
      addTearDown(controller.dispose);
      await controller.load();
      final added = await controller.addTextProvider();
      await controller.saveText(
        providerId: added.id,
        name: 'DeepSeek',
        enabled: true,
        baseUrl: 'https://api.deepseek.com/v1',
        model: 'deepseek-chat',
        models: const ['deepseek-chat', 'deepseek-reasoner'],
        protocol: TextProviderProtocol.chatCompletions,
        apiKey: 'secret',
      );
      await controller.setDefaultTextProvider(added.id);

      expect(controller.textSettings.providers, hasLength(2));
      expect(controller.textConfig.name, 'DeepSeek');
      expect(controller.textConfig.model, 'deepseek-chat');
      expect(controller.textConfig.models, contains('deepseek-reasoner'));
      expect(controller.textCredentialConfigured, isTrue);
    },
  );
}
