import 'package:deeplink_tools/deeplink_tools.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channelName = 'test/deeplink_events';

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(channelName),
          (call) async => null,
        );
  });

  test('pushed url reaches an EventChannel listener', () async {
    final received = <dynamic>[];
    final sub = const EventChannel(
      channelName,
    ).receiveBroadcastStream().listen(received.add);
    await Future<void>.delayed(Duration.zero);

    final result = await const ChannelInjectDispatcher(
      channelName: channelName,
    ).dispatch('myapp://dev.example.com/x?token=1');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(result.ok, isTrue);
    expect(received, ['myapp://dev.example.com/x?token=1']);
    await sub.cancel();
  });
}
