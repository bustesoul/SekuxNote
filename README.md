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

已新增最小的 BYOK 验证闭环：文字 AI 与语音转写配置分离、API Key 使用系统安全存储、文字 API 显式测试，以及小于 25 MB 的单个音频文件上传转写工作台。转写结果仅驻留当前会话，尚未写入 Recording 数据域。

**尚未进入 Gate A**；真实 API 冒烟、媒体与存储 ADR、录音/恢复、结果持久化与播放链路仍未完成。


