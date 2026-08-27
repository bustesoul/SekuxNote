import 'package:flutter_test/flutter_test.dart';
import 'package:sekuxnote/features/providers/dashscope_realtime_client.dart';

void main() {
  test('Fun-ASR realtime derives the workspace WebSocket endpoint', () {
    final uri = DashScopeRealtimeClient.websocketUriFromHttpApi(
      'https://workspace-1.cn-beijing.maas.aliyuncs.com/api/v1',
    );
    expect(uri.scheme, 'wss');
    expect(uri.host, 'workspace-1.cn-beijing.maas.aliyuncs.com');
    expect(uri.path, '/api-ws/v1/inference');
    expect(uri.hasQuery, isFalse);
  });
}