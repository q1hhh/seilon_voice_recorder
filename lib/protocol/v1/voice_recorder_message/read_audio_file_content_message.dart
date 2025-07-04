import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/log_util.dart';

import '../constants/LockControlCmd.dart';

class ReadAudioFileContentMessage extends BleControlMessage {
  ReadAudioFileContentMessage(String fileName, int start, int length) {
    cmdCategory = LockControlCmd.CATEGORY_RECORDER;
    cmd = LockControlCmd.CMD_RECORDER_AUDIO_FILE_CONTENT;
    data = Uint8List(46);

    data.setRange(0, 40, ByteUtil.toFixedLengthBytes(fileName));
    LogUtil.log.i("名称--->${ByteUtil.toFixedLengthBytes(fileName)}");
    data.setRange(40, 44, ByteUtil.getUint8ListOfInt(start));
    data.setRange(44, 46, ByteUtil.getUint8ListOfInt2(length));
  }
}