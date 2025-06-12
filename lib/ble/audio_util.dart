import 'dart:io';
import 'dart:typed_data';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/log_util.dart';
import 'package:Recording_pen/view/assistant/assistant_logic.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'ble_audio_message.dart';
import 'package:get/get.dart';

class AudiosUtil {
  static final AudiosUtil _instance = AudiosUtil._internal();
  factory AudiosUtil() {
    return _instance;
  }

  AudiosUtil._internal();

  // 根据frameId存储分块数据
  final List frameData = [];

  // 接收数据
  void receiveData(frameData) {
    // LogUtil.log.i(frameData);
    analysisData(frameData);
  }

  // 解析BLE数据包
  void analysisData(List data) {
    updateAudioData(data);
  }

  void updateAudioData(List opusData) {

    // 检查当前帧是否完整
    // if (bleAudioMessage.frameSize == bleAudioMessage.opusData?.length) {
      // 存储分块
      frameData.add(opusData);
      // LogUtil.log.i(opusData);
    // }
  }

  Uint8List handleOpusData()  {
    List<int> mergeData = [];

    // 合并所有 opusData
    for(var i = 0; i < frameData.length; i++) {
      mergeData.addAll(frameData[i]);
    }

    return Uint8List.fromList(mergeData);
  }

  void clearFrame() {
    frameData.clear();
  }
}