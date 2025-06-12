import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_mobile.dart';
import 'ble_windows.dart';

abstract class BlePlatform {
  // 单例访问点
  static BlePlatform get instance => _createPlatformInstance();

  // 工厂方法保持单例
  static BlePlatform _createPlatformInstance() {
    if (Platform.isWindows) return _windowsInstance ??= BleWindows();
    return _mobileInstance ??= BleMobile();
  }
  static BleWindows? _windowsInstance;
  static BleMobile? _mobileInstance;

  // 扫描相关方法
  Future<void> startScan(List<Guid> serviceUuids, int timeout);
  Stream<List<ScanResult>> get scanResults;
  Stream<bool> get isScanning;
  Future<void> stopScan();

  // 设备连接相关方法
  Future<void> connectDevice(dynamic device, Function(bool) callback);
  Future<void> writeData(dynamic device, Uint8List data, {void Function(bool success)? callback});
  Future<void> notify(String deviceId, dynamic characteristic);
  Future<void> notifyHandShake(String deviceId, dynamic characteristic);
  Future<void> notifyRealTimeAudio(String deviceId, dynamic characteristic);
  Future<void> manualDisconnect(String macAddress);
  Future<Uint8List?> readInfo(String deviceId, String characteristicUuid);
  
  // 获取已连接设备
  List<dynamic> get connectedDevices;
  
  // 蓝牙状态检查
  Future<bool> checkBlueStatus();
}