import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get_storage/get_storage.dart';
import 'package:opus_dart/opus_dart.dart';
import 'package:opus_flutter/opus_flutter.dart' as opus_flutter;

import 'common/shared/my_configurator.dart';
import 'controllers/my_app.dart';

Future<void> main() async {
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());
  WidgetsFlutterBinding.ensureInitialized();
  GetStorage.init();
  await MyConfigurator().initSharedPreferences();

  // 加载动态库并初始化 libopus
  final dylib = await opus_flutter.load();
  initOpus(dylib);
  runApp(const MyApp());
}