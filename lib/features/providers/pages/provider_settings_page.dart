import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../provider_controller.dart';
import '../provider_error_message.dart';
import '../provider_models.dart';

enum ProviderSettingsKind { text, transcription }

class ProviderSettingsPage extends StatefulWidget {
  const ProviderSettingsPage({
    super.key,
    required this.controller,
    required this.kind,
    this.transcriptionProviderId,
    this.onOpenTranscriptionWorkbench,
  });

  final ProviderController controller;
  final ProviderSettingsKind kind;
  final String? transcriptionProviderId;
  final VoidCallback? onOpenTranscriptionWorkbench;

  @override
  State<ProviderSettingsPage> createState() => _ProviderSettingsPageState();
}

class _ProviderSettingsPageState extends State<ProviderSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;
  late final TextEditingController _fastFileModelController;
  late final TextEditingController _realtimeModelController;
  TextEditingController? _dashScopeApiUrlController;
  TextEditingController? _chunkDurationController;
  TextEditingController? _concurrencyController;
  final _apiKeyController = TextEditingController();
  late bool _enabled;
  bool _saving = false;
  bool _credentialsStored = false;
  bool _apiKeyVisible = false;

  bool get _isText => widget.kind == ProviderSettingsKind.text;
  TranscriptionProviderConfig get _transcriptionConfig =>
      widget.controller.transcriptionProviderById(
        widget.transcriptionProviderId ??
            widget.controller.transcriptionSettings.defaultProviderId,
      ) ??
      widget.controller.transcriptionConfig;
  bool get _isDashScope =>
      !_isText &&
      _transcriptionConfig.type == TranscriptionProviderType.dashScopeFunAsr;

  @override
  void initState() {
    super.initState();
    if (_isText) {
      final config = widget.controller.textConfig;
      _nameController = TextEditingController(text: config.name);
      _baseUrlController = TextEditingController(text: config.baseUrl);
      _modelController = TextEditingController(text: config.model);
      _fastFileModelController = TextEditingController();
      _realtimeModelController = TextEditingController();
      _enabled = config.enabled;
    } else {
      final config = _transcriptionConfig;
      _nameController = TextEditingController(text: config.name);
      _baseUrlController = TextEditingController(text: config.baseUrl);
      _modelController = TextEditingController(text: config.batchModel);
      _fastFileModelController = TextEditingController(
        text: config.fastFileModel ?? '',
      );
      _realtimeModelController = TextEditingController(
        text: config.realtimeModel ?? '',
      );
      _chunkDurationController = TextEditingController(
        text: config.chunkDurationSeconds.toString(),
      );
      _concurrencyController = TextEditingController(
        text: config.maxConcurrentUploads.toString(),
      );
      _dashScopeApiUrlController = TextEditingController(
        text: config.dashScopeApiUrl,
      );
      _enabled = config.enabled;
    }
    _loadCredentialState();
  }

  Future<void> _loadCredentialState() async {
    final stored = _isText
        ? widget.controller.textCredentialConfigured
        : await widget.controller.transcriptionCredentialConfiguredFor(
            _transcriptionConfig.id,
          );
    if (mounted) setState(() => _credentialsStored = stored);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _fastFileModelController.dispose();
    _realtimeModelController.dispose();
    _dashScopeApiUrlController?.dispose();
    _chunkDurationController?.dispose();
    _concurrencyController?.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    if (!_formKey.currentState!.validate()) return false;
    setState(() => _saving = true);
    final enteredApiKey = _apiKeyController.text.trim().isNotEmpty;
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
          providerId: _transcriptionConfig.id,
          name: _nameController.text,
          enabled: _enabled,
          baseUrl: _isDashScope ? '' : _baseUrlController.text,
          batchModel: _modelController.text,
          fastFileModel: _isDashScope ? _fastFileModelController.text : null,
          realtimeModel: _realtimeModelController.text,
          language: _transcriptionConfig.language,
          chunkDurationSeconds: _isDashScope
              ? 60
              : int.parse(_chunkDurationController!.text),
          maxConcurrentUploads: _isDashScope
              ? 1
              : int.parse(_concurrencyController!.text),
          dashScopeApiUrl: _isDashScope
              ? _dashScopeApiUrlController!.text
              : null,
          apiKey: _apiKeyController.text,
        );
      }
      _apiKeyController.clear();
      if (mounted) {
        if (enteredApiKey) {
          _credentialsStored = true;
        } else {
          await _loadCredentialState();
        }
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
                key: const Key('provider_settings_scroll'),
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
                  if (!_isDashScope) ...[
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
                  ] else ...[
                    DropdownButtonFormField<String>(
                      key: const Key('dashscope_model'),
                      initialValue:
                          _dashScopeModels.contains(
                            _modelController.text.trim(),
                          )
                          ? _modelController.text.trim()
                          : 'fun-asr',
                      decoration: InputDecoration(labelText: '文件精转模型（异步任务）'),
                      items: _dashScopeModels
                          .map(
                            (model) => DropdownMenuItem(
                              value: model,
                              child: Text(model),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _saving
                          ? null
                          : (model) => setState(
                              () => _modelController.text = model ?? 'fun-asr',
                            ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: const Key('dashscope_fast_file_model'),
                      initialValue:
                          _dashScopeFastFileModels.contains(
                            _fastFileModelController.text.trim(),
                          )
                          ? _fastFileModelController.text.trim()
                          : _dashScopeFastFileModels.first,
                      decoration: const InputDecoration(
                        labelText: '短文件快速模型（同步 SSE）',
                        helperText: '完整文件上传后渐进返回文字；最长 5 分钟，不支持说话人分离。',
                      ),
                      items: _dashScopeFastFileModels
                          .map(
                            (model) => DropdownMenuItem(
                              value: model,
                              child: Text(model),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _saving
                          ? null
                          : (model) => setState(
                              () => _fastFileModelController.text =
                                  model ?? _dashScopeFastFileModels.first,
                            ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: const Key('dashscope_realtime_model'),
                      initialValue:
                          _dashScopeRealtimeModels.contains(
                            _realtimeModelController.text.trim(),
                          )
                          ? _realtimeModelController.text.trim()
                          : _dashScopeRealtimeModels.first,
                      decoration: const InputDecoration(
                        labelText: '录音中实时模型（WebSocket）',
                        helperText: '麦克风边录边传，实时文字作为临时稿保存。',
                      ),
                      items: _dashScopeRealtimeModels
                          .map(
                            (model) => DropdownMenuItem(
                              value: model,
                              child: Text(model),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _saving
                          ? null
                          : (model) => setState(
                              () => _realtimeModelController.text =
                                  model ?? _dashScopeRealtimeModels.first,
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('dashscope_api_url'),
                      controller: _dashScopeApiUrlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'DashScope API URL',
                        helperText:
                            '粘贴控制台的 https://…/api/v1；实时 WebSocket 地址自动推导。',
                      ),
                      validator: _validUrl,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '临时上传仅适合个人使用和验证；生产环境应改用 OSS。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (!_isText && !_isDashScope) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('provider_realtime_model'),
                      controller: _realtimeModelController,
                      decoration: const InputDecoration(
                        labelText: '录音中实时模型（可选）',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('provider_chunk_duration'),
                      controller: _chunkDurationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.providerChunkDurationLabel,
                        helperText: l10n.providerChunkDurationHint,
                      ),
                      validator: _positiveNumber,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('provider_upload_concurrency'),
                      controller: _concurrencyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.providerUploadConcurrencyLabel,
                        helperText: l10n.providerUploadConcurrencyHint,
                      ),
                      validator: _validConcurrency,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apiKeyController,
                    obscureText: !_apiKeyVisible,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: l10n.providerApiKeyLabel,
                      helperText: l10n.providerApiKeyHint,
                      suffixIcon: IconButton(
                        key: const Key('provider_api_key_visibility'),
                        tooltip: _apiKeyVisible ? '隐藏 API Key' : '显示 API Key',
                        onPressed: () =>
                            setState(() => _apiKeyVisible = !_apiKeyVisible),
                        icon: Icon(
                          _apiKeyVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _credentialsStored
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

  String? _positiveNumber(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number == null || number <= 0 ? '' : null;
  }

  String? _validConcurrency(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number == null || number < 1 || number > 4 ? '' : null;
  }

  static const _dashScopeModels = [
    'fun-asr',
    'fun-asr-2025-11-07',
    'fun-asr-2025-08-25',
    'fun-asr-mtl',
    'fun-asr-mtl-2025-08-25',
  ];

  static const _dashScopeFastFileModels = ['fun-asr-flash-2026-06-15'];

  static const _dashScopeRealtimeModels = [
    'fun-asr-realtime',
    'fun-asr-realtime-2026-02-28',
    'fun-asr-realtime-2025-11-07',
  ];
}
