import 'dart:typed_data';

import 'package:Recording_pen/ble/service/ble_found_service.dart';
import 'package:Recording_pen/ble/service/ble_service.dart';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/loading_util.dart';
import 'package:Recording_pen/util/log_util.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';


class BleSearchLogic extends GetxController {

  static final bleFoundBle = BleFoundService();
  static final bleService = BleService();

  RxMap scanDeviceMap = {}.obs;

  @override
  void onReady() {
    reStartScan();
    super.onReady();
  }

  @override
  void onClose() {
    bleFoundBle.stopScan();
    super.onClose();
  }

  //重新扫描
  void reStartScan() async {
    startScan();
  }

  //开始搜索蓝牙
  void startScan() {
    scanDeviceMap.clear();
    bleFoundBle.startScan(60, (device) async {
      List<int>? manufacturerData =
          device.advertisementData.manufacturerData[0x5D];

      if (manufacturerData != null) {
        scanDeviceMap[ByteUtil.uint8ListToHexFull(
            Uint8List.fromList(manufacturerData))] = device;
        update(['scanBle']);
      }
    }, (onError) {
      LogUtil.log.i('ble error:${onError}');
    });
  }

  toDeviceInfo(key) {
    // todo 停止蓝牙扫描
    bleFoundBle.stopScan();
    LoadingUtil.show();
    startConnect(key);
  }

  void startConnect(key) {

    bleService.connectDevice(scanDeviceMap[key].device, (result) {
      LogUtil.log.i('连接 :$result');
      LoadingUtil.dismiss();
      if (result) {

        GetStorage().write("deviceInfo", {
          "deviceId": scanDeviceMap[key].device.remoteId.str,
        });
        Get.toNamed("/assistant")?.then((value) {
          scanDeviceMap.clear();
          scanDeviceMap.value = {}.obs;
          print('清理列表');
        });
      }
    });
  }
}