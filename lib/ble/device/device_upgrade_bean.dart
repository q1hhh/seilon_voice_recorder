import 'package:get/get.dart';

class DeviceUpgradeBean {
  List otaData = [];
  int otaIndex = 0;
  RxBool upgrading = false.obs;

  //总进度
  RxDouble schedule = 0.0.obs;

  //子进度
  int subProgress = 0;

  int maxLength = 0;
}