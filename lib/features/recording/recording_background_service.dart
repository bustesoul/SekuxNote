import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class RecordingBackgroundService {
  static void initialize() {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sekuxnote_recording',
        channelName: 'SekuxNote 录音',
        channelDescription: '录音进行时保持麦克风采集并显示持续通知。',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start(String title) async {
    if (!Platform.isAndroid) return;
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'SekuxNote 正在录音',
        notificationText: title,
      );
      return;
    }
    await FlutterForegroundTask.startService(
      serviceId: 4107,
      serviceTypes: const [ForegroundServiceTypes.microphone],
      notificationTitle: 'SekuxNote 正在录音',
      notificationText: title,
      callback: recordingForegroundTaskEntryPoint,
    );
  }

  static Future<void> stop() async {
    if (Platform.isAndroid && await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

@pragma('vm:entry-point')
void recordingForegroundTaskEntryPoint() {
  FlutterForegroundTask.setTaskHandler(_RecordingTaskHandler());
}

class _RecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
