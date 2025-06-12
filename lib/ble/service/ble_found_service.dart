import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart' as logger_package;

import '../model/ble_platform_interface.dart';

var log = logger_package.Logger();
class BleFoundService {
  static final BleFoundService _instance = BleFoundService._internal();
  factory BleFoundService() {
    return _instance;
  }
  BleFoundService._internal();

  static List<Guid> serviceUuids = [Guid("fb349b5f-8000-0080-0010-000000a00000"), Guid("0f417647-9d55-6d98-ca43-cdd098d726e1")];

  var _scanResultsSubscription;
  var _streamSubscription;

  final BlePlatform _ble = BlePlatform.instance;

  /// 开始扫描
  Future<void> startScan(int timeOut, Function(ScanResult result) callback, Function(int code) onError) async {
    log.d("start Scan");
    stopScan();

    _scanResultsSubscription = _ble.scanResults.listen((results) {
      if (results.isNotEmpty) {
        for (var result in results) {
          callback.call(result);
        } // 直接传递回调函数
      }
    });

    await _ble.startScan(serviceUuids, timeOut);

    //扫描结束回调
    _streamSubscription = _ble.isScanning.where((val) => val == false).listen((onDone) {
      onError(0);
    });
  }

  /// 停止扫描
  void stopScan() {
    log.i('stop scan');
    if(_scanResultsSubscription != null) {
      _scanResultsSubscription.cancel();
    }
    if(_streamSubscription != null) {
      _streamSubscription.cancel();
    }
  }


}