import 'package:get/get.dart';

import '../ble/service/ble_service.dart';

///保存设备连接

class DeviceConnectLogic {
  static final DeviceConnectLogic _instance = DeviceConnectLogic._internal();
  factory DeviceConnectLogic() {
    return _instance;
  }

  DeviceConnectLogic._internal();


  // 保存订阅(保存设备连接)
  RxMap streamSubscription = {}.obs;

  // notify通道
  RxMap notifySubscription = {}.obs;
  RxMap notifyControlSubscription = {}.obs;
  RxMap notifyRealTimeAudioSubscription = {}.obs;

  RxMap deviceStateListen = {}.obs;

  // 断开指定设备
  void disconnectDevice(String deviceId) {
    cleanDevice(deviceId);

    print('手动断开设备 $deviceId');
  }

  // 断开所有设备
  void disconnectAllDevices() {
    final deviceIds = streamSubscription.keys.toList();

    for (final deviceId in deviceIds) {
      disconnectDevice(deviceId.toString());
    }
  }

  // 清理设备资源
  void cleanDevice(String deviceId) {
    // 断开设备连接
    var connectedDevices = BleService().getConnectedDevices();
    var deviceMatches = connectedDevices.where(
      (device) => device.remoteId.str == deviceId
    );

    if (deviceMatches.isNotEmpty) {
      var targetDevice = deviceMatches.first;
      try {
        targetDevice.disconnect();
        print('设备 $deviceId 已断开连接');
      } catch (e) {
        print('断开设备 $deviceId 时发生错误: $e');
      }
    }

    streamSubscription[deviceId]?.cancel();
    notifySubscription[deviceId]?.cancel();
    notifyControlSubscription[deviceId]?.cancel();
    notifyRealTimeAudioSubscription[deviceId]?.cancel();

    // 清理所有订阅
    streamSubscription?.remove(deviceId);
    notifySubscription?.remove(deviceId);
    notifyControlSubscription?.remove(deviceId);
    notifyRealTimeAudioSubscription?.remove(deviceId);
    deviceStateListen?.remove(deviceId);
    
    print('已清理设备 $deviceId 的所有资源');
  }
}