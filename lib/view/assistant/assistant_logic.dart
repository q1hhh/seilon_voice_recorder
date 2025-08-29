import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:async';

import 'package:Recording_pen/ble/ble_common_message.dart';
import 'package:Recording_pen/ble/service/ble_service.dart';
import 'package:Recording_pen/controllers/home_control.dart';
import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/protocol/v1/voice_recorder_message/open_u_disk_message.dart';
import 'package:Recording_pen/protocol/v1/voice_recorder_message/open_wifi_message.dart';
import 'package:Recording_pen/protocol/v1/voice_recorder_message/read_audio_list_count_reply_message.dart';
import 'package:Recording_pen/protocol/v1/voice_recorder_message/remove_audio_file.dart';
import 'package:Recording_pen/protocol/v1/voice_recorder_message/screen_control_message.dart';
import 'package:Recording_pen/protocol/v1/voice_recorder_message/start_ota_reply_message.dart';
import 'package:Recording_pen/protocol/v1/voice_recorder_message/upgrade_package_reply_message.dart';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/loading_util.dart';
import 'package:Recording_pen/util/log_util.dart';
import 'package:Recording_pen/util/my_pcm_util.dart';
import 'package:Recording_pen/util/view_log_util.dart';
import 'package:app_settings/app_settings.dart';
import 'package:date_format/date_format.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dfu_realtek/dfu_realtek.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:opus_dart/opus_dart.dart';
import 'package:opus_dart/wrappers/opus_decoder.dart';
import 'package:opus_flutter/opus_flutter.dart' as opus_flutter;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:seilon_dnr/seilon_dnr.dart';
import 'package:wifi_iot/wifi_iot.dart';
import '../../ble/package/hand_shake_message.dart';

import '../../controllers/deviceInfo_control.dart';
import '../../protocol/v1/system_setting_message/upgrade_packet_message.dart';
import '../../protocol/v1/voice_recorder_message/device_info_reply_message.dart';
import '../../protocol/v1/voice_recorder_message/power_control_message.dart';
import '../../protocol/v1/voice_recorder_message/start_ota_message.dart';
import '../../protocol/v1/voice_recorder_message/readAudioFileListMessage.dart';
import '../../protocol/v1/voice_recorder_message/read_audio_file_content_message.dart';
import '../../protocol/v1/voice_recorder_message/read_audio_file_content_reply_message.dart';
import '../../protocol/v1/voice_recorder_message/read_audio_file_list_reply_message.dart';
import '../../protocol/v1/voice_recorder_message/read_audio_list_count.dart';
import '../../protocol/v1/voice_recorder_message/real_time_streaming_message.dart';
import '../../protocol/v1/voice_recorder_message/tcp_server_message.dart';
import '../../protocol/v1/voice_recorder_message/tcp_server_parse_message.dart';
import '../../protocol/v1/voice_recorder_message/wifi_open_message.dart';
import '../../constant/my_app_common.dart';
import '../../protocol/BleControlPackage.dart';
import '../../protocol/v1/network_category_message/bind_device_message.dart';
import '../../protocol/v1/network_category_message/complete_net_work_message.dart';
import '../../protocol/v1/network_category_message/hand_shake_message.dart';
import '../../protocol/v1/voice_recorder_message/control_sound_record_message.dart';
import '../../protocol/v1/voice_recorder_message/get_device_info_message.dart';
import '../../theme/app_colors.dart';
import '../../util/audio/data_rate_formatter.dart';
import '../../util/audio/notify_rate_calculator.dart';
import '../../util/crc_16_util.dart';
import '../../util/tcp_util.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import '../../wiget/simple_opus_stream_player.dart';
import '../../wiget/upgrade_dialog.dart';
import '../file_list/page/file_list_page.dart';
import '../pagination.dart';

class GlobalOpusDecoder {
  static late SimpleOpusDecoder _decoder;
  static bool _initialized = false;

  static void init() {
    if (!_initialized) {
      _decoder = SimpleOpusDecoder(sampleRate: 16000, channels: 2);
      _initialized = true;
    }
  }

  static Int16List decode(Uint8List data) => _decoder.decode(input: data);
}

class AssistantLogic extends GetxController {
  var homeLogic = Get.find<HomeControl>();

  // 文件列表弹窗显示
  RxBool fileDialogShow = false.obs;

  // 读取内容的文件名
  RxString currentFileName = "".obs;
  // 读取文件的内容大小
  RxInt currentFileSize = 0.obs;
  
  // 暂存读取文件的内容
  RxList fileListContent = [].obs;

  // 文件列表总共多少页
  RxInt fileTotalCount = 5.obs;

  // 当前页码
  RxInt filePageNum = 1.obs;

  // 读取文件列表的起始位置
  RxInt fileStart = 0.obs;

  // 每页读取多少个文件
  RxInt filePageSize = 16.obs;

  // 每次读取多少文件内容
  RxInt maxFileContentLength = 900.obs;

  // 读取到的文件的总数量
  RxInt fileListCount = 99.obs;

  //读取到的文件列表
  RxList fileList = [].obs;

  // 按钮列表(读取信息)
  RxList actionBtnList = [].obs;

  var deviceInfo = GetStorage().read("deviceInfo");

  int lastSentCommandId = -1;

  final int turnOffRecording = 0x0300;

  Timer? timeoutTimer;

  int expectedOffset = 0; // 当前期望收到的start

  //降噪db
  RxDouble noiseReductionLevel = (-100.0).obs;

  Completer<void>? responseCompleter;
  // 收到的数据总长度
  int dataCount = 0;

  // ==============================

  TextEditingController otaModeController = TextEditingController();
  TextEditingController otaFileVersionController = TextEditingController();

  // OTA升级的总数据
  late Uint8List allOTAData;
  // OTA数据包的长度(设备回复)
  late int maxDataLength = 0;
  // OTA数据包(用于分包发送)
  Queue<Uint8List> splitData = Queue();
  // 当前发送包的标识(1~N)
  int currentPackAgeIndex = 1;
  // OTA升级模式(0, 1, 2)
  int otaType = 2;
  // OTA升级文件版本
  String otaVersion = "";
  // OTA升级文件名称
  RxString otaFileName = "".obs;
  // OTA升级进度
  RxDouble otaProcess = 0.0.obs;
  // OTA升级固件大小
  RxInt otaFileSize = 0.obs;
  // OTA升级已发送数据大小
  RxInt otaAlready = 0.obs;

  // 速率
  RxString dataRate = "".obs;

  final dfu = DfuRealtek();

  bool isGetRecord = false;

  @override
  void onClose() {
    disconnect();
    // opusStreamPlayer.dispose();
    super.onClose();
  }

  @override
  onInit() {

    ViewLogUtil.clear();
    actionBtnList.addAll([
      { "text": "进入绑定", "press": startBindDevice },
      { "text": "开始握手", "press": startHandShake },
      { "text": "完成绑定", "press": completeBinding },
      // { "text": "假弹窗", "press": () => showCustomDialog(Get.context!) },
      { "text": "关机", "press": powerOff },
      { "text": "获取设备信息New", "press": getDeviceInfoV2 },
      { "text": "开启录音(通话录音模式)", "press": () => controlSoundRecording(1, 0) },
      { "text": "开启录音(会议录音模式)", "press": () => controlSoundRecording(1, 1) },
      { "text": "关闭录音New", "press": () => controlSoundRecording(0, 0) },
      { "text": "打开U盘", "press": () => openUDisk(true) },
      { "text": "关闭U盘", "press": () => openUDisk(false) },
      { "text": "开启屏幕亮度", "press": () => screenControl(true) },
      { "text": "关闭屏幕亮度", "press": () => screenControl(false) },
      { "text": "打开WIFI", "press": () => openWifi(true) },
      { "text": "关闭WIFI", "press": () => openWifi(false) },
      { "text": "连接WIFI", "press": () => connectWifi() },
      { "text": "查询TCP服务", "press": () => readTcpServer() },
      { "text": "TCP连接", "press": () => connectTcp() },
      { "text": "切换通信模式(BLE/TCP)", "press": () => changeType() },
      { "text": "读取音频文件列表数量", "press": () => readAudioFileListCount() },
      { "text": "读取音频文件列表", "press": () => readAudioFileList() },
      // { "text": "读取单个音频文件内容", "press": () => readAudioFileContent() },
      // { "text": "删除单个文件", "press": () => removeAudioFile(fileList[2]['fileName']) },
      { "text": "删除所有文件", "press": () => removeAudioFile(null) },
      { "text": "进入OTA升级模式", "press": startOTA },
      { "text": "开始OTA升级", "press": () => sendUpgradePacket() },
      { "text": "清空本地存储的文件", "press": () => clearOpusFiles() },
      { "text": "清空日志", "press": clearLog },
      { "text": "选择本地降噪文件", "press": selectAudioFile },
      { "text": "升级蓝牙模块", "press": realtekOta},
    ]);
    initOpusRealPlay();
    initDnr();
    GlobalOpusDecoder.init();
  }



  // 初始化降噪
  initDnr() async {
    int result = await DnrPlugin.initialize(16000);

    if (result == 0) {

      // List<int> bufferSizes = await DnrPlugin.getBufferSizes();

      await DnrPlugin.setNoiseReductionLevel(noiseReductionLevel.value);

      ViewLogUtil.debug("DNR初始化成功:${noiseReductionLevel.value}");
    } else {

      ViewLogUtil.debug("DNR初始化失败");
    }
  }

  Future<void> initPcmSound() async {
    await FlutterPcmSound.init(sampleRate: 16000, channels: 2);

    // 当内部剩余 frames < threshold 时会回调要数据（单位=audio frames）
    // await FlutterPcmSound.setFeedThreshold(640 * 10);

    // FlutterPcmSound.setFeedCallback((int remainingFrames) async {
    //   // LogUtil.log.i("back:$remainingFrames");
    //
    //   // await FlutterPcmSound.feed(pcmQueue.removeFirst());
    // });

    FlutterPcmSound.start();
  }

  initOpusRealPlay() async {
    NotifyRateCalculator().start(
      enableAutoCalculation: true,
      autoCalculationInterval: const Duration(seconds: 1), // 每1秒自动计算

      onStatsUpdated: (stats) {
        // 自动接收最新统计数据
        dataRate.value = DataRateFormatter.formatDataRate(stats.dataRatePerSecond);
      },

      onPerformanceAlert: (alert) {
        // 自动接收性能警告
      },
    );

    // opusStreamPlayer = DebugAudioPlayer(
    //   sampleRate: 16000,  // 16kHz
    //   channels: 2,        // 单声道
    // );
    // await opusStreamPlayer.initialize();
  }

  //选择降噪文件进行降噪
  Future<void> selectAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        if (result.files.single.name.endsWith(".wav")) {

          var directory = await _getFilePath();

          if (directory == null) return;

          var data = await DnrPlugin.processAudioFile(
            "${directory.path}/${result.files.single.name}",
          );

          await writeToExternalStorage(data!, "DNR_${result.files.single.name}");
        }
      }
    } catch (e) {
      ViewLogUtil.error('选择文件失败: $e');
    }
  }

  Future<void> realtekOta() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        if (result.files.single.name.endsWith(".bin")) {

          var directory = await _getFilePath();

          if (directory == null) return;

          RxDouble _currentProgress = (0.0).obs;
          RxString _currentStatus = "准备升级...".obs;
          RxString _currentDetail = "".obs;
          RxBool _isComplete = false.obs;
          RxBool _canClose = false.obs;

          Get.dialog(
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return Obx(() => UpgradeDialog(
                    progress: _currentProgress.value,
                    statusText: _currentStatus.value,
                    detailText: _currentDetail.value,
                    isComplete: _isComplete.value,
                    canClose: _canClose.value,
                    primaryColor: Colors.cyan,
                    onClose: () {
                      Navigator.of(context).pop();
                    },
                  ));
                },
              )
          );

          await dfu.initialize();

          dfu.startOta(address: deviceInfo['deviceId'],
              filePath: "${directory.path}/${result.files.single.name}");

          dfu.progressStream.listen((progress) {
            _currentProgress.value = progress.toDouble();

          });

          dfu.statusStream.listen((state) {
            _currentStatus.value = state.name;

            if (state == DfuStatus.success) {
              _isComplete.value = true;
              _canClose.value = true;
            }

          });

        }
      }
    } catch (e) {
      ViewLogUtil.error('选择文件失败: $e');
    }
  }

  // 进行绑定
  startBindDevice() {
    var accountId = getAccountId();

    var bleLockPackage = BleControlPackage.toBleLockPackage(BindDeviceMessage(accountId), 0);

    var bytes = bleLockPackage.toBytes(MyAppCommon.DEVICE_DEFAULT_KEY);

    // 从连接的设备列表中找到对应的设备对象
    var connectedDevices = BleService().getConnectedDevices();
    var deviceMatches = connectedDevices.where(
            (device) => device.remoteId.str == deviceInfo["deviceId"]
    );

    if (deviceMatches.isNotEmpty) {
      var targetDevice = deviceMatches.first;
      BleService().writeData(targetDevice, bytes, targetDevice.mtuNow);
    } else {
      LogUtil.log.e("设备未连接或找不到设备: ${deviceInfo["deviceId"]}");
    }
  }

  // 开始握手
  startHandShake() {
    var accountId = getAccountId();

    var bleLockPackage = BleControlPackage.toBleLockPackage(HandshakeMessage(accountId), 0);

    var bytes = bleLockPackage.toBytes(MyAppCommon.DEVICE_DEFAULT_KEY);

    // 从连接的设备列表中找到对应的设备对象
    var connectedDevices = BleService().getConnectedDevices();
    var deviceMatches = connectedDevices.where(
            (device) => device.remoteId.str == deviceInfo["deviceId"]
    );

    if (deviceMatches.isNotEmpty) {
      var targetDevice = deviceMatches.first;
      BleService().writeData(targetDevice, bytes, targetDevice.mtuNow);
    } else {
      LogUtil.log.e("设备未连接或找不到设备: ${deviceInfo["deviceId"]}");
    }
  }

  // 完成绑定
  completeBinding() {
    var bleLockPackage = BleControlPackage.toBleLockPackage(CompleteNetWorkMessage(true), 0);
    _sendMessage(bleLockPackage);
  }

  // 关机
  powerOff() {
    var bleLockPackage = BleControlPackage.toBleLockPackage(PowerControlMessage(1), 0);
    _sendMessage(bleLockPackage);
  }

  getDeviceInfoV2() {
    var bleLockPackage = BleControlPackage.toBleLockPackage(GetDeviceInfoMessage(), 0);
    _sendMessage(bleLockPackage);
  }

  // 启动或关闭录音
  controlSoundRecording(int control, int model) {

    if (control == 1) {
      allOpusData.clear();
      opusData.clear();
      // opusStreamPlayer.startStreaming();
      isFirst = true;
      pushing = false;

      initPcmSound();

      _isInitialized = true;
    }
    if (control == 0) {
      lastSentCommandId = turnOffRecording;
      // opusStreamPlayer.stopStreaming();

      // pcmQueue.clear();

      getControlFeedBack(null);
    }

    var bleLockPackage = BleControlPackage.toBleLockPackage(ControlSoundRecordMessage(control, model), 0);
    _sendMessage(bleLockPackage);
  }

  //打开或关闭U盘
  openUDisk(bool isOpen) {

    var bleLockPackage = BleControlPackage.toBleLockPackage(OpenUDiskMessage(isOpen), 0);
    _sendMessage(bleLockPackage);
  }

  //屏幕控制
  screenControl(bool isOpen) {

    var bleLockPackage = BleControlPackage.toBleLockPackage(ScreenControlMessage(isOpen, 60, 99), 0);
    _sendMessage(bleLockPackage);
  }

  //打开WIFI
  openWifi(bool isOpen) async {
    if(!isOpen) {
      bool res = await WiFiForIoTPlugin.disconnect();
      if(res) {
        LogUtil.log.i("wifi: ${DeviceInfoController().ssid.value} 已断开 ==> $res");
        await TcpUtil().close();
        DeviceInfoController().cleanInfo();
      }
    }
    var bleLockPackage = BleControlPackage.toBleLockPackage(OpenWifiMessage(isOpen), 0);
    _sendMessage(bleLockPackage);
  }

  // 连接wifi
  connectWifi() async {
    Clipboard.setData(ClipboardData(text: DeviceInfoController().password.value.trim()));
    AppSettings.openAppSettings(type: AppSettingsType.wifi);

    // 连接 WPA 网络
    // 传true，强制使用wifi
    // await WiFiForIoTPlugin.forceWifiUsage(true);
    // if (await WiFiForIoTPlugin.isConnected()) {
    //   bool res = await WiFiForIoTPlugin.disconnect();
    //   LogUtil.log.i("连接前断开的结果--->$res");
    // }
    //
    // await Future.delayed(Duration(seconds:2));
    // var connect = await WiFiForIoTPlugin.connect(
    //   DeviceInfoController().ssid.value,
    //   password: DeviceInfoController().password.value,
    //   security: NetworkSecurity.WPA,
    //   withInternet: true,
    // );
    //
    // if(connect) {
    //   ViewLogUtil.info("wifi: ${ DeviceInfoController().ssid.value} 连接成功");
    // }
    // else {
    //   ViewLogUtil.error("wifi: ${ DeviceInfoController().ssid.value} 连接失败");
    // }
  }

  // 查询TCP服务
  readTcpServer() {
    var bleLockPackage = BleControlPackage.toBleLockPackage(TcpServerMessageMessage(), 0);
    _sendMessage(bleLockPackage);
  }

  // 连接TCP服务
  Future<void> connectTcp() async {
    if(DeviceInfoController().tcpIp.value.isEmpty || DeviceInfoController().tcpPort.value == 0) {
      return;
    }
    LogUtil.log.i("开始连接=====>tcpIp = ${DeviceInfoController().tcpIp}, tcpPort = ${DeviceInfoController().tcpPort}");
    await TcpUtil().connect(DeviceInfoController().tcpIp.value, DeviceInfoController().tcpPort.value);
  }

  // 切换通信模式
  void changeType() {
    DeviceInfoController().messageType.value = DeviceInfoController().messageType.value == "BLE" ? "TCP" : "BLE";
    ViewLogUtil.warn("当前通信模式${DeviceInfoController().messageType}");
  }

  // 读取音频文件列表数量
  readAudioFileListCount() {
    var bleLockPackage = BleControlPackage.toBleLockPackage(ReadAudioListCount(), 0);
    _sendMessage(bleLockPackage);
  }

  // 读取音频文件列表
  readAudioFileList() {
    if(fileListCount.value == 0) return;
    var bleLockPackage = BleControlPackage.toBleLockPackage(ReadAudioFileListMessage(fileStart.value, filePageSize.value), 0);
    _sendMessage(bleLockPackage);
  }

  // 读取单个音频文件内容
  readAudioFileContent(String readFileName, int readFileSize) async {
    if(fileList.isEmpty) return;

    TcpUtil().dataTotal = 0;
    TcpUtil().tempData.clear();
    fileListContent.clear();
    fileListContent.refresh();

    print("读取的文件--$readFileName--$readFileSize");

    currentFileName.value = readFileName;
    currentFileSize.value = readFileSize;

    isGetRecord = true;

    var bleLockPackage = BleControlPackage.toBleLockPackage(ReadAudioFileContentMessage(currentFileName.value, 0, maxFileContentLength.value), 0);
    _sendMessage(bleLockPackage);
    Get.back();
  }

  // 删除文件
  removeAudioFile(String? fileName) {
    LogUtil.log.i("删除的文件名--->$fileName");
    var bleLockPackage = BleControlPackage.toBleLockPackage(RemoveAudioFile(fileName), 0);
    _sendMessage(bleLockPackage);
  }

  // 进入OTA升级模式
  startOTA() async {
    currentPackAgeIndex = 1;
    showOTAModeDialog();
    return;
    // this.otaType = otaType;
    //
    // ByteData data = await rootBundle.load(fileName);
    // allOTAData = data.buffer.asUint8List();
    //
    // Uint8List checkSum = Crc16Util.calculateCrc32BigEndian(allOTAData);
    // String crc32CheckSum = ByteUtil.uint8ListToHexFull(checkSum);
    //
    // ViewLogUtil.info("crc==>${crc32CheckSum}");
    //
    // var startOTAMessage = StartOtaMessage(otaType, allOTAData.length, crc32CheckSum, version);
    //
    // ViewLogUtil.info("开始升级==> 类型: ${startOTAMessage.data[0]}, "
    //     "bin文件名称: $fileName, bin文件大小: ${allOTAData.length}, "
    //     "CRC: ${ByteUtil.uint8ListToHexFull(Uint8List.fromList((startOTAMessage.data.getRange(5, 9).toList())))}, "
    //     "版本号: ${startOTAMessage.data.getRange(9, 24)}");
    //
    // var bleLockPackage = BleControlPackage.toBleLockPackage(startOTAMessage, 0);
    //
    // _sendMessage(bleLockPackage);
  }

  // 输入OTA升级模式的弹窗
  showOTAModeDialog() {
    showDialog(
      context: Get.context!,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text(
            'OTA升级模式',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          content: SizedBox(
            height: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextField(
                  controller: otaModeController,
                  style: TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: '输入OTA升级模式(1位数字)',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(  // 未聚焦时的边框
                      borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 1),
                    ),
                  ),
                ),
                TextField(
                  controller: otaFileVersionController,
                  style: TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: '输入OTA升级文件版本',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(  // 未聚焦时的边框
                      borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: Container(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: AppColors.shadowColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () async {
                    if(otaModeController.text != otaModeController.text.trim()
                        || otaFileVersionController.text != otaFileVersionController.text.trim()) {
                      print("两边有空格");
                      return;
                    }
                    if(otaModeController.text.isEmpty || otaModeController.text.length > 1 || otaFileVersionController.text.isEmpty) return;
                    try {
                      if((int.parse(otaModeController.text) is int)) {
                        otaType = int.parse(otaModeController.text);
                        otaVersion = otaFileVersionController.text;

                        Navigator.of(ctx).pop();
                        if(await requestStoragePermission()) {
                          pickAndReadFile();
                        }
                      }
                    } catch (e) {
                      print("出错--->$e");
                    }
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 4),
                      Text(
                        "确定",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // 圆角
          ),
        );
      },
    );
  }

  // 选择文件
  Future<void> pickAndReadFile() async {
    // 让用户选择一个文件
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);

      List<int> bytes = await file.readAsBytes();
      
      allOTAData = Uint8List.fromList(bytes);

      Uint8List checkSum = Crc16Util.calculateCrc32BigEndian(allOTAData);
      String crc32CheckSum = ByteUtil.uint8ListToHexFull(checkSum);

      var startOTAMessage = StartOtaMessage(otaType, allOTAData.length, crc32CheckSum, otaVersion);

      otaFileSize.value = bytes.length;
      otaFileSize.refresh();

      ViewLogUtil.info("OTA升级模式: ${otaModeController.text}, 文件名称: ${result.files.single.name}, "
          "文件长度: ${bytes.length}, 版本号: $otaVersion, CRC: $crc32CheckSum");

      var bleLockPackage = BleControlPackage.toBleLockPackage(startOTAMessage, 0);

      _sendMessage(bleLockPackage);
    }
  }

  // 发送OTA升级数据
  sendUpgradePacket() async {
    var bleLockPackage = BleControlPackage.toBleLockPackage(
        UpgradePacketMessage(otaType, currentPackAgeIndex, splitData.first), 0);
    _sendMessage(bleLockPackage);
    
    otaAlready.value += splitData.length;
    otaAlready.refresh();

    LogUtil.log.i("分包：index=$currentPackAgeIndex, 当前长度=${splitData.first.length}");
  }

  // 清空本地的所有的opus文件
  Future<void> clearOpusFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);

      // 获取所有文件
      final files = dir.listSync();
      for (var entity in files) {
        // 只处理文件，不处理文件夹
        if (entity is File) {
          final ext = path.extension(entity.path);
          if (ext == '.opus' || ext == '.wav') {
            await entity.delete();
            print('已删除: ${entity.path}');
          }
        }
      }
      ViewLogUtil.info("目录下所有文件已清空");

    } catch (e) {
      print('删除文件失败: $e');
      ViewLogUtil.info("删除文件失败");
    }
  }


  // 32位UUID
  String getAccountId() {
    // todo demo模拟Id
    return '8fdc3c5ed75d4eadb04283803516b1a3';
  }

  // 通用发送消息方法
  void _sendMessage(BleControlPackage bleLockPackage) async {
    var bytes = bleLockPackage.toBytes(MyAppCommon.DEVICE_DEFAULT_KEY);

    if(DeviceInfoController().messageType.value == "BLE") {
      // 从连接的设备列表中找到对应的设备对象
      var connectedDevices = BleService().getConnectedDevices();
      var deviceMatches = connectedDevices.where(
              (device) => device.remoteId.str == deviceInfo["deviceId"]
      );

      if (deviceMatches.isNotEmpty) {
        var targetDevice = deviceMatches.first;
        BleService().writeData(targetDevice, bytes, targetDevice.mtuNow);
      } else {
        LogUtil.log.e("设备未连接或找不到设备: ${deviceInfo["deviceId"]}");

        Get.showSnackbar(
          const GetSnackBar(
            message: "设备未连接或找不到设备",
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );

      }
    }
    // TCP模式
    else {
      TcpUtil().sendData(bytes);
    }

  }

  // 断开连接
  disconnect() {
    if (deviceInfo != null && deviceInfo["deviceId"] != null) {
      BleService().manualDisconnect(deviceInfo["deviceId"]);
      LogUtil.log.i("断开设备连接: ${deviceInfo["deviceId"]}");
    }
  }

  // 控制反馈(跟发送的commandId对比)
  getControlFeedBack(data) async {
    // if(homeLogic.lastSentCommandId.value == data) {}
    LogUtil.log.i("控制反馈--->$data");

    if (lastSentCommandId == turnOffRecording) {
      lastSentCommandId = -1;
      FlutterPcmSound.stop();

      if (allOpusData.isNotEmpty) {

        var list = allOpusData.toList().map((data) => [0, 0, 0, data.length, ...data]).toList();

        await writeToExternalStorage(Uint8List.fromList(list.expand((inner) => inner).toList()), '${DateFormat('yyyy-MM-dd_HH_mm_ss').format(DateTime.now())}.opus');
        await saveWav('${DateFormat('yyyy-MM-dd_HH_mm_ss').format(DateTime.now())}.wav');
      }
    }
  }

  // 清空日志
  clearLog() {
    ViewLogUtil.clear();
  }


  Future<bool> requestStoragePermission() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    int sdk = androidInfo.version.sdkInt;
    bool granted;

    if (sdk >= 33) {
      // Android 13+
      final res = await [
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ].request();
      granted = res.values.every((s) => s.isGranted);
    } else {
      // Android 12及以下
      PermissionStatus status = await Permission.storage.request();
      granted = status.isGranted;
    }

    if (!granted && sdk >= 30) {
      // 强迫许可可选项，非Play发布时慎用
      final manage = await Permission.manageExternalStorage.request();
      granted = manage.isGranted;
    }

    if (!granted) await openAppSettings();
    return granted;
  }

  Future<Directory?> _getFilePath() async {
    Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      String newPath = "";
      List<String> paths = directory.path.split("/");
      for (int x = 1; x < paths.length; x++) {
        String folder = paths[x];
        if (folder != "Android") {
          newPath += "/" + folder;
        } else {
          break;
        }
      }
      newPath = newPath + "/Download";
      directory = Directory(newPath);

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
    return directory;
  }

  Future<void> writeToExternalStorage(Uint8List data, String fileName) async {
    if (await requestStoragePermission()) {

      var directory = await _getFilePath();
      if (directory == null) return;

        File file = File('${directory.path}/$fileName');
        await file.writeAsBytes(data);
        print('文件已保存至: ${file.path}');

        Get.showSnackbar(
          GetSnackBar(
            message: '文件已保存至: ${file.path}',
            duration: const Duration(seconds: 2),          // 显示时长：3秒后自动消失
            animationDuration: const Duration(milliseconds: 100), // 入场动画：立即出现
            snackPosition: SnackPosition.BOTTOM,     // 可选：位置默认 BOTTOM
            backgroundGradient: const LinearGradient(             // 渐变背景颜色
              colors: AppColors.buttonGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: 8,                                      // 可选：圆角
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
          ),
        );

      } else {
      print('存储权限被拒绝');
    }
  }



  Future<void> writeToFile(List<int> data, String fileName) async {
    try {
      // 获取应用文档目录（跨平台兼容）
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');

      // 如果文件存在，先删除
      if (await file.exists()) {
        await file.delete();
      }

      // 再写入新文件
      await file.writeAsBytes(Uint8List.fromList(data));

      print('文件已写入至: ${file.path}');
    } catch (e) {
      print('写入失败: $e');
    }
  }

  Future<String> _getOpusSavePath(String extension) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}$extension';
  }

  //回调成功的方法--------------------------------------------------------------------------------

  dealHandShakeMessage(BleMessage bleMessage, String deviceUuid) {
    var directive = HandShakeMessage([], "", 3).toBytes();

    // 从连接的设备列表中找到对应的设备对象
    var connectedDevices = BleService().getConnectedDevices();
    var deviceMatches = connectedDevices
        .where((device) => device.remoteId.str == deviceInfo["deviceId"]);

    if (deviceMatches.isNotEmpty) {
      var targetDevice = deviceMatches.first;
      BleService().writeData(targetDevice, directive, targetDevice.mtuNow);
    } else {
      LogUtil.log.e("设备未连接或找不到设备: ${deviceInfo["deviceId"]}");
    }
  }

  Queue<List<int>> allOpusData = Queue();

  List<int> opusData = [];

  bool _isInitialized = false;

  // opus 裸流数据
  void dealAudioMessage(RealTimeStreamingMessage realTimeStreamingMessage) {
    if (!_isInitialized) {
      print('音频处理器未初始化');
      return;
    }

    for (var msg in realTimeStreamingMessage.opusData) {
      // 直接发送给优化的播放器处理
      // opusStreamPlayer.onBluetoothPcmData(Uint8List.fromList(msg));

      Future(() => testDirectPlaySimple(Uint8List.fromList(msg)));

      // 如果需要保存全量数据
      // allOpusData.addAll(msg);
      // opusData.addAll(msg);
    }
  }

  void dealOpusMsg(Uint8List data) {
    FlutterPcmSound.feed(GlobalOpusDecoder.decode(data));
    allOpusData.add(data);
  }

  // Queue<PcmArrayInt16> pcmQueue = Queue();

  bool isFirst = true;
  bool pushing = false;


  Future<void> testDirectPlaySimple(Uint8List opusData) async {
    try {

      MyPcmUtil.decodeOpusToPcm(opusData).then((data) {
        FlutterPcmSound.feed(data);
      });
      // final pcmData = await MyPcmUtil.decodeOpusToPcm(opusData);
      // if (pcmData.isEmpty) return;
      //
      // FlutterPcmSound.feed(pcmData);

    } catch (e) {
      print('简化播放失败: $e');
    }
  }

  /**
  Future<void> testDirectPlaySimple(Uint8List opusData) async {
    try {
      final pcmData = await MyPcmUtil.decodeOpusToPcm(opusData);
      if (pcmData.isEmpty) return;

      List<int> processedPcm = [];

      // 如果是640样本，分割成256样本的帧处理
      if (pcmData.length == 640) {
        // 处理前两个256样本帧
        for (int i = 0; i < 2; i++) {
          List<int> frame256 = pcmData.sublist(i * 256, (i + 1) * 256);

          PcmFrameResult? result = await DnrPlugin.processPcmFrame(frame256);
          if (result != null && result.isSuccess) {
            processedPcm.addAll(result.processedPcm);
          } else {
            LogUtil.log.e("第${i+1}个256帧处理失败: ${result?.statusMessage ?? 'Unknown error'}");
            return;
          }
        }

        // 处理剩余的128样本
        List<int> lastFrame = List.from(pcmData.sublist(512)); // 最后128样本
        while (lastFrame.length < 256) {
          lastFrame.add(0); // 填充到256
        }

        PcmFrameResult? lastResult = await DnrPlugin.processPcmFrame(lastFrame);
        if (lastResult != null && lastResult.isSuccess) {
          processedPcm.addAll(lastResult.processedPcm.sublist(0, 128)); // 只取前128个
        } else {
          LogUtil.log.e("最后一帧处理失败: ${lastResult?.statusMessage ?? 'Unknown error'}");
          return;
        }

      } else if (pcmData.length == 256) {
        // 标准256样本帧
        PcmFrameResult? result = await DnrPlugin.processPcmFrame(pcmData);
        if (result != null && result.isSuccess) {
          processedPcm = result.processedPcm;
        } else {
          LogUtil.log.e("单帧处理失败: ${result?.statusMessage ?? 'Unknown error'}");
          return;
        }

      } else {
        LogUtil.log.e("不支持的PCM帧长度: ${pcmData.length}");
        return;
      }

      // 播放处理后的音频
      FlutterPcmSound.feed(Int16List.fromList(processedPcm));

    } catch (e) {
      print('简化播放失败: $e');
    }
  }*/

  // 获取设备信息(回复)
  dealDeviceInfoReplyMessage(BleControlMessage ble) {
    var deviceInfoMessage = DeviceInfoReplyMessage(ble);
    ViewLogUtil.info(deviceInfoMessage.toString());
  }

  dealOpenWifiMessage(BleControlMessage ble) {
    var wifiOpenMessage = WifiOpenMessage(ble);
    DeviceInfoController().ssid.value = wifiOpenMessage.apName ?? "";
    DeviceInfoController().password.value = wifiOpenMessage.apPassword ?? "";
    ViewLogUtil.info("wifi名称： ${DeviceInfoController().ssid}, wifi密码: ${ DeviceInfoController().password}");
  }

  // 查询TCP服务信息(回复)
  dealTcpServer(BleControlMessage ble) {
    var tcpMessage = TcpServerParseMessage(ble);
    DeviceInfoController().tcpIp.value = tcpMessage.tcpIp?.join(".") ?? "";
    DeviceInfoController().tcpPort.value = tcpMessage.tcpPort ?? 0;
    ViewLogUtil.info("tcpIp = ${DeviceInfoController().tcpIp}, tcpPort = ${DeviceInfoController().tcpPort}");
  }

  // 读取音频文件列表数量(回复)
  dealAudioListCount(BleControlMessage ble) {
    var audioListCountMessage = ReadAudioListCountReplyMessage(ble);
    // 每页最多显示多少个
    filePageSize.value = audioListCountMessage.pageCount ?? 16;
    fileListCount.value = audioListCountMessage.fileCount ?? 0;

    maxFileContentLength.value = audioListCountMessage.maxFileContentLength ?? 900;

    var temp = (fileListCount.value / filePageSize.value);

    // 总共多少页
    fileTotalCount.value = temp == 0 ? 0 : temp.ceil();

    ViewLogUtil.info("读取文件数量--->$audioListCountMessage");
    ViewLogUtil.info("文件页数--->${fileTotalCount.value}");
  }

  // 读取音频文件列表(回复)
  dealAudioList(BleControlMessage ble) {
    var audioListMessage = ReadAudioFileListReplyMessage(ble);
    fileList.value = (audioListMessage.fileList ?? []).cast<Map<String, Object>>();

    fileList.refresh();
    ViewLogUtil.info(audioListMessage.toString());
    ViewLogUtil.info("当前页码: (${filePageNum.value}/${fileTotalCount.value})");

    if(fileDialogShow.value) return;
    showCustomDialog(Get.context!);
  }

  // 读取音频文件内容(回复)
  void dealAudioFileContent(BleControlMessage ble) async {
    var audioListContentMessage = ReadAudioFileContentReplyMessage(ble);

    if(DeviceInfoController().messageType.value == "TCP") {
      if (audioListContentMessage.fileContent == null) {
        ViewLogUtil.error("文件内容为空, ble data===> $ble");
        return;
      }

      dataCount += audioListContentMessage.fileContent!.length;

      LogUtil.log.i(
          "收到文件内容的长度${audioListContentMessage.fileContent?.length}, "
          "文件内容的起始位置${audioListContentMessage.start}, "
          "收到数据的总长度: ${TcpUtil().tempData.length},"
            "文件内容总长度:$dataCount"
      );
    }

    fileListContent.value.addAll(audioListContentMessage.fileContent as List<int>);
    fileListContent.refresh();
    LogUtil.log.i("收到的数据长度： ${fileListContent.length}");
    // responseCompleter?.complete();
    // 如果全部接收完毕
    if ((currentFileSize.value == fileListContent.length) && await requestStoragePermission()) {

      isGetRecord = false;

      await writeToExternalStorage(Uint8List.fromList(fileListContent.value.cast<int>()), currentFileName.value);

      if (currentFileName.value.endsWith(".wav")) {

        var directory = await _getFilePath();

        if (directory == null) return;

        var data = await DnrPlugin.processAudioFile(
          "${directory.path}/${currentFileName.value}",
        );

        await writeToExternalStorage(data!, "DNR_${currentFileName.value}");
      }
    }
  }

  // 删除文件回复
  dealRemoveFileReply(BleControlMessage ble) {
    if(ble.isSuccess()) {
      LoadingUtil.showSuccess("删除成功");
    }
    else {
      LoadingUtil.showSuccess("删除失败");
    }
  }

  // 进入OTA升级模式(回复)
  dealStartOTAReply(BleControlMessage ble) {
    var startOTAReply = StartOtaReplyMessage(ble);
    LogUtil.log.i(startOTAReply);

    var code = startOTAReply.data[0];
    // 电量不足
    if (code == 0x1B) {
      ViewLogUtil.error("电量不足");
      return;
    }

    if(code == 0x01) {
      ViewLogUtil.error("进入升级模式失败");
      return;
    }

    if(code == 0x03) {
      ViewLogUtil.error("同一版本");
      return;
    }

    int maxLength = startOTAReply.getMaxLength();
    ViewLogUtil.info("每包发送最大: $maxLength");

    log.i(maxLength);
    //分包数据清除
    splitData.clear();

    // 开始分包
    splitData = splitPacketForByte(allOTAData, maxLength);

    //最大包数
    maxDataLength = splitData.length;
  }

  Queue<Uint8List> splitPacketForByte(Uint8List data, int size) {
    Queue<Uint8List> dataQueue = Queue<Uint8List>();
    if (data != null) {
      int index = 0;
      do {
        Uint8List surplusData = Uint8List.sublistView(data, index);
        Uint8List currentData;
        if (surplusData.length <= size) {
          currentData = Uint8List.fromList(surplusData);
          index += surplusData.length;
        } else {
          currentData = Uint8List.sublistView(data, index, index + size);
          index += size;
        }
        dataQueue.add(currentData);
      } while (index < data.length);
    }
    return dataQueue;
  }

  // 发送OTA升级数据(回复)
  dealSendDataOTAReply(BleControlMessage ble) async {
    var sendOTADataReplyMessage = UpgradePackageReplyMessage(ble);
    LogUtil.log.i("发送升级数据包的回复$sendOTADataReplyMessage");

    // 发送升级包成功
    if (sendOTADataReplyMessage.isSuccess()) {
      currentPackAgeIndex = ++currentPackAgeIndex;
    }

    if (sendOTADataReplyMessage.isFail()) {
      ViewLogUtil.error("升级发生错误");
      return;
    }

    // OTA升级成功
    if (sendOTADataReplyMessage.isComplete()) {
      ViewLogUtil.info("OTA升级成功");
      return;
    }


    if (currentPackAgeIndex <= maxDataLength) {
      splitData.removeFirst();
      await Future.delayed(const Duration(milliseconds: 20));
      sendUpgradePacket();
    } else {
      log.i('send Success');
    }

  }

  Future<void> saveWav(String fileName) async {
    // LogUtil.log.i("录音数据--->$allOpusData");
    Uint8List pcmData = await MyPcmUtil.decodeAllOpus(allOpusData.toList());

    var channels = 2;

    Uint8List wavData = pcmToWav(pcmData, channels: channels);

    writeToExternalStorage(wavData, fileName);
  }


  Uint8List pcmToWav(Uint8List pcmBytes, {
    int sampleRate = 16000,
    int channels = 1,
    int bitDepth = 16,
  }) {
    int byteRate = sampleRate * channels * bitDepth ~/ 8;
    int blockAlign = channels * bitDepth ~/ 8;
    int dataLength = pcmBytes.length;
    int fileSize = 44 + dataLength - 8;

    final header = BytesBuilder();

    // RIFF header
    header.add(ascii.encode('RIFF'));
    header.add(_intToBytes(fileSize, 4));       // File size - 8
    header.add(ascii.encode('WAVE'));

    // fmt chunk
    header.add(ascii.encode('fmt '));
    header.add(_intToBytes(16, 4));             // Subchunk1Size (16 for PCM)
    header.add(_intToBytes(1, 2));              // AudioFormat (1 = PCM)
    header.add(_intToBytes(channels, 2));       // NumChannels
    header.add(_intToBytes(sampleRate, 4));     // SampleRate
    header.add(_intToBytes(byteRate, 4));       // ByteRate
    header.add(_intToBytes(blockAlign, 2));     // BlockAlign
    header.add(_intToBytes(bitDepth, 2));       // BitsPerSample

    // data chunk
    header.add(ascii.encode('data'));
    header.add(_intToBytes(dataLength, 4));     // Subchunk2Size
    header.add(pcmBytes);                       // PCM 数据本体

    return header.toBytes();
  }
  
  Uint8List _intToBytes(int value, int byteCount) {
    final bytes = ByteData(byteCount);
    if (byteCount == 2) {
      bytes.setInt16(0, value, Endian.little);
    } else if (byteCount == 4) {
      bytes.setInt32(0, value, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  // 文件列表弹窗
  void showCustomDialog(BuildContext context) {
    fileDialogShow.value = true;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        // 获取屏幕宽度
        double dialogWidth = MediaQuery.of(context).size.width * 0.90;
        double dialogHeight = MediaQuery.of(context).size.height * 0.8;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          insetPadding: EdgeInsets.zero,
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      "文件列表",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FileListPage() // 你的内容
                ),),
                Obx(() {
                  return Pagination(
                    total: fileListCount.value,
                    totalPage: fileTotalCount.value,
                    currentPage: filePageNum.value,
                    onPageChanged: (page) {
                      fileList.clear();
                      fileList.refresh();
                      print("发生改变: $page");
                      filePageNum.value = page;
                      var temp = page == 1 ? 0 : page - 1;
                      fileStart.value = filePageSize.value * temp;
                      print("每页最多显示: $filePageSize, 读取的起始位置: $filePageNum, 读取位置: $fileStart");
                      readAudioFileList();
                    },
                  );
                }),
                const SizedBox(
                  height: 10,
                )
              ],
            ),
          ),
        );
      },
    ).then((res) {
      fileDialogShow.value = false;
    });
  }


}