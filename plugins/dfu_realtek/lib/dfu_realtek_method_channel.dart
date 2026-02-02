import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dfu_realtek_platform_interface.dart';

/// An implementation of [DfuRealtekPlatform] that uses method channels.
class MethodChannelDfuRealtek extends DfuRealtekPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('dfu_realtek');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
