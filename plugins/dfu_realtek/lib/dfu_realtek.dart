
import 'dfu_realtek_platform_interface.dart';

import 'dart:async';
import 'package:flutter/services.dart';

/// DFU 状态
enum DfuStatus {
  idle,
  initializing,
  ready,
  connecting,
  uploading,
  activating,
  success,
  failed,
  aborted,
}

/// 升级进度信息
class DfuProgress {
  final int progress;        // 总进度 0~100
  final double speedKbps;    // 传输速度
  final int totalBytes;      // 升级总字节
  final int transferredBytes;// 已传输字节

  DfuProgress({
    required this.progress,
    required this.speedKbps,
    required this.totalBytes,
    required this.transferredBytes,
  });

  factory DfuProgress.fromMap(Map<String, dynamic> map) {
    return DfuProgress(
      progress: map['progress'] ?? 0,
      speedKbps: map['speed'] ?? 0.0,
      totalBytes: map['total'] ?? 0,
      transferredBytes: map['transferred'] ?? 0,
    );
  }
}

class DfuRealtek {
  static const MethodChannel _channel = MethodChannel('dfu_realtek');

  static final DfuRealtek _instance = DfuRealtek._internal();
  factory DfuRealtek() => _instance;
  DfuRealtek._internal();

  /// 当前状态
  final StreamController<DfuStatus> _statusController = StreamController.broadcast();
  Stream<DfuStatus> get statusStream => _statusController.stream;

  /// 升级进度
  final StreamController<int> _progressController = StreamController.broadcast();
  Stream<int> get progressStream => _progressController.stream;

  /// 初始化DFU SDK
  Future<void> initialize({bool debug = false}) async {
    _statusController.add(DfuStatus.initializing);
    await _channel.invokeMethod('initialize', {"debug": debug});
  }

  /// 启动OTA升级
  Future<void> startOta({
    required String address,
    required String filePath,
    int reconnectTimes = 3
  }) async {
    _statusController.add(DfuStatus.connecting);

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onProgress':
          _progressController.add(call.arguments);

          break;

        case 'onOtaStart':
          _statusController.add(DfuStatus.ready);
          break;

        case 'onStartDfuProcess':
          _statusController.add(DfuStatus.uploading);
          break;

        case 'onPendingActiveImage':
          _statusController.add(DfuStatus.activating);
          break;

        case 'onSuccess':
          _statusController.add(DfuStatus.success);
          break;
        case 'onError':
          _statusController.add(DfuStatus.failed);
          break;
        case 'onAborted':
          _statusController.add(DfuStatus.aborted);
          break;
      }
    });

    await _channel.invokeMethod('startOta', {
      "address": address,
      "filePath": filePath,
      "reconnectTimes": reconnectTimes
    });
  }

  /// 中止OTA升级
  Future<void> abort() async {
    await _channel.invokeMethod('abort');
    _statusController.add(DfuStatus.aborted);
  }
}

