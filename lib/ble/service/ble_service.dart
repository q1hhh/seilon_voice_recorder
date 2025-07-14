import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/log_util.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart' as logger_package;
import '../../controllers/home_control.dart';
import '../../util/BleDataUtil.dart';
import '../model/ble_platform_interface.dart';

var log = logger_package.Logger();

class BleService {
  static final BleService _instance = BleService._internal();
  var homeControl = Get.find<HomeControl>();

  final int _maxReconnectAttempts = 3; // 最大重连次数

  factory BleService() {
    return _instance;
  }

  BleService._internal();

  // 使用平台抽象
  final BlePlatform _blePlatform = BlePlatform.instance;

  // 直接连接
  connectDevice(device, Function(bool) callback) async {
    await _blePlatform.connectDevice(device, callback);
  }

  Future<void> writeData(dynamic device, Uint8List data, int mtu, {void Function(bool success)? callback}) async {
    int mtuSize = 20;

    if (mtu != 0) mtuSize = mtu - 3;

    //根据mtu修改单个数据发送数据长度大小
    Queue<Uint8List> splitPacketForByteDatas = BleDataUtil.splitPacketForByte(data, mtuSize);
    //循环发送
    splitPacketForByteDatas.forEach((data) async {
      await _blePlatform.writeData(device, data, callback: callback);
      LogUtil.log.i(ByteUtil.uint8ListToHexFull(data));
    });
    // Queue<Uint8List> splitPacketForByteData = BleDataUtil.splitPacketForByte(data, mtuSize);
    //
    // for (final chunk in splitPacketForByteData) {
    //   await _blePlatform.writeData(device, chunk, callback: callback);
    //   LogUtil.log.i(ByteUtil.uint8ListToHexFull(chunk));
    //   // await Future.delayed(Duration(milliseconds: 20));
    // }

  }

  // 手动断开指定的设备
  manualDisconnect(String macAddress) async {
    await _blePlatform.manualDisconnect(macAddress);
  }

  // 断开所有已经连接的设备
  disConnectAllDevice() {
    final connectedDevices = _blePlatform.connectedDevices;
    for (var item in connectedDevices) {
      if (Platform.isWindows) {
        // Windows平台的断开逻辑
        item.disconnect();
      } else {
        // 移动端平台的断开逻辑
        item.disconnect();
      }
    }
  }

  // 判断蓝牙是否可用
  Future<bool> checkBlueStatus() async {
    return await _blePlatform.checkBlueStatus();
  }

  // 获取已连接设备
  List<dynamic> getConnectedDevices() {
    return _blePlatform.connectedDevices;
  }

  // 读取设备信息
  Future<Uint8List?> readInfo(String deviceId, String characteristicUuid) async {
    return await _blePlatform.readInfo(deviceId, characteristicUuid);
  }
}


