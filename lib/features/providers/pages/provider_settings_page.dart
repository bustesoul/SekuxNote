import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../provider_controller.dart';
import '../provider_error_message.dart';

enum ProviderSettingsKind { text, transcription }

class ProviderSettingsPage extends StatefulWidget {
  const ProviderSettingsPage({
    super.key,
    required this.controller,
    required this.kind,
    this.onOpenTranscriptionWorkbench,
  });

  final ProviderController controller;
  final ProviderSettingsKind kind;
  final VoidCallback? onOpenTranscriptionWorkbench;

  @override
  State<ProviderSettingsPage> createState() => _ProviderSettingsPageState();
}

class _ProviderSettingsPageState extends State<ProviderSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;
  final _apiKeyController = TextEditingController();
  late bool _enabled;
  bool _saving = false;

  bool get _isText => widget.kind == ProviderSettingsKind.text;

  @override
  void initState() {
    super.initState();
    if (_isText) {
      final config = widget.controller.textConfig;
      _nameController = TextEditingController(text: config.name);
      _baseUrlController = TextEditingController(text: config.baseUrl);
      _modelController = TextEditingController(text: config.model);
      _enabled = config.enabled;
    } else {
      final config = widget.controller.transcriptionConfig;
      _nameController = TextEditingController(text: config.name);
      _baseUrlController = TextEditingController(text: config.baseUrl);
      _modelController = TextEditingController(text: config.batchModel);
      _enabled = config.enabled;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    if (!_formKey.currentState!.validate()) return false;
    setState(() => _saving = true);
    try {
      if (_isText) {
        await widget.controller.saveText(
          name: _nameController.text,
          enabled: _enabled,
          baseUrl: _baseUrlController.text,
          model: _modelController.text,
          apiKey: _apiKeyController.text,
        );
      } else {
        await widget.controller.saveTranscription(
          name: _nameController.text,
          enabled: _enabled,
          baseUrl: _baseUrlController.text,
          batchModel: _modelController.text,
          apiKey: _apiKeyController.text,
        );
      }
      _apiKeyController.clear();
      if (mounted) {
        setState(() {});
      }
      return true;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _testTextApi() async {
    if (!await _save()) return;
    setState(() => _saving = true);
    try {
      final result = await widget.controller.testText();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          final usage = result.usage.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join(', ');
          return AlertDialog(
            title: Text(l10n.providerTestResultTitle),
            content: SelectionArea(
              child: Text(
                '${result.model}\n\n${result.output}'
                '${usage.isEmpty ? '' : '\n\n${l10n.providerUsage}: $usage'}',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(MaterialLocalizations.of(context).closeButtonLabel),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (mounted) {
        _showError(providerErrorMessage(AppLocalizations.of(context), error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final credentialsStored = _isText
        ? widget.controller.textCredentialConfigured
        : widget.controller.transcriptionCredentialConfigured;
    final title = _isText
        ? l10n.settingsTextAiTitle
        : l10n.settingsTranscriptionTitle;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.providerNameLabel,
                    ),
                    validator: _notBlank,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _baseUrlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: l10n.providerBaseUrlLabel,
                    ),
                    validator: _validUrl,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      labelText: l10n.providerModelLabel,
                    ),
                    validator: _notBlank,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apiKeyController,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: l10n.providerApiKeyLabel,
                      helperText: l10n.providerApiKeyHint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    credentialsStored
                        ? l10n.providerCredentialSet
                        : l10n.providerCredentialMissing,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _enabled,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _enabled = value),
                    title: Text(l10n.providerEnabledLabel),
                  ),
                  if (!_isText) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.providerCapabilities,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    l10n.providerTestNotice,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: Key(
                      _isText
                          ? 'provider_save_text'
                          : 'provider_save_transcription',
                    ),
                    onPressed: _saving ? null : _save,
                    child: Text(l10n.providerSave),
                  ),
                  const SizedBox(height: 12),
                  if (_isText)
                    OutlinedButton(
                      key: const Key('provider_test_text'),
                      onPressed: _saving ? null : _testTextApi,
                      child: Text(
                        _saving
                            ? l10n.providerTestRunning
                            : l10n.providerTestTextApi,
                      ),
                    )
                  else
                    OutlinedButton(
                      key: const Key('provider_open_transcription_workbench'),
                      onPressed: _saving
                          ? null
                          : () async {
                              if (await _save() && mounted) {
                                widget.onOpenTranscriptionWorkbench?.call();
                              }
                            },
                      child: Text(l10n.providerTestTranscriptionApi),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _notBlank(String? value) =>
      value == null || value.trim().isEmpty ? '' : null;

  String? _validUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    return uri == null || !uri.hasScheme || uri.host.isEmpty ? '' : null;
  }
}
