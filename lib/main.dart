import 'package:flutter/material.dart';

import 'app/bootstrap/sekux_app.dart';
import 'features/providers/provider_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final providerController = await ProviderController.createPersistent();
  runApp(SekuxApp(providerController: providerController));
}
