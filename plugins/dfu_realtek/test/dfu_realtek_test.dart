import 'package:flutter_test/flutter_test.dart';
import 'package:dfu_realtek/dfu_realtek.dart';
import 'package:dfu_realtek/dfu_realtek_platform_interface.dart';
import 'package:dfu_realtek/dfu_realtek_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDfuRealtekPlatform
    with MockPlatformInterfaceMixin
    implements DfuRealtekPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DfuRealtekPlatform initialPlatform = DfuRealtekPlatform.instance;

  test('$MethodChannelDfuRealtek is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDfuRealtek>());
  });

  test('getPlatformVersion', () async {
    DfuRealtek dfuRealtekPlugin = DfuRealtek();
    MockDfuRealtekPlatform fakePlatform = MockDfuRealtekPlatform();
    DfuRealtekPlatform.instance = fakePlatform;

    expect(await dfuRealtekPlugin.getPlatformVersion(), '42');
  });
}
