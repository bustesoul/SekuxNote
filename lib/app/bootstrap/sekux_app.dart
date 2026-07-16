import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/app_localizations.dart';
import '../../features/providers/provider_controller.dart';
import '../shell/app_session_controller.dart';
import '../shell/app_shell.dart';
import '../theme/app_theme.dart';

/// Root widget for SekuxNote.
class SekuxApp extends StatefulWidget {
  const SekuxApp({
    super.key,
    this.session,
    this.locale,
    this.providerController,
  });

  final AppSessionController? session;
  final Locale? locale;
  final ProviderController? providerController;

  @override
  State<SekuxApp> createState() => _SekuxAppState();
}

class _SekuxAppState extends State<SekuxApp> {
  late final ProviderController _providerController;
  late final bool _ownsProviderController;

  @override
  void initState() {
    super.initState();
    _ownsProviderController = widget.providerController == null;
    _providerController =
        widget.providerController ?? ProviderController.inMemory();
  }

  @override
  void dispose() {
    if (_ownsProviderController) _providerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: widget.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppShell(
        session: widget.session,
        providerController: _providerController,
      ),
    );
  }
}
