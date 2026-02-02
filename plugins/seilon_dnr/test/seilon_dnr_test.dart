import 'package:flutter_test/flutter_test.dart';
import 'package:seilon_dnr/seilon_dnr.dart';
import 'package:seilon_dnr/seilon_dnr_platform_interface.dart';
import 'package:seilon_dnr/seilon_dnr_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSeilonDnrPlatform
    with MockPlatformInterfaceMixin
    implements SeilonDnrPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SeilonDnrPlatform initialPlatform = SeilonDnrPlatform.instance;

  test('$MethodChannelSeilonDnr is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSeilonDnr>());
  });

  test('getPlatformVersion', () async {
    SeilonDnr seilonDnrPlugin = SeilonDnr();
    MockSeilonDnrPlatform fakePlatform = MockSeilonDnrPlatform();
    SeilonDnrPlatform.instance = fakePlatform;

    expect(await seilonDnrPlugin.getPlatformVersion(), '42');
  });
}
