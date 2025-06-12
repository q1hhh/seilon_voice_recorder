import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';



class MyPhoneDeviceUtil {
  static final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  ///获取手机版本
  static Future<String> getSystemVersion() async {
    String systemVersion = "";
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      systemVersion = androidInfo.version.release;

    } else {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      systemVersion = iosInfo.systemVersion;
    }
    return systemVersion;
  }

  ///获取手机型号
  static Future<String> getDeviceType() async {
    String deviceType = 'Unknown';

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceType = androidInfo.model;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceType = iosInfo.utsname.machine;
    }

    return deviceType;
  }

  /// 获取手机厂商
  static Future<String> getDeviceBrand() async {
    String brand = 'Unknown';
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      brand = androidInfo.brand;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      brand = 'Apple';
    }
    return brand;
  }

  static Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version; // 获取版本号
  }

  static Future<String> getAppName() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.appName;
  }

}