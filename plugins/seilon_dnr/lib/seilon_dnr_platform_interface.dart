import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'seilon_dnr_method_channel.dart';

abstract class SeilonDnrPlatform extends PlatformInterface {
  /// Constructs a SeilonDnrPlatform.
  SeilonDnrPlatform() : super(token: _token);

  static final Object _token = Object();

  static SeilonDnrPlatform _instance = MethodChannelSeilonDnr();

  /// The default instance of [SeilonDnrPlatform] to use.
  ///
  /// Defaults to [MethodChannelSeilonDnr].
  static SeilonDnrPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SeilonDnrPlatform] when
  /// they register themselves.
  static set instance(SeilonDnrPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
