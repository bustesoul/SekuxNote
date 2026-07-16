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
  String get tabAssistant => 'AI 助手';

  @override
  String get tabSearch => '搜索';

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
  String get assistantTitle => 'AI 助手';

  @override
  String get assistantHeadline => '文字 AI 工具';

  @override
  String get assistantBody => '通用对话与文档处理将在本仓实现。默认首页是「记录」，不是聊天。';

  @override
  String get searchTitle => '搜索';

  @override
  String get searchHeadline => '搜索记录与转写';

  @override
  String get searchBody => '本地搜索将在有记录数据后接入。';

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
  String get transcriptionResultTitle => '转写结果';

  @override
  String get transcriptionCopy => '复制文本';

  @override
  String get transcriptionCopied => '已复制转写文本';

  @override
  String get providerErrorCredentialMissing => '请先保存 API Key。';

  @override
  String get providerErrorProviderDisabled => '请先启用此供应商。';

  @override
  String get providerErrorInvalidBaseUrl => '请输入有效的 Base URL。';

  @override
  String get providerErrorUnauthorized => '供应商拒绝了此 API Key（401）。';

  @override
  String get providerErrorRateLimited => '已达到供应商限流（429），请稍后重试。';

  @override
  String get providerErrorUnavailable => '供应商暂时不可用，请稍后重试。';

  @override
  String get providerErrorAudioFileTooLarge => '音频文件必须小于 25 MB。';

  @override
  String get providerErrorInvalidResponse => '供应商返回了无法识别的响应。';

  @override
  String get providerErrorRequestFailed => 'API 请求失败，请检查配置和网络。';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appName => 'SekuxNote';

  @override
  String get tabRecords => '记录';

  @override
  String get tabAssistant => 'AI 助手';

  @override
  String get tabSearch => '搜索';

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
  String get assistantTitle => 'AI 助手';

  @override
  String get assistantHeadline => '文字 AI 工具';

  @override
  String get assistantBody => '通用对话与文档处理将在本仓实现。默认首页是「记录」，不是聊天。';

  @override
  String get searchTitle => '搜索';

  @override
  String get searchHeadline => '搜索记录与转写';

  @override
  String get searchBody => '本地搜索将在有记录数据后接入。';

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
  String get transcriptionResultTitle => '转写结果';

  @override
  String get transcriptionCopy => '复制文本';

  @override
  String get transcriptionCopied => '已复制转写文本';

  @override
  String get providerErrorCredentialMissing => '请先保存 API Key。';

  @override
  String get providerErrorProviderDisabled => '请先启用此供应商。';

  @override
  String get providerErrorInvalidBaseUrl => '请输入有效的 Base URL。';

  @override
  String get providerErrorUnauthorized => '供应商拒绝了此 API Key（401）。';

  @override
  String get providerErrorRateLimited => '已达到供应商限流（429），请稍后重试。';

  @override
  String get providerErrorUnavailable => '供应商暂时不可用，请稍后重试。';

  @override
  String get providerErrorAudioFileTooLarge => '音频文件必须小于 25 MB。';

  @override
  String get providerErrorInvalidResponse => '供应商返回了无法识别的响应。';

  @override
  String get providerErrorRequestFailed => 'API 请求失败，请检查配置和网络。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appName => 'SekuxNote';

  @override
  String get tabRecords => '記錄';

  @override
  String get tabAssistant => 'AI 助手';

  @override
  String get tabSearch => '搜尋';

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
  String get assistantTitle => 'AI 助手';

  @override
  String get assistantHeadline => '文字 AI 工具';

  @override
  String get assistantBody => '通用對話與文件處理將在本倉實作。預設首頁是「記錄」，不是聊天。';

  @override
  String get searchTitle => '搜尋';

  @override
  String get searchHeadline => '搜尋記錄與轉寫';

  @override
  String get searchBody => '本地搜尋將在有記錄資料後接入。';

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
  String get transcriptionResultTitle => '轉寫結果';

  @override
  String get transcriptionCopy => '複製文字';

  @override
  String get transcriptionCopied => '已複製轉寫文字';

  @override
  String get providerErrorCredentialMissing => '請先儲存 API Key。';

  @override
  String get providerErrorProviderDisabled => '請先啟用此供應商。';

  @override
  String get providerErrorInvalidBaseUrl => '請輸入有效的 Base URL。';

  @override
  String get providerErrorUnauthorized => '供應商拒絕了此 API Key（401）。';

  @override
  String get providerErrorRateLimited => '已達到供應商限流（429），請稍後重試。';

  @override
  String get providerErrorUnavailable => '供應商暫時無法使用，請稍後重試。';

  @override
  String get providerErrorAudioFileTooLarge => '音訊檔案必須小於 25 MB。';

  @override
  String get providerErrorInvalidResponse => '供應商回傳了無法辨識的回應。';

  @override
  String get providerErrorRequestFailed => 'API 請求失敗，請檢查設定與網路。';
}
