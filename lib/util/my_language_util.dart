import 'dart:ui';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class MyLanguageUtil {

  static String getLanguage() {
    final box = GetStorage();
    // 本地语言
    var localeLand = box.read<Locale?>('localeLand');
    var systemLocale = localeLand ?? Get.deviceLocale;
    return systemLocale!.languageCode;
  }
}