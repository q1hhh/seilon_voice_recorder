import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'blue_tooth_message_handler.dart';

class _Pkt {
  final String devId;
  final Uint8List data;
  _Pkt(this.devId, this.data);
}

class BleCallbackDispatcher {
  BleCallbackDispatcher._();
  static final BleCallbackDispatcher instance = BleCallbackDispatcher._();

  final _q = Queue<_Pkt>();
  bool _busy = false;

  /// 防爆参数（按速率调整）
  int maxQueue = 200;   // 队列超过则丢最老，防止越积越多
  int timeSliceMs = 8;  // 每轮处理的最大连续时间，之后让出时间片

  void enqueue(String deviceId, Uint8List data) {

    Future.sync(() =>
        BlueToothMessageHandler().handleMessage(data, deviceId));

    // if (_q.length >= maxQueue) _q.removeFirst();  // 丢最老，保证实时
    // _q.addLast(_Pkt(deviceId, data));
    // if (!_busy) _drain();
  }

  void _drain() {
    _busy = true;
    // 放到下一轮事件循环，确保 BLE 回调能立刻返回
    Timer.run(() async {
      while (_q.isNotEmpty) {
        final start = DateTime.now();
        // 本轮时间片内尽量多处理一些，别太频繁切换
        while (_q.isNotEmpty &&
            DateTime.now().difference(start).inMilliseconds < timeSliceMs) {
          final pkt = _q.removeFirst();
          // 兼容同步/异步的 handleMessage
          await Future.sync(() =>
              BlueToothMessageHandler().handleMessage(pkt.data, pkt.devId));
        }
        // 主动让出时间片，给 BLE/UI 事件机会
        if (_q.isNotEmpty) {
          await Future.delayed(Duration.zero);
        }
      }
      _busy = false;
    });
  }
}
