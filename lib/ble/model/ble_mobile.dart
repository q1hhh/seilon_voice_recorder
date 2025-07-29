import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart' as logger_package;
import 'package:get/get.dart';

import '../../controllers/deviceConnect.dart';
import '../../util/ByteUtil.dart';
import '../../util/log_util.dart';
import '../../util/view_log_util.dart';
import '../blue_tooth_message_handler.dart';
import 'ble_platform_interface.dart';

var log = logger_package.Logger();

class BleMobile implements BlePlatform {
  var deviceConnectLogic = DeviceConnectLogic();

  // final serviceId = "a000";
  final serviceId = "ffe0";// DB02
  // final handshakeUuid = "a001"; // 设备信息、状态读取
  // final characteristicUuid = "a002"; // 握手认证、设备控制
  // final realTimeAudioUuid = "a003"; // 实时音频接收

  final handshakeUuid = "ffe1"; // 设备信息、状态读取
  final characteristicUuid = "ffe1"; // 握手认证、设备控制
  final realTimeAudioUuid = "ffe1"; // 实时音频接收
  @override
  Future<void> startScan(List<Guid> serviceUuids, int timeout) async {
    await FlutterBluePlus.startScan(
      withServices: serviceUuids,
      timeout: Duration(seconds: timeout),
    );
  }

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.onScanResults;

  @override
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  @override
  Future<void> connectDevice(dynamic device, Function(bool) callback) async {
    BluetoothDevice bleDevice = device as BluetoothDevice;
    
    if (bleDevice != null) {
      try {
        await bleDevice.connect(timeout: const Duration(seconds: 10), autoConnect: false);

        deviceConnectLogic.streamSubscription[bleDevice.remoteId.str] = 
            bleDevice.connectionState.listen((BluetoothConnectionState state) async {
          log.i(state.toString());
          switch (state) {
            case BluetoothConnectionState.connected:
              // 只有安卓需要设置mtu
              if (Platform.isAndroid) bleDevice.requestMtu(512);
              print("设备${bleDevice.remoteId} 连接成功");
              ViewLogUtil.info("设备 ${bleDevice.remoteId} 连接成功");
              var services = await bleDevice.discoverServices();
              LogUtil.log.i(services);
              var bleService = services.firstWhere((service) =>
                  service.serviceUuid.str == serviceId);

              callback(true);

              for (var characteristic in bleService.characteristics) {
                if (characteristic.characteristicUuid.str == characteristicUuid) {
                  notify(bleDevice.remoteId.str, characteristic);
                  continue;
                }

                // if (characteristic.characteristicUuid.str == handshakeUuid) {
                //   notifyHandShake(bleDevice.remoteId.str, characteristic);
                //   continue;
                // }

                if (characteristic.characteristicUuid.str == realTimeAudioUuid) {
                  notifyRealTimeAudio(bleDevice.remoteId.str, characteristic);
                  continue;
                }
              }
              break;

            case BluetoothConnectionState.disconnected:
              log.e("disconnect :${bleDevice.remoteId.str}");
              ViewLogUtil.error("设备 ${bleDevice.remoteId} 已断开");
              BlueToothMessageHandler().handleConnectState(bleDevice.remoteId.str, false);
              deviceConnectLogic.streamSubscription[bleDevice.remoteId.str]?.cancel();
              deviceConnectLogic.cleanDevice(bleDevice.remoteId.str);

              if (deviceConnectLogic.notifySubscription.containsKey(bleDevice.remoteId)) {
                bleDevice.cancelWhenDisconnected(deviceConnectLogic.notifySubscription[bleDevice.remoteId]);
              }

              callback(false);
              break;

            case BluetoothConnectionState.connecting:
              break;
            case BluetoothConnectionState.disconnecting:
              break;
          }
        }, onError: (error) {
          log.e(error);
        });

      } catch (e) {
        log.e(e);
        const duration = Duration(seconds: 2);
        Timer(duration, () async {
          connectDevice(device, callback);
        });
      }
    }
  }

  @override
  Future<void> writeData(dynamic device, Uint8List data, {void Function(bool success)? callback}) async {
    BluetoothDevice bleDevice = device as BluetoothDevice;
    var servicesList = bleDevice.servicesList;

    var service = servicesList.firstWhere(
      (service) => serviceId == service.serviceUuid.str,
      orElse: () => servicesList[0],
    );

    if (service == null) {
      log.w('Service not found with serviceId: $serviceId');
      return;
    }

    var characteristic = service.characteristics.firstWhere(
      (character) => (characteristicUuid) == character.characteristicUuid.str,
      orElse: () => service.characteristics[0],
    );

    if (characteristic == null) {
      log.w('Characteristic not found with characteristicUuid: $characteristicUuid');
      return;
    }

    try {
      print('Writing data to characteristic: ${characteristic.characteristicUuid.str}');
      await characteristic.write(data, withoutResponse: true);
      callback?.call(true);
      print('Data written successfully');
    } catch (e) {
      callback?.call(false);
      print('Failed to write data: $e');
    }
  }

  @override
  Future<void> notify(String deviceId, dynamic characteristic) async {
    BluetoothCharacteristic bleCharacteristic = characteristic as BluetoothCharacteristic;
    bleCharacteristic.setNotifyValue(false);
    deviceConnectLogic.notifySubscription[deviceId] = bleCharacteristic.onValueReceived.listen((value) {
      var data = ByteUtil.uint8ListToHexFull(Uint8List.fromList(value));
      ViewLogUtil.info("onValueReceived=====>$deviceId $data");
      BlueToothMessageHandler().handleMessage(Uint8List.fromList(value), deviceId);
    });
    bleCharacteristic.setNotifyValue(true);
  }

  @override
  Future<void> notifyHandShake(String deviceId, dynamic characteristic) async {
    BluetoothCharacteristic bleCharacteristic = characteristic as BluetoothCharacteristic;
    bleCharacteristic.setNotifyValue(false);
    LogUtil.log.i('notifyHandShake');
    deviceConnectLogic.notifyControlSubscription[deviceId] = bleCharacteristic.onValueReceived.listen((value) {
      var data = ByteUtil.uint8ListToHexFull(Uint8List.fromList(value));
      ViewLogUtil.info("notifyHandShake=====>$deviceId $data");
      BlueToothMessageHandler().handleMessage(Uint8List.fromList(value), deviceId);
    });
    bleCharacteristic.setNotifyValue(true);
  }

  @override
  Future<void> notifyRealTimeAudio(String deviceId, dynamic characteristic) async {
    BluetoothCharacteristic bleCharacteristic = characteristic as BluetoothCharacteristic;
    bleCharacteristic.setNotifyValue(false);
    deviceConnectLogic.notifyRealTimeAudioSubscription[deviceId] = bleCharacteristic.onValueReceived.listen((value) {
      var data = ByteUtil.uint8ListToHexFull(Uint8List.fromList(value));
      ViewLogUtil.info("notifyRealTimeAudio=====>$deviceId $data");
      BlueToothMessageHandler().handleMessage(Uint8List.fromList(value), deviceId);
    });
    bleCharacteristic.setNotifyValue(true);
  }

  @override
  Future<Uint8List?> readInfo(String deviceId, String characteristicUuid) async {
    try {
      // 从已连接设备中找到目标设备
      final connectedDevices = FlutterBluePlus.connectedDevices;
      var device = connectedDevices.firstWhere(
        (connectedDevice) => connectedDevice.remoteId.str == deviceId,
        orElse: () => throw Exception('Device not found: $deviceId'),
      );

      // 获取服务列表
      var servicesList = device.servicesList;
      if (servicesList.isEmpty) {
        log.w('No services found for device: $deviceId');
        return null;
      }

      // 查找目标服务
      var service = servicesList.firstWhere(
        (service) => serviceId == service.serviceUuid.str,
        orElse: () => throw Exception('Service not found with serviceId: $serviceId'),
      );

      // 查找目标特征值
      var characteristic = service.characteristics.firstWhere(
        (character) => characteristicUuid == character.characteristicUuid.str,
        orElse: () => throw Exception('Characteristic not found: $characteristicUuid'),
      );

      // 检查特征值是否支持读取
      if (!characteristic.properties.read) {
        log.w('Characteristic does not support read: $characteristicUuid');
        return null;
      }

      // 读取数据
      log.i('Reading data from characteristic: $characteristicUuid');
      var data = await characteristic.read();
      log.i('Read data successfully: ${data.length} bytes');
      
      return Uint8List.fromList(data);
      
    } catch (e) {
      log.e('Failed to read info from device $deviceId: $e');
      return null;
    }
  }

  @override
  Future<void> manualDisconnect(String macAddress) async {
    final connectedDevices = FlutterBluePlus.connectedDevices;
    try {
      var device = connectedDevices.firstWhere(
        (connectedDevice) => connectedDevice.remoteId.str == macAddress,
      );
      device.disconnect();
    } catch (e) {
      log.e('not Device :$macAddress');
    }
  }

  @override
  List<BluetoothDevice> get connectedDevices => FlutterBluePlus.connectedDevices;

  @override
  Future<bool> checkBlueStatus() async {
    if (!await FlutterBluePlus.isAvailable || !await FlutterBluePlus.isOn) {
      return false;
    }
    return true;
  }
}