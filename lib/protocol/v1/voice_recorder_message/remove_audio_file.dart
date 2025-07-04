import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/ByteUtil.dart';

import '../constants/LockControlCmd.dart';

class RemoveAudioFile extends BleControlMessage {
  RemoveAudioFile(String? fileName) {
    cmdCategory = LockControlCmd.CATEGORY_RECORDER;

    // fileName不为空, 则删除单个文件
    if(fileName != null) {
      cmd = LockControlCmd.CMD_RECORDER_AUDIO_FILE_REMOVE;
      data.setRange(0, 40, ByteUtil.hexStringToList(fileName));
    }
    // 删除所有文件
    else {
      cmd = LockControlCmd.CMD_RECORDER_AUDIO_FILE_REMOVE_ALL;
    }
  }
}