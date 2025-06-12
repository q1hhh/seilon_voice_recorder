import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../common/language/lang_plugin.dart';
import '../common/style/global_them_data .dart';
import '../generated/l10n.dart';
import '../routers/routers.dart';
import 'deviceInfo_control.dart';
import 'home_control.dart';
import 'my_window_main_frame.dart';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var deviceLocale = Get.deviceLocale;
    Get.put(HomeControl());

    FlutterNativeSplash.remove();

    return GetMaterialApp(
      title: 'Recording Pen',

      builder: EasyLoading.init(),
      translations: LangPlugin(),
      locale: deviceLocale,
      fallbackLocale: deviceLocale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      theme: GlobalThemData.lightThemeData,
      darkTheme: GlobalThemData.darkThemeData,
      initialRoute: "/home",
      getPages: AppPage.routes,
    );
  }
}