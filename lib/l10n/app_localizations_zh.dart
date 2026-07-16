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
  String get settingsTranscriptionSubtitle =>
      'TranscriptionProviderConfig · 即将接入';

  @override
  String get settingsTextAiTitle => '文字 AI 服务';

  @override
  String get settingsTextAiSubtitle => '本仓 Provider 配置 · 即将接入';

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
  String get settingsTranscriptionSubtitle =>
      'TranscriptionProviderConfig · 即将接入';

  @override
  String get settingsTextAiTitle => '文字 AI 服务';

  @override
  String get settingsTextAiSubtitle => '本仓 Provider 配置 · 即将接入';

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
  String get settingsTranscriptionSubtitle =>
      'TranscriptionProviderConfig · 即將接入';

  @override
  String get settingsTextAiTitle => '文字 AI 服務';

  @override
  String get settingsTextAiSubtitle => '本倉 Provider 設定 · 即將接入';

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
}
