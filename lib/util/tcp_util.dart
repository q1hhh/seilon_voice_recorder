import 'dart:convert';
import 'dart:io';

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

  // 发送数据
  void sendData(List<int> data) {
    if (_socket != null) {
      _socket!.add(data);
    } else {
      print("TCP未连接，无法发送数据");
    }
  }

  // 监听服务器响应
  void startListen() {
    _socket?.listen(
      (data) {
        ViewLogUtil.info('收到TCP服务器响应--->$data');
        var deviceInfo = GetStorage().read("deviceInfo");
        BlueToothMessageHandler().handleMessage(data, deviceInfo["deviceId"]);
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
    ViewLogUtil.info('TCP连接已手动关闭');
  }
}