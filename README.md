# SekuxNote

本地优先的 AI 语音记录与会议整理工具（录音优先；独立实现，非聊天客户端改皮）。

## 开发

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos
```

当前进度：**Task 1 AppShell 工程完成** — 冷启动进入「记录」、四个一级入口、四份 ARB、`AppSessionController` 演示长任务保活、平台显示名 `SekuxNote`。

已新增最小的 BYOK 验证闭环：文字 AI 与语音转写配置分离、文字 API 显式测试，以及 macOS 音频文件转写。供应商配置、API Key（按当前本地 SQLite 存储决策）和转写任务会持久化；转写失败也保留状态与错误。小于 25 MB 的文件以单请求保留完整上下文并保存带时间戳的文本段；超限文件才按可配置时长（默认 60 秒）分片上传，并发数默认 2（可在语音转写设置中改为 1–4）。每个分片首次请求后最多自动重试 3 次；失败/停止任务可在记录库中重试未完成分片或手动停止。

百炼供应商现按使用方式分别配置 `fun-asr`（异步文件精转）、`fun-asr-flash-2026-06-15`（短文件 SSE 增量转写）和 `fun-asr-realtime`（录音 WebSocket 实时稿）。首页录音会立即建立独立记录，并把 16 kHz 单声道 PCM 持续写入本地 WAV；离开录音页后仍由应用级会话继续，Android 使用麦克风前台服务，Apple 平台启用音频后台能力。网络中断只中断 provisional 实时稿，不中断本地录音。

当前录音记录已有持久化与异常退出后的 WAV 修复，但播放、会后正式稿 revision 和完整时间轴仍待后续 Recording 数据域迭代。

**尚未进入 Gate A**；真实 API 冒烟、媒体与存储 ADR、录音/恢复、结果持久化与播放链路仍未完成。


