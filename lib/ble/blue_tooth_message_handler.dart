import 'dart:typed_data';
import 'dart:collection';
import 'package:Recording_pen/protocol/v1/constants/LockControlCmd.dart';
import 'package:Recording_pen/util/log_util.dart';
import 'package:Recording_pen/view/assistant/assistant_logic.dart';
import 'package:date_format/date_format.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart' as logger_package;
import '../constant/my_app_common.dart';
import '../protocol/BleControlMessage.dart';
import '../protocol/BleControlPackage.dart';
import '../protocol/v1/voice_recorder_message/real_time_streaming_message.dart';
import '../util/ByteUtil.dart';
import '../util/audio/notify_rate_calculator.dart';

var log = logger_package.Logger();

class BlueToothMessageHandler {
  BlueToothMessageHandler._internal();
  static final BlueToothMessageHandler _instance = BlueToothMessageHandler._internal();
  factory BlueToothMessageHandler() => _instance;

  /// 原来是 Map<String, Queue<Uint8List>>
  /// 改成：每个设备维护一块连续 buffer，避免大量 List 拷贝
  static final Map<String, List<int>> _bufferMap = {};

  final NotifyRateCalculator rateCalculator = NotifyRateCalculator();
  late final AssistantLogic _cachedLogic = Get.find<AssistantLogic>();

  void handleConnectState(String deviceMac, bool state) {}

  void realAudioMessage(Uint8List bleMsg, String deviceUuid) {
    if (_cachedLogic.isGetRecord) {
      handleMessage(bleMsg, deviceUuid);
    } else {
      // 实时流音频走快速通道
      NotifyRateCalculator.instance.onNotifyReceived(bleMsg);
      _cachedLogic.dealOpusMsg(bleMsg);
    }
  }

  /// 通用组包入口（BLE 和 TCP 共用）
  void handleMessage(Uint8List bleMsg, String deviceUuid, {isWifi = false}) {
    // 统计 notify 速率（放到 microtask，降低阻塞）：BLE 和 TCP 分开计算
    if (isWifi) {
      Future(() => NotifyRateCalculator.tcpInstance.onNotifyReceived(bleMsg));
    } else {
      Future(() => NotifyRateCalculator.instance.onNotifyReceived(bleMsg));
    }

    // 1. 取出或初始化 buffer
    final buffer = _bufferMap.putIfAbsent(deviceUuid, () => <int>[]);

    // 2. 追加这次收到的数据
    buffer.addAll(bleMsg);

    // 3. 不断尝试从 buffer 里拆出完整包
    _tryParseBuffer(deviceUuid, isWifi: isWifi);
  }

  /// 从指定设备的 buffer 中，不断拆出完整数据包
  void _tryParseBuffer(String deviceUuid, {isWifi = false}) {
    final buffer = _bufferMap[deviceUuid];
    if (buffer == null || buffer.isEmpty) return;

    // 安全上限：防止设备发疯导致内存爆炸
    const int maxBufferLen = 5 * 1024 * 1024; // 5MB，可按需要调整
    if (buffer.length > maxBufferLen) {
      log.w('[$deviceUuid] buffer 超过 $maxBufferLen 字节，丢弃旧数据重置');
      buffer.clear();
      return;
    }

    int offset = 0;

    while (true) {
      final remaining = buffer.length - offset;
      if (remaining < 7) {
        // 连头和长度字段都不够，下次再解析
        break;
      }

      // 找包头 0xFD, 0xFD（举例，用你 BleControlPackage.START）
      // 原逻辑只检查队头，现在我们扫描直到找到头
      int start = offset;
      while (start + 1 < buffer.length) {
        if (buffer[start] == BleControlPackage.START[0] &&
            buffer[start + 1] == BleControlPackage.START[1]) {
          break;
        }
        start++;
      }

      if (start + 1 >= buffer.length) {
        // 没有找到完整的头，丢弃前面垃圾
        if (start > 0) {
          buffer.removeRange(0, start);
        }
        return;
      }

      // 需要至少 7 字节才能读长度
      if (buffer.length - start < 7) {
        // 头已找到，但后面长度字段还没到，等下一次数据
        if (start > 0) {
          buffer.removeRange(0, start);
        }
        return;
      }

      // 包长字段在原来代码中是 index 5 开始的 int2（含包头+包尾）
      final length = ByteUtil.getInt2(Uint8List.fromList(buffer), start + 5);

      if (length <= 0) {
        log.e('[$deviceUuid] 非法包长: $length，丢弃当前头');
        // 丢弃这个字节，继续往后找
        buffer.removeRange(0, start + 1);
        offset = 0;
        continue;
      }

      // 判断剩余数据是否足够一个完整包
      if (buffer.length - start < length) {
        // 数据还不够，保留从 start 开始到结尾的内容
        if (start > 0) {
          buffer.removeRange(0, start);
        }
        return;
      }

      // 拿到完整包
      final packet = buffer.sublist(start, start + length);

      // 移动 offset / 删除已处理数据
      buffer.removeRange(0, start + length);
      offset = 0;

      // 校验包尾
      if (packet.isEmpty || packet.last != 0xFE) {
        log.e('[$deviceUuid] 包尾不是 0xFE，丢弃该包');
        // 继续下一轮
        continue;
      }

      // 分发解析
      _distributeData(Uint8List.fromList(packet), deviceUuid, isWifi: isWifi);

      // 继续 while(true)，尝试解析 buffer 里剩下的数据
      if (buffer.isEmpty) break;
    }
  }

  void _distributeData(Uint8List data, String deviceUuid, {isWifi = false}) {
    final parse = BleControlPackage.parse(data);
    if (parse != null) {
      bool ok = false;

      if (isWifi) {
        ok = parse.parseNotKeyMessage();
      } else {
        ok = parse.parseMessage(MyAppCommon.DEVICE_DEFAULT_KEY);
      }

      if (ok) {
        _receiveMessage(parse.message, parse.deviceId);
      }
    } else {
      log.e('parse is null');
    }
  }

  /// 完整的数据解析后的处理方法
  void _receiveMessage(BleControlMessage ble, String deviceUuid) {
    switch (ble.cmdCategory) {
      case LockControlCmd.CATEGORY_SYSTEM:
        switch (ble.cmd) {
          case LockControlCmd.CMD_SPECIAL_REQUEST_UPGRADE:
            if (Get.isRegistered<AssistantLogic>()) {
              Get.find<AssistantLogic>().dealStartOTAReply(ble);
            }
            break;
          case LockControlCmd.CMD_SPECIAL_SEND_UPGRADE_DATA:
            if (Get.isRegistered<AssistantLogic>()) {
              Get.find<AssistantLogic>().dealSendDataOTAReply(ble);
            }
            break;
        }
        break;

      case LockControlCmd.CATEGORY_RECORDER:
        switch (ble.cmd) {
          case LockControlCmd.CMD_RECORDER_DEVICE_INFO:
            if (Get.isRegistered<AssistantLogic>()) {
              Get.find<AssistantLogic>().dealDeviceInfoReplyMessage(ble);
            }
            break;

          case LockControlCmd.CMD_RECORDER_REAL_TIME_STREAMING:
            final realTimeStreamingMessage = RealTimeStreamingMessage(ble);
            if (Get.isRegistered<AssistantLogic>()) {
              Get.find<AssistantLogic>().dealAudioMessage(realTimeStreamingMessage);
            }
            break;

          case LockControlCmd.CMD_RECORDER_CONTROL_SOUND_RECORD:
            if (Get.isRegistered<AssistantLogic>()) {
              Get.find<AssistantLogic>().getControlFeedBack(null);
            }
            break;

          case LockControlCmd.CMD_RECORDER_OPEN_WIFI:
            if (Get.isRegistered<AssistantLogic>()) {
              Get.find<AssistantLogic>().dealOpenWifiMessage(ble);
            }
            break;

          case LockControlCmd.CMD_RECORDER_QUERY_TCP_SERVICE:
            if (Get.isRegistered<AssistantLogic>()) {
              Get.find<AssistantLogic>().dealTcpServer(ble);
            }
            break;

          case LockControlCmd.CMD_RECORDER_AUDIO_FILE_COUNT:
            if (Get.isRegistered<AssistantLogic>()) {
              Get.find<AssistantLogic>().dealAudioListCount(ble);
            }
            break;

          case LockControlCmd.CMD_RECORDER_AUDIO_FILE_LIST:
            if (Get.isRegistered<AssistantLogic>()) {
              Get.find<AssistantLogic>().dealAudioList(ble);
            }
            break;

          case LockControlCmd.CMD_RECORDER_AUDIO_FILE_REMOVE:
          case LockControlCmd.CMD_RECORDER_AUDIO_FILE_REMOVE_ALL:
            if (Get.isRegistered<AssistantLogic>()) {
              Get.find<AssistantLogic>().dealRemoveFileReply(ble);
            }
            break;

        // 设备快速上传 → 这里数据量最大
          case LockControlCmd.CMD_RECORDER_AUDIO_FILE_ALL_FAST_UPLOAD:
            if (Get.isRegistered<AssistantLogic>()) {
              // 用 microtask 包一层，先把当前同步栈清掉，给 UI 一点 breathing room
              Future.microtask(() {
                Get.find<AssistantLogic>().dealAudioFileContent(ble);
              });
            }
            break;
        }
        break;
    }
  }
}
