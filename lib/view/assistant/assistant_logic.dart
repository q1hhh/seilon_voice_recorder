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
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/log_util.dart';
import 'package:Recording_pen/util/my_pcm_util.dart';
import 'package:Recording_pen/util/view_log_util.dart';
import 'package:app_settings/app_settings.dart';
import 'package:date_format/date_format.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
import 'package:wifi_iot/wifi_iot.dart';
import '../../ble/package/control_message.dart';
import '../../ble/package/hand_shake_message.dart';
import 'package:uuid/uuid.dart';

import '../../controllers/deviceInfo_control.dart';
import '../../protocol/v1/constants/LockControlCmd.dart';
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
import '../../common/shared/my_configurator.dart';
import '../../constant/my_app_common.dart';
import '../../protocol/BleControlPackage.dart';
import '../../protocol/v1/network_category_message/bind_device_message.dart';
import '../../protocol/v1/network_category_message/complete_net_work_message.dart';
import '../../protocol/v1/network_category_message/hand_shake_message.dart';
import '../../protocol/v1/voice_recorder_message/control_sound_record_message.dart';
import '../../protocol/v1/voice_recorder_message/get_device_info_message.dart';
import '../../theme/app_colors.dart';
import '../../util/crc_16_util.dart';
import '../../util/tcp_util.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';

class AssistantLogic extends GetxController {
  var homeLogic = Get.find<HomeControl>();

  // 读取内容的文件名
  RxString currentFileName = "".obs;
  // 读取内容的文件大小
  RxInt currentFileSize = 0.obs;
  
  // 暂存读取文件的内容
  RxList fileListContent = [].obs;

  // 文件列表总共多少页
  RxInt filePageCount = 0.obs;

  // 当前读取文件列表的位置(页码)
  RxInt filePageNum = 0.obs;

  // 每页最多读16
  RxInt filePageSize = 16.obs;

  // 读取到的文件的总数量
  RxInt fileListCount = 0.obs;

  //读取到的文件列表
  RxList fileList = [].obs;

  // 按钮列表(读取信息)
  RxList actionBtnList = [].obs;

  var deviceInfo = GetStorage().read("deviceInfo");

  int lastSentCommandId = -1;

  final int turnOffRecording = 0x0300;

  Timer? timeoutTimer;

  int expectedOffset = 0; // 当前期望收到的start

  Completer<void>? responseCompleter;
  // 收到的数据总长度
  int dataCount = 0;


  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  @override
  onInit() {
    actionBtnList.addAll([
      { "text": "进入绑定", "press": startBindDevice },
      { "text": "开始握手", "press": startHandShake },
      { "text": "完成绑定", "press": completeBinding },
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
      { "text": "读取单个音频文件内容", "press": () => readAudioFileContent() },
      { "text": "删除单个文件", "press": () => removeAudioFile(fileList[2]['fileName']) },
      { "text": "删除所有文件", "press": () => removeAudioFile(null) },
      { "text": "进入OTA升级模式", "press": () => startOTA() },
      { "text": "开始OTA升级", "press": () => sendOTAData() },
      { "text": "清空本地存储的文件", "press": () => clearOpusFiles() },
      { "text": "清空日志", "press": clearLog },
    ]);
  }

  initPcmSound() async {
    // 1. 初始化
    await FlutterPcmSound.setup(sampleRate: 16000, channelCount: 1);
    FlutterPcmSound.setFeedThreshold(1024);
    FlutterPcmSound.start();
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
      BleService().writeData(targetDevice, bytes);
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
      BleService().writeData(targetDevice, bytes);
    } else {
      LogUtil.log.e("设备未连接或找不到设备: ${deviceInfo["deviceId"]}");
    }
  }

  // 完成绑定
  completeBinding() {
    var bleLockPackage = BleControlPackage.toBleLockPackage(CompleteNetWorkMessage(true), 0);
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
      initPcmSound();
    }
    if (control == 0) {
      lastSentCommandId = turnOffRecording;
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
    Clipboard.setData(ClipboardData(text: DeviceInfoController().password.value));
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
    var bleLockPackage = BleControlPackage.toBleLockPackage(ReadAudioFileListMessage(filePageNum.value, filePageSize.value), 0);
    _sendMessage(bleLockPackage);

    if(filePageNum.value < filePageCount.value) {
      filePageNum.value++;
    }
    else {
      filePageNum.value = 0;
    }
  }

  // 读取单个音频文件内容
  readAudioFileContent() async {
    if(fileList.isEmpty) return;
    // if(DeviceInfoController().messageType.value == "TCP") {
    //   readAudioFileContentTCP();
    //   return;
    // }
    TcpUtil().dataTotal = 0;
    TcpUtil().tempData.clear();
    fileListContent.clear();
    fileListContent.refresh();
    var fileName = fileList[1]['fileName'];
    var fileSize = fileList[1]['fileSize'];
    print("读取的文件--$fileName--$fileSize");

    currentFileName.value = fileName;
    currentFileSize.value = fileSize;

    // 每次读取900字节
    int chunkSize = 900;
    int readNum = 0;

    var bleLockPackage = BleControlPackage.toBleLockPackage(ReadAudioFileContentMessage(fileName, 0, 900), 0);
    _sendMessage(bleLockPackage);
    // for (int offset = 0; offset < fileSize; offset += chunkSize) {
    //   readNum++;
    //   int len = (fileSize - offset) >= chunkSize ? chunkSize : (fileSize - offset);
    //   LogUtil.log.i("读取次数===>${readNum}----读取的长度${len}");
    //
    //   var bleLockPackage = BleControlPackage.toBleLockPackage(ReadAudioFileContentMessage(fileName, offset, len), 0);
    //   _sendMessage(bleLockPackage);
    // }

  }

  // Future<void> readAudioFileContentTCP() async {
  //   if (fileList.isEmpty) return;
  //
  //   fileListContent = [];
  //   var fileName = fileList[0]['fileName'];
  //   var fileSize = fileList[0]['fileSize'];
  //   print("读取的文件--$fileName--$fileSize");
  //
  //   currentFileName = fileName;
  //   currentFileSize = fileSize;
  //
  //   int chunkSize = 900;
  //   int readNum = 0;
  //
  //   for (TcpUtil().startOffset; TcpUtil().startOffset < fileSize; TcpUtil().startOffset += chunkSize) {
  //     readNum++;
  //     int len = (fileSize - TcpUtil().startOffset) >= chunkSize ? chunkSize : (fileSize - TcpUtil().startOffset);
  //     LogUtil.log.i("读取次数===>${readNum}----读取的长度${len}");
  //
  //     var bleLockPackage = BleControlPackage.toBleLockPackage(
  //       ReadAudioFileContentMessage(fileName, TcpUtil().startOffset, len),
  //       0,
  //     );
  //
  //     timeoutTimer = Timer(Duration(seconds: 1), () async {
  //       if (!(TcpUtil().responseCompleter?.isCompleted ?? true)) {
  //         LogUtil.log.w("响应超时，重发offset=${TcpUtil().startOffset}");
  //         await TcpUtil().sendDataAndWait(bleLockPackage);
  //       }
  //     });
  //
  //     // 这里调用 sendDataAndWait 等待响应
  //     await TcpUtil().sendDataAndWait(bleLockPackage);
  //   }
  //   print("所有分包发送完成");
  // }

  Future<void> readAudioFileContentTCP() async {
    if (fileList.isEmpty) return;
    fileListContent.clear();
    fileListContent.refresh();

    var fileName = fileList[0]['fileName'];
    var fileSize = fileList[0]['fileSize'];
    print("读取的文件--$fileName--$fileSize");

    currentFileName.value = fileName;
    currentFileSize.value = fileSize;

    int chunkSize = 900;
    int readNum = 0;
    int offset = 0;

    while (offset < fileSize) {
      expectedOffset = offset;
      readNum++;
      int len = (fileSize - offset) >= chunkSize ? chunkSize : (fileSize - offset);

      LogUtil.log.i("当前发送位置: $offset, 当前发送次数: $readNum");
      var bleLockPackage = BleControlPackage.toBleLockPackage(
        ReadAudioFileContentMessage(fileName, offset, len),
        0,
      );
      responseCompleter = Completer<void>();

      // 发送一次
      TcpUtil().sendDataAndWait(bleLockPackage.toBytes(MyAppCommon.DEVICE_DEFAULT_KEY));

      // 启动1秒超时定时器
      timeoutTimer = Timer(Duration(seconds: 1), () {
        if (!(responseCompleter?.isCompleted ?? true)) {
          LogUtil.log.w("响应超时，重发offset=$offset");
          TcpUtil().sendDataAndWait(bleLockPackage.toBytes(MyAppCommon.DEVICE_DEFAULT_KEY));
        }
      });

      // 等待响应
      await responseCompleter!.future;
      timeoutTimer?.cancel();

      offset += len;
    }
    print("所有分包发送完成, 发送次数: $readNum");
  }


  // 删除文件
  removeAudioFile(String? fileName) {
    if(fileList.isEmpty) return;
    LogUtil.log.i("删除的文件名--->$fileName");
    var bleLockPackage = BleControlPackage.toBleLockPackage(RemoveAudioFile(fileName), 0);
    _sendMessage(bleLockPackage);
  }

  // 开始OTA升级
  startOTA() async {
    ByteData data = await rootBundle.load('assets/ota_all_4.4.0.05.bin');
    LogUtil.log.i("OTA升级文件大小-->${data.buffer.asUint8List().length}");
    Uint8List otaBytes = data.buffer.asUint8List();

    Uint8List checkSum = Crc16Util.calculateBigEndian(otaBytes);

    var bleLockPackage = BleControlPackage.toBleLockPackage(StartOtaMessage(2, otaBytes.length, checkSum, ""), 0);

    _sendMessage(bleLockPackage);
  }

  // OTA升级
  sendOTAData() async {

    //
    // // 减去固定的
    // int maxLength = 1460 - 32;
    //
    // for(var i = 0; i < otaLength; i += maxLength) {
    //   int end = (i + maxLength < otaLength) ? (i + maxLength) : otaLength;
    //
    //   // 每包发送的数据
    //   Uint8List otaData = data.buffer.asUint8List().sublist(i, end);
    //
    //   // var bleLockPackage = UpgradePacketMessage(otaData);
    //
    //   // _sendMessage(bleLockPackage);
    //
    //   LogUtil.log.i("分包：offset=$i, end=$end, 长度=${otaData.length}");
    //   await Future.delayed(Duration(milliseconds: 20));
    // }
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
          if (ext == '.opus') {
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
        BleService().writeData(targetDevice, bytes);
      } else {
        LogUtil.log.e("设备未连接或找不到设备: ${deviceInfo["deviceId"]}");
      }
    }
    // TCP模式
    else {
      // 发一包等响应
      await TcpUtil().sendDataAndWait(bytes);
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
      FlutterPcmSound.release();

      await writeToExternalStorage(Uint8List.fromList(allOpusData), '${DateFormat('yyyy-MM-dd_HH_mm_ss').format(DateTime.now())}.opus');
      await saveWav('${DateFormat('yyyy-MM-dd_HH_mm_ss').format(DateTime.now())}.wav');
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

  Future<void> writeToExternalStorage(Uint8List data, String fileName) async {
    if (await requestStoragePermission()) {
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

      }
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
      BleService().writeData(targetDevice, directive);
    } else {
      LogUtil.log.e("设备未连接或找不到设备: ${deviceInfo["deviceId"]}");
    }
  }

  List<int> allOpusData = [];

  List<int> opusData = [];

  // opus 裸流数据
  void dealAudioMessage(RealTimeStreamingMessage realTimeStreamingMessage) {


    for (final msg in realTimeStreamingMessage.opusData) {
      allOpusData.addAll(msg); // 累积全量数据（如果你需要保存）
      opusData.addAll(msg);
    }
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
    // 先计算总共多少页(每页最多16个)
    fileListCount.value = audioListCountMessage.fileCount ?? 0;
    filePageCount.value = (fileListCount.value / filePageSize.value).ceil();

    ViewLogUtil.info("文件数量--->${audioListCountMessage}");
    ViewLogUtil.info("文件页数--->${filePageCount.value}");

  }

  // 读取音频文件列表(回复)
  dealAudioList(BleControlMessage ble) {
    var audioListMessage = ReadAudioFileListReplyMessage(ble);
    fileList.value = audioListMessage.fileList ?? [];
    ViewLogUtil.info(audioListMessage.toString());
    ViewLogUtil.info("当前位置: (${filePageNum.value}/${filePageCount.value})");
  }

  // 读取音频文件内容(回复)
  // dealAudioFileContent(BleControlMessage ble) async {
  //   var audioListContentMessage = ReadAudioFileContentReplyMessage(ble);
  //   LogUtil.log.i("收到的长度${audioListContentMessage.fileContent?.length} -- 位置${audioListContentMessage.start}");
  //
  //   // 记录TCP回复的文件内容位置
  //   TcpUtil().tcpOffset = audioListContentMessage.start!;
  //
  //   // 位置相等才存入数组中
  //   if((TcpUtil().startOffset - 900) == TcpUtil().tcpOffset) {
  //     fileListContent.addAll(audioListContentMessage.fileContent as List<int>);
  //   }
  //   else {
  //     LogUtil.log.e("收到的包start不对，丢弃！收到${TcpUtil().tcpOffset}, 期望${TcpUtil().startOffset - 900}");
  //   }
  //
  //   // 将内容存在本地
  //   if ((currentFileSize == fileListContent.length) && await requestStoragePermission()) {
  //     await writeToFile(fileListContent as List<int>, currentFileName);
  //   }
  // }

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
      // await writeToFile(fileListContent.value.cast<int>(), currentFileName.value);
      await writeToExternalStorage(Uint8List.fromList(fileListContent.value.cast<int>()), currentFileName.value);
    }
  }



  Future<Uint8List> decodeOpusToPCM(Uint8List opusData) async {
    const int sampleRate = 16000;
    const int channels = 1;

    // 初始化解码器
    final decoder = SimpleOpusDecoder(
      sampleRate: sampleRate,
      channels: channels,
    );
    final pcm = decoder.decode(input: opusData); // Uint8List opusData 是一帧

    // 转为 Uint8List（写文件用）
    final Uint8List pcmBytes = pcm.buffer.asUint8List(
      pcm.offsetInBytes,
      pcm.lengthInBytes
    );

    decoder.destroy();
    return pcmBytes;
  }


  Future<void> saveWav(String fileName) async {
    LogUtil.log.i("录音数据--->$allOpusData");
    Uint8List pcmData = await MyPcmUtil.decodeAllOpus(Uint8List.fromList(allOpusData));

    var channels = 1;
    // 双声道
    if(allOpusData[3] > 40) {
      channels = 2;
    }

    // final file = File('/storage/emulated/0/Download/output.pcm');
    // await file.writeAsBytes(pcmData);

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


}