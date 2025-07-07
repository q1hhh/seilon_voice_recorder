import 'dart:convert';
import 'dart:io';

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
      startListen();
    } catch (e) {
      print("连接失败: $e");
      close();
    }
  }

  // 发送数据
  void sendData(String data) {
    if (_socket != null) {
      _socket!.add(utf8.encode(data));
    } else {
      print("tcp未连接，无法发送数据");
    }
  }

  // 监听服务器响应
  void startListen() {
    _socket?.listen(
      (data) {
        print('收到tcpServer---->: ${data}');
      },
      onError: (error) {
        print('连接异常: $error');
        close();
      },
      onDone: () {
        print('连接关闭！');
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
    print('tcp连接已手动关闭');
  }
}