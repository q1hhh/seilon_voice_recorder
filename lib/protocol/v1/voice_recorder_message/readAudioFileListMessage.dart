import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/ByteUtil.dart';

import '../constants/LockControlCmd.dart';

class ReadAudioFileListMessage extends BleControlMessage {
  ReadAudioFileListMessage(int start, int num) {
    cmdCategory = LockControlCmd.CATEGORY_RECORDER;
    cmd = LockControlCmd.CMD_RECORDER_AUDIO_FILE_LIST;
    data = Uint8List(5);

    var startByte = ByteUtil.getUint8ListOfInt(start);
    data.setRange(0, 4, startByte);
    data[4] = num;
  }
}