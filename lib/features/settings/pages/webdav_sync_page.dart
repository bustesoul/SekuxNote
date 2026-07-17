import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/provider_controller.dart';
import '../webdav_config_sync.dart';

class WebDavSyncPage extends StatefulWidget {
  const WebDavSyncPage({
    super.key,
    required this.providerController,
    this.settingsStore,
    this.client,
    this.codec,
  });

  final ProviderController providerController;
  final WebDavSyncSettingsStore? settingsStore;
  final WebDavConfigSyncClient? client;
  final ConfigurationSyncCodec? codec;

  @override
  State<WebDavSyncPage> createState() => _WebDavSyncPageState();
}

class _WebDavSyncPageState extends State<WebDavSyncPage> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pathController = TextEditingController();

  late final WebDavConfigSyncClient _client;
  late final ConfigurationSyncCodec _codec;
  WebDavSyncSettingsStore? _store;
  bool _loading = true;
  bool _busy = false;
  bool _showPassword = false;
  DateTime? _remoteModifiedAt;

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? WebDavConfigSyncClient();
    _codec = widget.codec ?? ConfigurationSyncCodec();
    _load();
  }

  Future<void> _load() async {
    final store =
        widget.settingsStore ?? await FileWebDavSyncSettingsStore.open();
    final settings = await store.read();
    if (!mounted) return;
    _store = store;
    _urlController.text = settings.url;
    _usernameController.text = settings.username;
    _passwordController.text = settings.password;
    _pathController.text = settings.remotePath;
    setState(() => _loading = false);
    if (settings.url.isNotEmpty && settings.password.isNotEmpty) {
      await _run(
        () => _refreshRemoteModifiedAt(settings),
        showSuccess: false,
        showError: false,
      );
    }
  }

  WebDavSyncSettings get _settings => WebDavSyncSettings(
    url: _urlController.text.trim(),
    username: _usernameController.text.trim(),
    password: _passwordController.text,
    remotePath: _pathController.text.trim().isEmpty
        ? 'sekuxnote/config'
        : _pathController.text.trim(),
  );

  Future<void> _save() async {
    await _store!.write(_settings);
  }

  Future<void> _testConnection() async {
    await _run(() async {
      await _save();
      await _client.test(_settings);
      await _refreshRemoteModifiedAt(_settings);
    }, successMessage: AppLocalizations.of(context).webDavTestSucceeded);
  }

  Future<void> _upload() async {
    await _run(() async {
      await _save();
      final snapshot = await widget.providerController
          .exportConfigurationSnapshot();
      final encrypted = await _codec.encode(
        snapshot,
        password: _settings.password,
      );
      await _client.upload(_settings, encrypted);
      _remoteModifiedAt = DateTime.now();
      await _refreshRemoteModifiedAt(_settings, keepExisting: true);
    }, successMessage: AppLocalizations.of(context).webDavUploadSucceeded);
  }

  Future<void> _download() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.webDavDownloadConfirmTitle),
        content: Text(l10n.webDavDownloadConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.webDavCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.webDavDownloadAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      await _save();
      final encrypted = await _client.download(_settings);
      final snapshot = await _codec.decode(
        encrypted,
        password: _settings.password,
      );
      await widget.providerController.importConfigurationSnapshot(snapshot);
      await _refreshRemoteModifiedAt(_settings, keepExisting: true);
    }, successMessage: l10n.webDavDownloadSucceeded);
  }

  Future<void> _refreshRemoteModifiedAt(
    WebDavSyncSettings settings, {
    bool keepExisting = false,
  }) async {
    try {
      final modified = await _client.remoteModifiedAt(settings);
      if (modified != null || !keepExisting) _remoteModifiedAt = modified;
    } catch (_) {
      // HEAD is optional on some WebDAV servers. It must never turn a
      // successful connection, upload or import into a reported failure.
    }
  }

  Future<void> _run(
    Future<void> Function() action, {
    String? successMessage,
    bool showSuccess = true,
    bool showError = true,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      setState(() {});
      if (showSuccess && successMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error) {
      if (!mounted || !showError) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errorMessage(Object error) {
    final l10n = AppLocalizations.of(context);
    if (error is WebDavSyncException) {
      return switch (error.code) {
        'invalidUrl' => l10n.webDavInvalidUrl,
        'passwordRequired' => l10n.webDavPasswordRequired,
        'remoteConfigurationMissing' => l10n.webDavRemoteMissing,
        _ => l10n.webDavRequestFailed(error.toString()),
      };
    }
    if (error is ArgumentError && error.name == 'password') {
      return l10n.webDavPasswordRequired;
    }
    return l10n.webDavDecryptOrFormatFailed;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pathController.dispose();
    if (widget.client == null) _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.webDavTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  key: const Key('webdav_url'),
                  controller: _urlController,
                  enabled: !_busy,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: l10n.webDavServerUrl,
                    hintText: 'https://example.com/dav',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('webdav_username'),
                  controller: _usernameController,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: l10n.webDavUsername,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('webdav_password'),
                  controller: _passwordController,
                  enabled: !_busy,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: l10n.webDavPassword,
                    helperText: l10n.webDavPasswordEncryptionHint,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      key: const Key('webdav_password_visibility'),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('webdav_remote_path'),
                  controller: _pathController,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: l10n.webDavRemotePath,
                    hintText: 'sekuxnote/config',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.webDavSyncScopeTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(l10n.webDavSyncScopeBody),
                        const SizedBox(height: 8),
                        Text(
                          _remoteModifiedAt == null
                              ? l10n.webDavRemoteNotFound
                              : l10n.webDavRemoteUpdatedAt(
                                  DateFormat.yMd(
                                    Localizations.localeOf(context).toString(),
                                  ).add_Hm().format(_remoteModifiedAt!),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('webdav_test'),
                  onPressed: _busy ? null : _testConnection,
                  icon: const Icon(Icons.wifi_tethering),
                  label: Text(l10n.webDavTestConnection),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('webdav_upload'),
                  onPressed: _busy ? null : _upload,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(l10n.webDavUpload),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('webdav_download'),
                  onPressed: _busy ? null : _download,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: Text(l10n.webDavDownload),
                ),
                if (_busy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
    );
  }
}
