import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:Recording_pen/util/ByteUtil.dart';
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

  bool _isConnecting = false;

  // 收到的数据总长度(读取文件内容)
  int dataTotal = 0;

  // // 保存收到的数据(读取文件内容)
  // List tempData = [];

  // 连接TCP服务器
  Future<void> connect(String tcpIp, int tcpPort) async {
    // 如果已经在连或已连接，直接返回
    if (_isConnecting || _socket != null) {
      return;
    }

    _isConnecting = true;
    try {
      _socket = await Socket.connect(tcpIp, tcpPort);
      ViewLogUtil.info(
          'TCP连接成功--->${_socket!.remoteAddress.address}:${_socket!.remotePort}');
      startListen();
    } catch (e) {
      ViewLogUtil.error("TCP连接失败:$e");
      await close(); // 失败时确保清理
    } finally {
      _isConnecting = false;
    }
  }

  // 直接发送，不等
  void sendData(List<int> data) {
    if (_socket != null) {
      ViewLogUtil.info('TCP发送--->${ByteUtil.uint8ListToHexFull(Uint8List.fromList(data))}');
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

        // 4️⃣ 解析丢到 microtask，避免阻塞当前事件循环
        final deviceInfo = GetStorage().read("deviceInfo");
        final deviceId = deviceInfo?["deviceId"];

        if (deviceId != null) {
          // 不 await，让它在下一轮事件循环执行，UI 有机会刷新
          Future.microtask(() {
            BlueToothMessageHandler().handleMessage(data, deviceId, isWifi: true);
          });
        } else {
          ViewLogUtil.error("deviceInfo 中没有 deviceId，丢弃本次 TCP 数据");
        }

        // 需要的话，这里可以考虑做一个“简单的速率统计”，但不要太频繁更新 UI
      },
      onError: (error) {
        ViewLogUtil.error('TCP连接异常: $error');
        close();
      },
      onDone: () {
        ViewLogUtil.error("TCP连接关闭");
        close();
      },
      cancelOnError: true,
    );
  }

  
  // 主动关闭连接
  Future<void> close() async {
    final sock = _socket;
    _socket = null;        // ⭐ 立刻置空

    if (sock != null) {
      try {
        await sock.close();
        sock.destroy();
      } catch (e) {
        ViewLogUtil.error("关闭 TCP 连接出错: $e");
      }
    }

    ViewLogUtil.info('TCP连接已关闭');
  }

}