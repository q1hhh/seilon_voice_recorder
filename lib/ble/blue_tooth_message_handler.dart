import 'dart:typed_data';
import 'dart:collection';
import 'package:Recording_pen/protocol/v1/constants/LockControlCmd.dart';
import 'package:Recording_pen/util/log_util.dart';
import 'package:Recording_pen/view/assistant/assistant_logic.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart' as logger_package;
import '../constant/my_app_common.dart';
import '../protocol/BleControlMessage.dart';
import '../protocol/BleControlPackage.dart';
import '../protocol/v1/voice_recorder_message/real_time_streaming_message.dart';
import '../util/ByteUtil.dart';

var log = logger_package.Logger();
class BlueToothMessageHandler {
  // 私有构造函数
  BlueToothMessageHandler._internal();

  // 静态单例引用
  static final BlueToothMessageHandler _instance = BlueToothMessageHandler._internal();

  // 工厂构造函数
  factory BlueToothMessageHandler() => _instance;

  static Map<String, Queue<Uint8List>> queueDataMap = {};

  var assistantLogic;
  // 组包
  static List<int> packageList = [];

  void handleConnectState(String deviceMac, bool state) {

  }

  // void handleMessage(Uint8List bleMsg, String deviceUuid) async {
  //   LogUtil.log.i("啊啊===>${BleControlMessage.parse(bleMsg)}");
  //   if (bleMsg[0] == BleControlPackage.START[0] && bleMsg[1] == BleControlPackage.START[1]) {
  //     queueDataMap.remove(deviceUuid);
  //     Queue<Uint8List> queue = Queue<Uint8List>();
  //     queue.add(bleMsg);
  //     queueDataMap.putIfAbsent(deviceUuid, () => queue);
  //
  //     if (bleMsg[bleMsg.length -1] == 0xFE) {
  //       Uint8List data = Uint8List(0);
  //       while(queue.isNotEmpty) {
  //         Uint8List element = queue.removeFirst();
  //         print("Removed element: $element");
  //         data = Uint8List.fromList([...data, ...element]);
  //       }
  //       queueDataMap.remove(deviceUuid);
  //       log.i('数据:$data');
  //       _distributeData(data, deviceUuid);
  //     }
  //   }
  // }

  // void handleMessage(Uint8List bleMsg, String deviceUuid) async {
  //   // LogUtil.log.i("handleMessage收到数据长度===>${bleMsg.length}");
  //
  //   if (bleMsg[0] == BleControlPackage.START[0] && bleMsg[1] == BleControlPackage.START[1]) {
  //
  //     queueDataMap.remove(deviceUuid);
  //     Queue<Uint8List> queue = Queue<Uint8List>();
  //     queue.add(bleMsg);
  //     queueDataMap.putIfAbsent(deviceUuid, () => queue);
  //
  //     if (bleMsg[bleMsg.length -1] == 0xFE) {
  //       Uint8List data = Uint8List(0);
  //       while(queue.isNotEmpty) {
  //         Uint8List element = queue.removeFirst();
  //         print("Removed element: $element");
  //         data = Uint8List.fromList([...data, ...element]);
  //       }
  //       queueDataMap.remove(deviceUuid);
  //       log.i('数据:$data');
  //       _distributeData(data, deviceUuid);
  //     }
  //   }
  //   else {
  //     if(queueDataMap[deviceUuid] == null) {
  //       queueDataMap[deviceUuid] = Queue<Uint8List>();
  //     }
  //     queueDataMap[deviceUuid]!.add(bleMsg);
  //
  //     var handleMsg = queueDataMap[deviceUuid]!.first;
  //
  //     int length = ByteUtil.getInt2(handleMsg, 5);
  //
  //     // queueDataMap[deviceUuid]!.add(bleMsg);
  //
  //     if(queueDataMap[deviceUuid]!.length == length) {
  //       var allData = queueDataMap.remove(deviceUuid);
  //
  //       Uint8List data = Uint8List(0);
  //       while (allData!.isNotEmpty) {
  //         data.addAll(allData.removeFirst());
  //       }
  //
  //       _distributeData(data, deviceUuid);
  //     }
  //     else {
  //       if (bleMsg[bleMsg.length -1] == 0xFE) {
  //         var queue = queueDataMap.remove(deviceUuid);
  //         Uint8List data = Uint8List(0);
  //         while(queue!.isNotEmpty) {
  //           Uint8List element = queue.removeFirst();
  //           print("Removed element: $element");
  //           data = Uint8List.fromList([...data, ...element]);
  //         }
  //         queueDataMap.remove(deviceUuid);
  //         log.i('数据2:$data');
  //         _distributeData(data, deviceUuid);
  //       }
  //     }
  //   }
  // }

  void handleMessage(Uint8List bleMsg, String deviceUuid) async {
    // 1. 初始化队列
    queueDataMap.putIfAbsent(deviceUuid, () => Queue<Uint8List>());
    queueDataMap[deviceUuid]!.add(bleMsg);

    Queue<Uint8List> queue = queueDataMap[deviceUuid]!;

    // 尝试不断从队列中组包，直到无法再组出完整包
    while (queue.isNotEmpty) {
      // 找到第一个包头
      Uint8List? handleMsg;
      int startIndex = 0;
      for (var msg in queue) {
        if (msg.length >= 2 && msg[0] == BleControlPackage.START[0] && msg[1] == BleControlPackage.START[1]) {
          handleMsg = msg;
          break;
        }
        startIndex++;
      }
      if (handleMsg == null) {
        // 没有包头，丢弃前面无效数据
        queue.clear();
        break;
      }

      // 判断当前包够不够取包长字段
      if (handleMsg.length < 7) break; // 至少到包长字段

      // 获取包长度（含包头+包尾）
      int length = ByteUtil.getInt2(handleMsg, 5);

      // 计算当前队列内累计长度
      int totalLen = 0;
      int endIndex = -1;
      for (int i = startIndex; i < queue.length; i++) {
        totalLen += queue.elementAt(i).length;
        if (totalLen >= length) {
          endIndex = i;
          break;
        }
      }

      if (endIndex == -1) break; // 不够长，等下一包

      // 组装完整数据包
      List<int> fullPacket = [];
      int remainLen = length;
      for (int i = startIndex; i <= endIndex; i++) {
        Uint8List item = queue.elementAt(startIndex); // always use startIndex as elements shift left after removeFirst
        if (item.length <= remainLen) {
          fullPacket.addAll(item);
          remainLen -= item.length;
          queue.removeFirst();
        } else {
          // 如果某个包拆开了，只取所需长度
          fullPacket.addAll(item.sublist(0, remainLen));
          // 剩下的部分塞回队首
          queue.removeFirst();
          queue.addFirst(item.sublist(remainLen));
          remainLen = 0;
        }
        if (remainLen == 0) break;
      }

      // 校验包尾
      if (fullPacket.length >= 1 && fullPacket.last == 0xFE) {
        _distributeData(Uint8List.fromList(fullPacket), deviceUuid);
      } else {
        // 包不对，数据错误，丢弃本次包
        //（如果你要更严谨处理，可打印日志但不要崩溃）
        log.e("包尾不是0xFE，数据异常");
        continue;
      }
      // 队列前面已处理完的数据已remove
    }
  }


  void _distributeData(Uint8List data, String deviceUuid) {
    var parse = BleControlPackage.parse(data);
    if (parse != null) {
      var parseMessage = parse.parseMessage(MyAppCommon.DEVICE_DEFAULT_KEY);
      if (parseMessage) {
        _receiveMessage(parse.message, parse.deviceId);
      }
    } else {
      log.e('parse is null');
    }
  }

  /**
   * 完整的数据解析后的处理方法
   */
  _receiveMessage(BleControlMessage ble, String deviceUuid) {
    // print("是什么===${ble.cmdCategory}");
    switch(ble.cmdCategory) {
      case LockControlCmd.CATEGORY_SYSTEM:
        switch(ble.cmd) {
          case LockControlCmd.CMD_SPECIAL_REQUEST_UPGRADE:
            if (Get.isRegistered<AssistantLogic>()) {
              var find = Get.find<AssistantLogic>();
              find.dealStartOTAReply(ble);
            }
            break;

          case LockControlCmd.CMD_SPECIAL_SEND_UPGRADE_DATA:
            if (Get.isRegistered<AssistantLogic>()) {
              var find = Get.find<AssistantLogic>();
              find.dealSendDataOTAReply(ble);
            }
            break;
        }
        break;

      case LockControlCmd.CATEGORY_RECORDER:
        switch(ble.cmd) {
          case LockControlCmd.CMD_RECORDER_REAL_TIME_STREAMING:
            var realTimeStreamingMessage = RealTimeStreamingMessage(ble);
            if (Get.isRegistered<AssistantLogic>()) {
              var find = Get.find<AssistantLogic>();
              find.dealAudioMessage(realTimeStreamingMessage);
            }
            break;

          case LockControlCmd.CMD_RECORDER_CONTROL_SOUND_RECORD:
            if (Get.isRegistered<AssistantLogic>()) {
              var find = Get.find<AssistantLogic>();
              find.getControlFeedBack(null);
            }
            break;

          case LockControlCmd.CMD_RECORDER_OPEN_WIFI:
            if (Get.isRegistered<AssistantLogic>()) {
              var find = Get.find<AssistantLogic>();
              find.dealOpenWifiMessage(ble);
            }
            break;

          case LockControlCmd.CMD_RECORDER_QUERY_TCP_SERVICE:
            if (Get.isRegistered<AssistantLogic>()) {
              var find = Get.find<AssistantLogic>();
              find.dealTcpServer(ble);
            }
            break;

          case LockControlCmd.CMD_RECORDER_AUDIO_FILE_COUNT:
            if (Get.isRegistered<AssistantLogic>()) {
              var find = Get.find<AssistantLogic>();
              find.dealAudioListCount(ble);
            }
            break;

          case LockControlCmd.CMD_RECORDER_AUDIO_FILE_LIST:
            if (Get.isRegistered<AssistantLogic>()) {
              var find = Get.find<AssistantLogic>();
              find.dealAudioList(ble);
            }
            break;

          case LockControlCmd.CMD_RECORDER_AUDIO_FILE_REMOVE:
          case LockControlCmd.CMD_RECORDER_AUDIO_FILE_REMOVE_ALL:
            if (Get.isRegistered<AssistantLogic>()) {
              var find = Get.find<AssistantLogic>();
              find.dealRemoveFileReply(ble);
            }
            break;

            // 单个文件读取
          // case LockControlCmd.CMD_RECORDER_AUDIO_FILE_CONTENT:
          //   if (Get.isRegistered<AssistantLogic>()) {
          //     var find = Get.find<AssistantLogic>();
          //     find.dealAudioFileContent(ble);
          //   }
          //   break;

            //设备快速上传
          case LockControlCmd.CMD_RECORDER_AUDIO_FILE_ALL_FAST_UPLOAD:
            if (Get.isRegistered<AssistantLogic>()) {
              var find = Get.find<AssistantLogic>();
              find.dealAudioFileContent(ble);
            }
            break;
        }
        break;
    }
  }


}