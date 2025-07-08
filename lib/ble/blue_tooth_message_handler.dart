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

  void handleMessage(Uint8List bleMsg, String deviceUuid) async {
    // LogUtil.log.i("handleMessage收到数据长度===>${bleMsg.length}");

    if (bleMsg[0] == BleControlPackage.START[0] && bleMsg[1] == BleControlPackage.START[1]) {

      queueDataMap.remove(deviceUuid);
      Queue<Uint8List> queue = Queue<Uint8List>();
      queue.add(bleMsg);
      queueDataMap.putIfAbsent(deviceUuid, () => queue);

      if (bleMsg[bleMsg.length -1] == 0xFE) {
        Uint8List data = Uint8List(0);
        while(queue.isNotEmpty) {
          Uint8List element = queue.removeFirst();
          print("Removed element: $element");
          data = Uint8List.fromList([...data, ...element]);
        }
        queueDataMap.remove(deviceUuid);
        log.i('数据:$data');
        _distributeData(data, deviceUuid);
      }
    }
    else {
      var handleMsg = queueDataMap[deviceUuid]!.first;

      int length = ByteUtil.getInt2(handleMsg, 5);

      queueDataMap[deviceUuid]!.add(bleMsg);

      if(queueDataMap[deviceUuid]!.length == length) {
        var allData = queueDataMap.remove(deviceUuid);

        Uint8List data = Uint8List(0);
        while (allData!.isNotEmpty) {
          data.addAll(allData.removeFirst());
        }

        _distributeData(data, deviceUuid);
      }
      else {
        if (bleMsg[bleMsg.length -1] == 0xFE) {
          var queue = queueDataMap.remove(deviceUuid);
          Uint8List data = Uint8List(0);
          while(queue!.isNotEmpty) {
            Uint8List element = queue.removeFirst();
            print("Removed element: $element");
            data = Uint8List.fromList([...data, ...element]);
          }
          queueDataMap.remove(deviceUuid);
          log.i('数据2:$data');
          _distributeData(data, deviceUuid);
        }
      }
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
    switch(ble.cmdCategory) {
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

            // 单个文件读取
          // case LockControlCmd.CMD_RECORDER_AUDIO_FILE_CONTENT:
          //   if (Get.isRegistered<AssistantLogic>()) {
          //     var find = Get.find<AssistantLogic>();
          //     find.dealAudioFileContent(ble);
          //   }
          //   break;

            //设备快速上传
          case LockControlCmd.CMD_RECORDER_AUDIO_FILE_REMOVE_ALL_FAST_UPLOAD:
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