import 'package:flutter/material.dart';

import 'app/bootstrap/sekux_app.dart';
import 'features/providers/provider_controller.dart';
import 'features/assistant/assistant_controller.dart';
import 'features/recording/recording_background_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  RecordingBackgroundService.initialize();
  final providerController = await ProviderController.createPersistent();
  final assistantController = await AssistantController.createPersistent(
    providerController,
  );
  runApp(
    SekuxApp(
      providerController: providerController,
      assistantController: assistantController,
    ),
  );
}
