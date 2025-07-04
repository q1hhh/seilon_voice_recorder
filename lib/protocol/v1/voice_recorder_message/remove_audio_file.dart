import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/log_util.dart';

import '../constants/LockControlCmd.dart';

class RemoveAudioFile extends BleControlMessage {
  RemoveAudioFile(String? fileName) {
    cmdCategory = LockControlCmd.CATEGORY_RECORDER;

    // fileName不为空, 则删除单个文件
    if(fileName != null) {
      data = Uint8List(40);
      cmd = LockControlCmd.CMD_RECORDER_AUDIO_FILE_REMOVE;
      LogUtil.log.i("文件名称转换==>${ByteUtil.toFixedLengthBytes(fileName)}");
      data.setRange(0, 40, ByteUtil.toFixedLengthBytes(fileName));
    }
    // 删除所有文件
    else {
      cmd = LockControlCmd.CMD_RECORDER_AUDIO_FILE_REMOVE_ALL;
    }
  }
}