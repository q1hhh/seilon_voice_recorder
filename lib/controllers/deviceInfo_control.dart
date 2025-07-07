import 'package:get/get.dart';

/**
 * 保存设备的ssid、password、TCP信息(ip、端口)
 */
class DeviceInfoController extends GetxController {
  static final DeviceInfoController _instance = DeviceInfoController._internal();

  factory DeviceInfoController() {
    return _instance;
  }

  DeviceInfoController._internal();

  RxString ssid = "".obs;
  RxString password = "".obs;

  RxString tcpIp = "".obs;
  RxInt tcpPort = 0.obs;

  void cleanInfo() {
    DeviceInfoController().ssid.value = "";
    DeviceInfoController().password.value = "";
    DeviceInfoController().tcpIp.value = "";
    DeviceInfoController().tcpPort.value = 0;
  }

}