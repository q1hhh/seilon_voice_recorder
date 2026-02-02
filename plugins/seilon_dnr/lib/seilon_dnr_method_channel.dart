import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'seilon_dnr_platform_interface.dart';

/// An implementation of [SeilonDnrPlatform] that uses method channels.
class MethodChannelSeilonDnr extends SeilonDnrPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('seilon_dnr');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
