import 'dart:async';

import 'package:flutter_easyloading/flutter_easyloading.dart';

class LoadingUtil {

  static Timer? _timer;

  static void show({time,title}) {
    EasyLoading.show(status: title??'');

    _timer = Timer(Duration(seconds: time??20), () {
      EasyLoading.dismiss();
    });
  }

  static void showTip(String tip,{time}) {
    EasyLoading.dismiss();
    EasyLoading.show(status: tip);

    _timer = Timer(Duration(seconds: time??20), () {
      EasyLoading.dismiss();
    });
  }

  static void showSuccess(String tip){
    EasyLoading.showSuccess(tip);
  }

  static void showError(String tip){
    EasyLoading.showError(tip);
  }

  static void showToast(String tip) {
    EasyLoading.showToast(
        tip,
        toastPosition: EasyLoadingToastPosition.bottom,
        maskType: EasyLoadingMaskType.none
    );
  }

  static void dismiss() {
    EasyLoading.dismiss();
    if (_timer != null) {
      _timer!.cancel();
    }
  }
}