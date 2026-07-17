// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'SekuxNote';

  @override
  String get tabRecords => '记录';

  @override
  String get tabHome => '首页';

  @override
  String get tabAssistant => 'AI 助手';

  @override
  String get tabSettings => '设置';

  @override
  String get startRecordingTooltip => '开始录音';

  @override
  String get recordsTitle => '记录';

  @override
  String get recordsEmptyTitle => '还没有录音';

  @override
  String get recordsEmptyBody => '录音与导入能力将在后续任务接入。现在可以从这里或录音入口开始。';

  @override
  String get recordsStartButton => '开始录音';

  @override
  String get homeRecentRecords => '最近记录';

  @override
  String get homeRecentRecordsBody => '展示最近 3 条录音或文件转写记录。';

  @override
  String get recordTitleSearchHint => '按标题搜索记录';

  @override
  String get recordTitleSearchClear => '清除搜索';

  @override
  String get recordTitleSearchEmpty => '没有匹配标题的记录。';

  @override
  String get assistantTitle => 'AI 助手';

  @override
  String get assistantHeadline => '文字 AI 工具';

  @override
  String get assistantBody => '通用对话与文档处理将在本仓实现。默认首页是「记录」，不是聊天。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAboutTitle => '关于 SekuxNote';

  @override
  String get settingsAboutSubtitle => '录音优先 · 本地优先 · BYOK';

  @override
  String get settingsAboutLegalese => '独立产品壳 · Task 1';

  @override
  String get settingsTranscriptionTitle => '语音转写服务';

  @override
  String get settingsTranscriptionSubtitle => '配置 OpenAI Audio、测试上传与单文件转写';

  @override
  String get settingsTextAiTitle => '文字 AI 服务';

  @override
  String get settingsTextAiSubtitle => '配置 Responses API 并测试连通性';

  @override
  String get settingsPrivacyTitle => '存储与隐私';

  @override
  String get settingsPrivacySubtitle => '用量、删除与备份 · 即将接入';

  @override
  String get recordingTitle => '录音';

  @override
  String get recordingPlaceholderHeadline => '录音能力即将接入';

  @override
  String get recordingPlaceholderBody =>
      '麦克风采集、分片落盘与转写将在 Task 0/3 后实现。此页仅作为产品入口占位，不会开始真实录音。';

  @override
  String get recordingBack => '返回';

  @override
  String get demoTaskTitle => '演示长任务';

  @override
  String demoTaskRunning(int seconds) {
    return '演示流式任务进行中 · $seconds 秒（切页不中断）';
  }

  @override
  String get demoTaskIdle => '启动假长任务以验证 FR-NAV-002/004 保活';

  @override
  String get demoTaskStart => '启动演示任务';

  @override
  String get demoTaskStop => '停止演示任务';

  @override
  String demoTaskBanner(int seconds) {
    return '后台演示任务 · $seconds 秒 · 点按打开 AI 助手';
  }

  @override
  String get keepAliveCounterLabel => '页内计数（IndexedStack 保活）';

  @override
  String get keepAliveIncrement => '加一';

  @override
  String get recordsTranscribeAudio => '转写音频文件';

  @override
  String get providerNameLabel => '供应商名称';

  @override
  String get providerBaseUrlLabel => 'Base URL';

  @override
  String get providerModelLabel => '模型';

  @override
  String get providerApiKeyLabel => 'API Key';

  @override
  String get providerApiKeyHint => '留空将保留已保存的 Key';

  @override
  String get providerEnabledLabel => '启用';

  @override
  String get providerCredentialSet => 'API Key 已安全保存';

  @override
  String get providerCredentialMissing => '尚未保存 API Key';

  @override
  String get providerSave => '保存配置';

  @override
  String get providerTestTextApi => '测试文字 API';

  @override
  String get providerTestTranscriptionApi => '用文件测试转写 API';

  @override
  String get providerTestNotice => '测试会发送一条很短的请求，并可能产生供应商用量。';

  @override
  String get providerTestRunning => '正在测试 API…';

  @override
  String get providerOpenWorkbench => '打开转写工作台';

  @override
  String get providerCapabilities => '批量转写、说话人标签与用量回报';

  @override
  String get providerTestResultTitle => 'API 测试结果';

  @override
  String get providerUsage => '用量';

  @override
  String get transcriptionWorkbenchTitle => '转写音频';

  @override
  String get transcriptionChooseFile => '选择音频文件';

  @override
  String get transcriptionNoFile => '尚未选择音频文件';

  @override
  String transcriptionSelectedFile(String name, String size) {
    return '已选择：$name · $size';
  }

  @override
  String get transcriptionConfirmTitle => '上传音频并转写？';

  @override
  String transcriptionConfirmBody(
    String name,
    String size,
    String provider,
    String model,
  ) {
    return '$name（$size）将发送至 $provider，使用 $model。这会产生一次转写 API 调用。';
  }

  @override
  String get transcriptionConfirmAction => '上传并转写';

  @override
  String get transcriptionUploading => '正在上传并转写…';

  @override
  String get providerChunkDurationLabel => '分片时长（秒）';

  @override
  String get providerChunkDurationHint => '音频会先按此时长切分再上传。';

  @override
  String get providerUploadConcurrencyLabel => '并发上传数';

  @override
  String get providerUploadConcurrencyHint => '同时发送 1–4 个请求，默认 2。';

  @override
  String get providerTranscriptionLanguageLabel => '转写语言';

  @override
  String get providerTranscriptionLanguageHint => 'ISO 639-1 代码，例如 zh 或 en。';

  @override
  String transcriptionTaskBanner(
    String fileName,
    int completedChunks,
    int totalChunks,
    int elapsedSeconds,
  ) {
    return '正在转写 $fileName · 分片 $completedChunks/$totalChunks · 已等待 $elapsedSeconds 秒';
  }

  @override
  String get transcriptionResultTitle => '转写结果';

  @override
  String get transcriptionCopy => '复制文本';

  @override
  String get transcriptionCopied => '已复制转写文本';

  @override
  String get transcriptionTaskFailedTitle => '转写任务失败';

  @override
  String get transcriptionTasksTitle => '转写任务';

  @override
  String get transcriptionTasksBody => '所有上传任务都会保留在这里，包括失败任务。';

  @override
  String get transcriptionTaskStatusLabel => '状态';

  @override
  String get transcriptionTaskChunkProgress => '分片进度';

  @override
  String get transcriptionTaskQueued => '排队中';

  @override
  String get transcriptionTaskRunning => '进行中';

  @override
  String get transcriptionTaskSucceeded => '已完成';

  @override
  String get transcriptionTaskFailed => '失败';

  @override
  String get transcriptionTaskStopped => '已停止';

  @override
  String get transcriptionTaskStop => '停止任务';

  @override
  String get transcriptionTaskRetry => '重试未完成分片';

  @override
  String get transcriptionTaskDelete => '删除记录';

  @override
  String get transcriptionTaskDeleteConfirmTitle => '删除转写记录？';

  @override
  String get transcriptionTaskDeleteConfirmBody => '将永久删除转写文本、任务状态及本地源音频。';

  @override
  String get transcriptionTaskDeleted => '已删除转写记录';

  @override
  String get providerErrorCredentialMissing => '请先保存 API Key。';

  @override
  String get providerErrorProviderDisabled => '请先启用此供应商。';

  @override
  String get providerErrorInvalidBaseUrl => '请输入有效的 Base URL。';

  @override
  String get providerErrorBadRequest => '供应商拒绝了请求参数（400）。请检查模型和音频格式。';

  @override
  String get providerErrorUnauthorized => '供应商拒绝了此 API Key（401）。';

  @override
  String get providerErrorForbidden => '供应商拒绝了此请求（403）。请检查 API Key 访问权限和账户状态。';

  @override
  String get providerErrorRateLimited => '已达到供应商限流（429），请稍后重试。';

  @override
  String get providerErrorTranscriptionTimedOut =>
      '转写在 10 分钟内未完成。请尝试更短的音频或稍后重试。';

  @override
  String get providerErrorUnavailable => '供应商暂时不可用，请稍后重试。';

  @override
  String get providerErrorAudioFileTooLarge => '音频文件必须小于 25 MB。';

  @override
  String get providerErrorInvalidAudioFile =>
      '这个 WAV 文件为空或已经损坏，请重新录音或选择有效的源文件。';

  @override
  String get providerErrorFilePickerPermission =>
      '应用没有打开所选文件的权限。请重新构建 macOS 应用后重试。';

  @override
  String get providerErrorInvalidResponse => '供应商返回了无法识别的响应。';

  @override
  String get providerErrorAudioChunkingUnavailable => '音频分片目前仅在 macOS 应用中可用。';

  @override
  String get providerErrorAudioChunkingFailed => '无法将音频切分为上传分片。';

  @override
  String get providerErrorTaskInterrupted => '应用在此转写完成前已关闭。';

  @override
  String get providerErrorSourceAudioMissing => '重试所需的导入音频已不可用。';

  @override
  String get providerErrorRequestFailed => 'API 请求失败，请检查配置和网络。';

  @override
  String get webDavTitle => 'WebDAV 配置同步';

  @override
  String get webDavSettingsSubtitle => '同步供应商配置和加密的 API Key';

  @override
  String get webDavServerUrl => '服务器地址';

  @override
  String get webDavUsername => '用户名';

  @override
  String get webDavPassword => '密码';

  @override
  String get webDavPasswordEncryptionHint => '同时用于加密远端文件中的 API Key。';

  @override
  String get webDavPasswordRequired => '请输入 WebDAV 密码，用于认证和配置加密。';

  @override
  String get webDavRemotePath => '远端目录';

  @override
  String get webDavSyncScopeTitle => '同步范围';

  @override
  String get webDavSyncScopeBody =>
      '包含文字 AI、语音转写供应商配置及 API Key；不包含录音、记录、转写结果、任务、总结和 AI 对话。';

  @override
  String get webDavRemoteNotFound => '远端还没有配置文件。';

  @override
  String webDavRemoteUpdatedAt(String time) {
    return '远端配置更新时间：$time';
  }

  @override
  String get webDavTestConnection => '测试连接';

  @override
  String get webDavTestSucceeded => 'WebDAV 连接成功';

  @override
  String get webDavUpload => '上传本机配置';

  @override
  String get webDavUploadSucceeded => '配置已上传';

  @override
  String get webDavDownload => '下载远端配置';

  @override
  String get webDavDownloadConfirmTitle => '覆盖本机供应商配置？';

  @override
  String get webDavDownloadConfirmBody =>
      '本机供应商设置和 API Key 将被加密的远端配置覆盖。录音、记录和 AI 对话不会受影响。';

  @override
  String get webDavDownloadAction => '下载并覆盖';

  @override
  String get webDavDownloadSucceeded => '远端配置已应用';

  @override
  String get webDavCancel => '取消';

  @override
  String get webDavInvalidUrl => '请输入有效的 HTTP 或 HTTPS WebDAV 地址。';

  @override
  String get webDavRemoteMissing => '远端配置文件尚不存在。';

  @override
  String webDavRequestFailed(String detail) {
    return 'WebDAV 请求失败：$detail';
  }

  @override
  String get webDavDecryptOrFormatFailed =>
      '无法解密远端文件，或文件不是有效的 SekuxNote 配置。请检查 WebDAV 密码。';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appName => 'SekuxNote';

  @override
  String get tabRecords => '记录';

  @override
  String get tabHome => '首页';

  @override
  String get tabAssistant => 'AI 助手';

  @override
  String get tabSettings => '设置';

  @override
  String get startRecordingTooltip => '开始录音';

  @override
  String get recordsTitle => '记录';

  @override
  String get recordsEmptyTitle => '还没有录音';

  @override
  String get recordsEmptyBody => '录音与导入能力将在后续任务接入。现在可以从这里或录音入口开始。';

  @override
  String get recordsStartButton => '开始录音';

  @override
  String get homeRecentRecords => '最近记录';

  @override
  String get homeRecentRecordsBody => '展示最近 3 条录音或文件转写记录。';

  @override
  String get recordTitleSearchHint => '按标题搜索记录';

  @override
  String get recordTitleSearchClear => '清除搜索';

  @override
  String get recordTitleSearchEmpty => '没有匹配标题的记录。';

  @override
  String get assistantTitle => 'AI 助手';

  @override
  String get assistantHeadline => '文字 AI 工具';

  @override
  String get assistantBody => '通用对话与文档处理将在本仓实现。默认首页是「记录」，不是聊天。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAboutTitle => '关于 SekuxNote';

  @override
  String get settingsAboutSubtitle => '录音优先 · 本地优先 · BYOK';

  @override
  String get settingsAboutLegalese => '独立产品壳 · Task 1';

  @override
  String get settingsTranscriptionTitle => '语音转写服务';

  @override
  String get settingsTranscriptionSubtitle => '配置 OpenAI Audio、测试上传与单文件转写';

  @override
  String get settingsTextAiTitle => '文字 AI 服务';

  @override
  String get settingsTextAiSubtitle => '配置 Responses API 并测试连通性';

  @override
  String get settingsPrivacyTitle => '存储与隐私';

  @override
  String get settingsPrivacySubtitle => '用量、删除与备份 · 即将接入';

  @override
  String get recordingTitle => '录音';

  @override
  String get recordingPlaceholderHeadline => '录音能力即将接入';

  @override
  String get recordingPlaceholderBody =>
      '麦克风采集、分片落盘与转写将在 Task 0/3 后实现。此页仅作为产品入口占位，不会开始真实录音。';

  @override
  String get recordingBack => '返回';

  @override
  String get demoTaskTitle => '演示长任务';

  @override
  String demoTaskRunning(int seconds) {
    return '演示流式任务进行中 · $seconds 秒（切页不中断）';
  }

  @override
  String get demoTaskIdle => '启动假长任务以验证 FR-NAV-002/004 保活';

  @override
  String get demoTaskStart => '启动演示任务';

  @override
  String get demoTaskStop => '停止演示任务';

  @override
  String demoTaskBanner(int seconds) {
    return '后台演示任务 · $seconds 秒 · 点按打开 AI 助手';
  }

  @override
  String get keepAliveCounterLabel => '页内计数（IndexedStack 保活）';

  @override
  String get keepAliveIncrement => '加一';

  @override
  String get recordsTranscribeAudio => '转写音频文件';

  @override
  String get providerNameLabel => '供应商名称';

  @override
  String get providerBaseUrlLabel => 'Base URL';

  @override
  String get providerModelLabel => '模型';

  @override
  String get providerApiKeyLabel => 'API Key';

  @override
  String get providerApiKeyHint => '留空将保留已保存的 Key';

  @override
  String get providerEnabledLabel => '启用';

  @override
  String get providerCredentialSet => 'API Key 已安全保存';

  @override
  String get providerCredentialMissing => '尚未保存 API Key';

  @override
  String get providerSave => '保存配置';

  @override
  String get providerTestTextApi => '测试文字 API';

  @override
  String get providerTestTranscriptionApi => '用文件测试转写 API';

  @override
  String get providerTestNotice => '测试会发送一条很短的请求，并可能产生供应商用量。';

  @override
  String get providerTestRunning => '正在测试 API…';

  @override
  String get providerOpenWorkbench => '打开转写工作台';

  @override
  String get providerCapabilities => '批量转写、说话人标签与用量回报';

  @override
  String get providerTestResultTitle => 'API 测试结果';

  @override
  String get providerUsage => '用量';

  @override
  String get transcriptionWorkbenchTitle => '转写音频';

  @override
  String get transcriptionChooseFile => '选择音频文件';

  @override
  String get transcriptionNoFile => '尚未选择音频文件';

  @override
  String transcriptionSelectedFile(String name, String size) {
    return '已选择：$name · $size';
  }

  @override
  String get transcriptionConfirmTitle => '上传音频并转写？';

  @override
  String transcriptionConfirmBody(
    String name,
    String size,
    String provider,
    String model,
  ) {
    return '$name（$size）将发送至 $provider，使用 $model。这会产生一次转写 API 调用。';
  }

  @override
  String get transcriptionConfirmAction => '上传并转写';

  @override
  String get transcriptionUploading => '正在上传并转写…';

  @override
  String get providerChunkDurationLabel => '分片时长（秒）';

  @override
  String get providerChunkDurationHint => '音频会先按此时长切分再上传。';

  @override
  String get providerUploadConcurrencyLabel => '并发上传数';

  @override
  String get providerUploadConcurrencyHint => '同时发送 1–4 个请求，默认 2。';

  @override
  String get providerTranscriptionLanguageLabel => '转写语言';

  @override
  String get providerTranscriptionLanguageHint => 'ISO 639-1 代码，例如 zh 或 en。';

  @override
  String transcriptionTaskBanner(
    String fileName,
    int completedChunks,
    int totalChunks,
    int elapsedSeconds,
  ) {
    return '正在转写 $fileName · 分片 $completedChunks/$totalChunks · 已等待 $elapsedSeconds 秒';
  }

  @override
  String get transcriptionResultTitle => '转写结果';

  @override
  String get transcriptionCopy => '复制文本';

  @override
  String get transcriptionCopied => '已复制转写文本';

  @override
  String get transcriptionTaskFailedTitle => '转写任务失败';

  @override
  String get transcriptionTasksTitle => '转写任务';

  @override
  String get transcriptionTasksBody => '所有上传任务都会保留在这里，包括失败任务。';

  @override
  String get transcriptionTaskStatusLabel => '状态';

  @override
  String get transcriptionTaskChunkProgress => '分片进度';

  @override
  String get transcriptionTaskQueued => '排队中';

  @override
  String get transcriptionTaskRunning => '进行中';

  @override
  String get transcriptionTaskSucceeded => '已完成';

  @override
  String get transcriptionTaskFailed => '失败';

  @override
  String get transcriptionTaskStopped => '已停止';

  @override
  String get transcriptionTaskStop => '停止任务';

  @override
  String get transcriptionTaskRetry => '重试未完成分片';

  @override
  String get transcriptionTaskDelete => '删除记录';

  @override
  String get transcriptionTaskDeleteConfirmTitle => '删除转写记录？';

  @override
  String get transcriptionTaskDeleteConfirmBody => '将永久删除转写文本、任务状态及本地源音频。';

  @override
  String get transcriptionTaskDeleted => '已删除转写记录';

  @override
  String get providerErrorCredentialMissing => '请先保存 API Key。';

  @override
  String get providerErrorProviderDisabled => '请先启用此供应商。';

  @override
  String get providerErrorInvalidBaseUrl => '请输入有效的 Base URL。';

  @override
  String get providerErrorBadRequest => '供应商拒绝了请求参数（400）。请检查模型和音频格式。';

  @override
  String get providerErrorUnauthorized => '供应商拒绝了此 API Key（401）。';

  @override
  String get providerErrorForbidden => '供应商拒绝了此请求（403）。请检查 API Key 访问权限和账户状态。';

  @override
  String get providerErrorRateLimited => '已达到供应商限流（429），请稍后重试。';

  @override
  String get providerErrorTranscriptionTimedOut =>
      '转写在 10 分钟内未完成。请尝试更短的音频或稍后重试。';

  @override
  String get providerErrorUnavailable => '供应商暂时不可用，请稍后重试。';

  @override
  String get providerErrorAudioFileTooLarge => '音频文件必须小于 25 MB。';

  @override
  String get providerErrorInvalidAudioFile =>
      '这个 WAV 文件为空或已经损坏，请重新录音或选择有效的源文件。';

  @override
  String get providerErrorFilePickerPermission =>
      '应用没有打开所选文件的权限。请重新构建 macOS 应用后重试。';

  @override
  String get providerErrorInvalidResponse => '供应商返回了无法识别的响应。';

  @override
  String get providerErrorAudioChunkingUnavailable => '音频分片目前仅在 macOS 应用中可用。';

  @override
  String get providerErrorAudioChunkingFailed => '无法将音频切分为上传分片。';

  @override
  String get providerErrorTaskInterrupted => '应用在此转写完成前已关闭。';

  @override
  String get providerErrorSourceAudioMissing => '重试所需的导入音频已不可用。';

  @override
  String get providerErrorRequestFailed => 'API 请求失败，请检查配置和网络。';

  @override
  String get webDavTitle => 'WebDAV 配置同步';

  @override
  String get webDavSettingsSubtitle => '同步供应商配置和加密的 API Key';

  @override
  String get webDavServerUrl => '服务器地址';

  @override
  String get webDavUsername => '用户名';

  @override
  String get webDavPassword => '密码';

  @override
  String get webDavPasswordEncryptionHint => '同时用于加密远端文件中的 API Key。';

  @override
  String get webDavPasswordRequired => '请输入 WebDAV 密码，用于认证和配置加密。';

  @override
  String get webDavRemotePath => '远端目录';

  @override
  String get webDavSyncScopeTitle => '同步范围';

  @override
  String get webDavSyncScopeBody =>
      '包含文字 AI、语音转写供应商配置及 API Key；不包含录音、记录、转写结果、任务、总结和 AI 对话。';

  @override
  String get webDavRemoteNotFound => '远端还没有配置文件。';

  @override
  String webDavRemoteUpdatedAt(String time) {
    return '远端配置更新时间：$time';
  }

  @override
  String get webDavTestConnection => '测试连接';

  @override
  String get webDavTestSucceeded => 'WebDAV 连接成功';

  @override
  String get webDavUpload => '上传本机配置';

  @override
  String get webDavUploadSucceeded => '配置已上传';

  @override
  String get webDavDownload => '下载远端配置';

  @override
  String get webDavDownloadConfirmTitle => '覆盖本机供应商配置？';

  @override
  String get webDavDownloadConfirmBody =>
      '本机供应商设置和 API Key 将被加密的远端配置覆盖。录音、记录和 AI 对话不会受影响。';

  @override
  String get webDavDownloadAction => '下载并覆盖';

  @override
  String get webDavDownloadSucceeded => '远端配置已应用';

  @override
  String get webDavCancel => '取消';

  @override
  String get webDavInvalidUrl => '请输入有效的 HTTP 或 HTTPS WebDAV 地址。';

  @override
  String get webDavRemoteMissing => '远端配置文件尚不存在。';

  @override
  String webDavRequestFailed(String detail) {
    return 'WebDAV 请求失败：$detail';
  }

  @override
  String get webDavDecryptOrFormatFailed =>
      '无法解密远端文件，或文件不是有效的 SekuxNote 配置。请检查 WebDAV 密码。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appName => 'SekuxNote';

  @override
  String get tabRecords => '記錄';

  @override
  String get tabHome => '首頁';

  @override
  String get tabAssistant => 'AI 助手';

  @override
  String get tabSettings => '設定';

  @override
  String get startRecordingTooltip => '開始錄音';

  @override
  String get recordsTitle => '記錄';

  @override
  String get recordsEmptyTitle => '還沒有錄音';

  @override
  String get recordsEmptyBody => '錄音與匯入能力將在後續任務接入。現在可以從這裡或錄音入口開始。';

  @override
  String get recordsStartButton => '開始錄音';

  @override
  String get homeRecentRecords => '最近記錄';

  @override
  String get homeRecentRecordsBody => '顯示最近 3 筆錄音或檔案轉寫記錄。';

  @override
  String get recordTitleSearchHint => '依標題搜尋記錄';

  @override
  String get recordTitleSearchClear => '清除搜尋';

  @override
  String get recordTitleSearchEmpty => '沒有符合標題的記錄。';

  @override
  String get assistantTitle => 'AI 助手';

  @override
  String get assistantHeadline => '文字 AI 工具';

  @override
  String get assistantBody => '通用對話與文件處理將在本倉實作。預設首頁是「記錄」，不是聊天。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsAboutTitle => '關於 SekuxNote';

  @override
  String get settingsAboutSubtitle => '錄音優先 · 本地優先 · BYOK';

  @override
  String get settingsAboutLegalese => '獨立產品殼 · Task 1';

  @override
  String get settingsTranscriptionTitle => '語音轉寫服務';

  @override
  String get settingsTranscriptionSubtitle => '設定 OpenAI Audio、測試上傳與單檔轉寫';

  @override
  String get settingsTextAiTitle => '文字 AI 服務';

  @override
  String get settingsTextAiSubtitle => '設定 Responses API 並測試連通性';

  @override
  String get settingsPrivacyTitle => '儲存與隱私';

  @override
  String get settingsPrivacySubtitle => '用量、刪除與備份 · 即將接入';

  @override
  String get recordingTitle => '錄音';

  @override
  String get recordingPlaceholderHeadline => '錄音能力即將接入';

  @override
  String get recordingPlaceholderBody =>
      '麥克風擷取、分片落盤與轉寫將在 Task 0/3 後實作。此頁僅作為產品入口佔位，不會開始真實錄音。';

  @override
  String get recordingBack => '返回';

  @override
  String get demoTaskTitle => '示範長任務';

  @override
  String demoTaskRunning(int seconds) {
    return '示範串流任務進行中 · $seconds 秒（切頁不中斷）';
  }

  @override
  String get demoTaskIdle => '啟動假長任務以驗證 FR-NAV-002/004 保活';

  @override
  String get demoTaskStart => '啟動示範任務';

  @override
  String get demoTaskStop => '停止示範任務';

  @override
  String demoTaskBanner(int seconds) {
    return '背景示範任務 · $seconds 秒 · 點按開啟 AI 助手';
  }

  @override
  String get keepAliveCounterLabel => '頁內計數（IndexedStack 保活）';

  @override
  String get keepAliveIncrement => '加一';

  @override
  String get recordsTranscribeAudio => '轉寫音訊檔案';

  @override
  String get providerNameLabel => '供應商名稱';

  @override
  String get providerBaseUrlLabel => 'Base URL';

  @override
  String get providerModelLabel => '模型';

  @override
  String get providerApiKeyLabel => 'API Key';

  @override
  String get providerApiKeyHint => '留空會保留已儲存的 Key';

  @override
  String get providerEnabledLabel => '啟用';

  @override
  String get providerCredentialSet => 'API Key 已安全儲存';

  @override
  String get providerCredentialMissing => '尚未儲存 API Key';

  @override
  String get providerSave => '儲存設定';

  @override
  String get providerTestTextApi => '測試文字 API';

  @override
  String get providerTestTranscriptionApi => '用檔案測試轉寫 API';

  @override
  String get providerTestNotice => '測試會傳送一個很短的請求，且可能產生供應商用量。';

  @override
  String get providerTestRunning => '正在測試 API…';

  @override
  String get providerOpenWorkbench => '開啟轉寫工作台';

  @override
  String get providerCapabilities => '批次轉寫、說話人標籤與用量回報';

  @override
  String get providerTestResultTitle => 'API 測試結果';

  @override
  String get providerUsage => '用量';

  @override
  String get transcriptionWorkbenchTitle => '轉寫音訊';

  @override
  String get transcriptionChooseFile => '選擇音訊檔案';

  @override
  String get transcriptionNoFile => '尚未選擇音訊檔案';

  @override
  String transcriptionSelectedFile(String name, String size) {
    return '已選擇：$name · $size';
  }

  @override
  String get transcriptionConfirmTitle => '上傳音訊並轉寫？';

  @override
  String transcriptionConfirmBody(
    String name,
    String size,
    String provider,
    String model,
  ) {
    return '$name（$size）將傳送至 $provider，使用 $model。這會產生一次轉寫 API 呼叫。';
  }

  @override
  String get transcriptionConfirmAction => '上傳並轉寫';

  @override
  String get transcriptionUploading => '正在上傳並轉寫…';

  @override
  String get providerChunkDurationLabel => '分片時長（秒）';

  @override
  String get providerChunkDurationHint => '音訊會先依此時長切分再上傳。';

  @override
  String get providerUploadConcurrencyLabel => '並發上傳數';

  @override
  String get providerUploadConcurrencyHint => '同時傳送 1–4 個請求，預設 2。';

  @override
  String get providerTranscriptionLanguageLabel => '轉寫語言';

  @override
  String get providerTranscriptionLanguageHint => 'ISO 639-1 代碼，例如 zh 或 en。';

  @override
  String transcriptionTaskBanner(
    String fileName,
    int completedChunks,
    int totalChunks,
    int elapsedSeconds,
  ) {
    return '正在轉寫 $fileName · 分片 $completedChunks/$totalChunks · 已等待 $elapsedSeconds 秒';
  }

  @override
  String get transcriptionResultTitle => '轉寫結果';

  @override
  String get transcriptionCopy => '複製文字';

  @override
  String get transcriptionCopied => '已複製轉寫文字';

  @override
  String get transcriptionTaskFailedTitle => '轉寫任務失敗';

  @override
  String get transcriptionTasksTitle => '轉寫任務';

  @override
  String get transcriptionTasksBody => '所有上傳任務都會保留在這裡，包括失敗任務。';

  @override
  String get transcriptionTaskStatusLabel => '狀態';

  @override
  String get transcriptionTaskChunkProgress => '分片進度';

  @override
  String get transcriptionTaskQueued => '排隊中';

  @override
  String get transcriptionTaskRunning => '進行中';

  @override
  String get transcriptionTaskSucceeded => '已完成';

  @override
  String get transcriptionTaskFailed => '失敗';

  @override
  String get transcriptionTaskStopped => '已停止';

  @override
  String get transcriptionTaskStop => '停止任務';

  @override
  String get transcriptionTaskRetry => '重試未完成分片';

  @override
  String get transcriptionTaskDelete => '刪除記錄';

  @override
  String get transcriptionTaskDeleteConfirmTitle => '刪除轉寫記錄？';

  @override
  String get transcriptionTaskDeleteConfirmBody => '將永久刪除轉寫文字、任務狀態及本機來源音訊。';

  @override
  String get transcriptionTaskDeleted => '已刪除轉寫記錄';

  @override
  String get providerErrorCredentialMissing => '請先儲存 API Key。';

  @override
  String get providerErrorProviderDisabled => '請先啟用此供應商。';

  @override
  String get providerErrorInvalidBaseUrl => '請輸入有效的 Base URL。';

  @override
  String get providerErrorBadRequest => '供應商拒絕了請求參數（400）。請檢查模型和音訊格式。';

  @override
  String get providerErrorUnauthorized => '供應商拒絕了此 API Key（401）。';

  @override
  String get providerErrorForbidden => '供應商拒絕了此請求（403）。請檢查 API Key 存取權限和帳戶狀態。';

  @override
  String get providerErrorRateLimited => '已達到供應商限流（429），請稍後重試。';

  @override
  String get providerErrorTranscriptionTimedOut =>
      '轉寫在 10 分鐘內未完成。請嘗試更短的音訊或稍後重試。';

  @override
  String get providerErrorUnavailable => '供應商暫時無法使用，請稍後重試。';

  @override
  String get providerErrorAudioFileTooLarge => '音訊檔案必須小於 25 MB。';

  @override
  String get providerErrorInvalidAudioFile =>
      '這個 WAV 檔案為空或已經損壞，請重新錄音或選擇有效的來源檔案。';

  @override
  String get providerErrorFilePickerPermission =>
      '應用程式沒有開啟所選檔案的權限。請重新建置 macOS 應用程式後再試。';

  @override
  String get providerErrorInvalidResponse => '供應商回傳了無法辨識的回應。';

  @override
  String get providerErrorAudioChunkingUnavailable => '音訊分片目前僅在 macOS 應用程式中可用。';

  @override
  String get providerErrorAudioChunkingFailed => '無法將音訊切分為上傳分片。';

  @override
  String get providerErrorTaskInterrupted => '應用程式在此轉寫完成前已關閉。';

  @override
  String get providerErrorSourceAudioMissing => '重試所需的匯入音訊已不可用。';

  @override
  String get providerErrorRequestFailed => 'API 請求失敗，請檢查設定與網路。';

  @override
  String get webDavTitle => 'WebDAV 設定同步';

  @override
  String get webDavSettingsSubtitle => '同步供應商設定和加密的 API Key';

  @override
  String get webDavServerUrl => '伺服器地址';

  @override
  String get webDavUsername => '使用者名稱';

  @override
  String get webDavPassword => '密碼';

  @override
  String get webDavPasswordEncryptionHint => '同時用於加密遠端檔案中的 API Key。';

  @override
  String get webDavPasswordRequired => '請輸入 WebDAV 密碼，用於認證和設定加密。';

  @override
  String get webDavRemotePath => '遠端目錄';

  @override
  String get webDavSyncScopeTitle => '同步範圍';

  @override
  String get webDavSyncScopeBody =>
      '包含文字 AI、語音轉寫供應商設定及 API Key；不包含錄音、記錄、轉寫結果、任務、摘要和 AI 對話。';

  @override
  String get webDavRemoteNotFound => '遠端還沒有設定檔。';

  @override
  String webDavRemoteUpdatedAt(String time) {
    return '遠端設定更新時間：$time';
  }

  @override
  String get webDavTestConnection => '測試連線';

  @override
  String get webDavTestSucceeded => 'WebDAV 連線成功';

  @override
  String get webDavUpload => '上傳本機設定';

  @override
  String get webDavUploadSucceeded => '設定已上傳';

  @override
  String get webDavDownload => '下載遠端設定';

  @override
  String get webDavDownloadConfirmTitle => '覆蓋本機供應商設定？';

  @override
  String get webDavDownloadConfirmBody =>
      '本機供應商設定和 API Key 將被加密的遠端設定覆蓋。錄音、記錄和 AI 對話不會受影響。';

  @override
  String get webDavDownloadAction => '下載並覆蓋';

  @override
  String get webDavDownloadSucceeded => '遠端設定已套用';

  @override
  String get webDavCancel => '取消';

  @override
  String get webDavInvalidUrl => '請輸入有效的 HTTP 或 HTTPS WebDAV 地址。';

  @override
  String get webDavRemoteMissing => '遠端設定檔尚不存在。';

  @override
  String webDavRequestFailed(String detail) {
    return 'WebDAV 請求失敗：$detail';
  }

  @override
  String get webDavDecryptOrFormatFailed =>
      '無法解密遠端檔案，或檔案不是有效的 SekuxNote 設定。請檢查 WebDAV 密碼。';
}
