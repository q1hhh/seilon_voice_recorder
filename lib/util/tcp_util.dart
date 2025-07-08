import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:Recording_pen/util/log_util.dart';
import 'package:Recording_pen/util/view_log_util.dart';
import 'package:get_storage/get_storage.dart';

import '../ble/blue_tooth_message_handler.dart';

class TcpUtil {
  static final TcpUtil _instance = TcpUtil._internal();

  factory TcpUtil() {
    return _instance;
  }

  TcpUtil._internal();

  Socket? _socket;

  // 新增成员，用于串行控制
  Completer<void>? responseCompleter;

  // 收到的数据总长度(读取文件内容)
  int dataTotal = 0;

  // 保存收到的数据(读取文件内容)
  List tempData = [];

  // 连接TCP服务器
  Future<void> connect(String tcpIp, int tcpPort) async {
    // 防止重复连接
    if (_socket != null) {
      return;
    }
    try {
      _socket = await Socket.connect(tcpIp, tcpPort);
      print('Connected to: ${_socket!.remoteAddress.address}:${_socket!.remotePort}');
      ViewLogUtil.info('TCP连接成功--->${_socket!.remoteAddress.address}:${_socket!.remotePort}');
      startListen();
    } catch (e) {
      ViewLogUtil.error("TCP连接失败");
      close();
    }
  }

  // 直接发送，不等
  void sendData(List<int> data) {
    if (_socket != null) {
      _socket!.add(data);
    } else {
      print("TCP未连接，无法发送数据");
    }
  }

  // 发送数据
  Future<void> sendDataAndWait(List<int> data) async {
    if (_socket != null) {
      // 构建completer并记录
      // responseCompleter = Completer<void>();
      _socket!.add(data);

      // 等待收到响应
      // await responseCompleter!.future;

    } else {
      print("TCP未连接，无法发送数据");
    }
  }

  // 监听服务器响应
  void startListen() {
    _socket?.listen(
      (data) {
        LogUtil.log.i("响应长度==>${data.length}");
        tempData.addAll(data);
        LogUtil.log.i("收到的总长度==>${tempData.length}");

        ViewLogUtil.info('收到TCP服务器响应--->$data');
        var deviceInfo = GetStorage().read("deviceInfo");
        BlueToothMessageHandler().handleMessage(data, deviceInfo["deviceId"]);

        // 唤醒completer
        // if (responseCompleter != null && !responseCompleter!.isCompleted) {
        //   responseCompleter!.complete();
        // }
      },
      onError: (error) {
        ViewLogUtil.error('TCP连接异常: $error');
        close();
      },
      onDone: () {
        ViewLogUtil.error("TCP连接关闭");
        close();
      },
      cancelOnError: true
    );
  }
  
  // 主动关闭连接
  Future<void> close() async {
    await _socket?.close();
    _socket?.destroy();
    _socket = null;
    ViewLogUtil.info('TCP连接已关闭');
  }
}