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
import 'package:Recording_pen/protocol/v1/voice_recorder_message/screen_control_message.dart';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/log_util.dart';
import 'package:Recording_pen/util/my_pcm_util.dart';
import 'package:Recording_pen/util/view_log_util.dart';
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

import '../../protocol/v1/voice_recorder_message/real_time_streaming_message.dart';
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

class AssistantLogic extends GetxController {
  var homeLogic = Get.find<HomeControl>();

  // 按钮列表(读取信息)
  RxList actionBtnList = [].obs;

  var deviceInfo = GetStorage().read("deviceInfo");

  int lastSentCommandId = -1;

  final int turnOffRecording = 0x0300;

  var ssid;
  var apPassword;

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
      { "text": "开启录音(录音模式)", "press": () => controlSoundRecording(1, 0) },
      { "text": "开启录音(会议模式)", "press": () => controlSoundRecording(1, 1) },
      { "text": "关闭录音New", "press": () => controlSoundRecording(0, 0) },
      { "text": "打开U盘", "press": () => openUDisk(true) },
      { "text": "关闭U盘", "press": () => openUDisk(false) },
      { "text": "开启屏幕亮度", "press": () => screenControl(true) },
      { "text": "关闭屏幕亮度", "press": () => screenControl(false) },
      { "text": "打开WIFI", "press": () => openWifi(true) },
      { "text": "关闭WIFI", "press": () => openWifi(false) },
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
  openWifi(bool isOpen) {

    var bleLockPackage = BleControlPackage.toBleLockPackage(OpenWifiMessage(isOpen), 0);
    _sendMessage(bleLockPackage);
  }


  // 32位UUID
  String getAccountId() {
    // todo demo模拟Id
    return '8fdc3c5ed75d4eadb04283803516b1a3';
  }

  // 通用发送消息方法
  void _sendMessage(BleControlPackage bleLockPackage) {
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

      await file.writeAsBytes(Uint8List.fromList(data));

      print('文件已保存至: ${file.path}');
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
    ssid = wifiOpenMessage.apName;
    apPassword = wifiOpenMessage.apPassword;
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