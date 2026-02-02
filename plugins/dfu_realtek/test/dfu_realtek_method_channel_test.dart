import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dfu_realtek/dfu_realtek_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelDfuRealtek platform = MethodChannelDfuRealtek();
  const MethodChannel channel = MethodChannel('dfu_realtek');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
