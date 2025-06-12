import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/ByteUtil.dart';

import '../constants/LockControlCmd.dart';

class ScreenControlMessage extends BleControlMessage {
  ScreenControlMessage(bool isOpen, int second, int brightness) {
    cmdCategory = LockControlCmd.CATEGORY_RECORDER;
    cmd = LockControlCmd.CMD_RECORDER_SCREEN_CONTROL;

    List<int> dataBytes = [];
    
    dataBytes.add(isOpen ? 1 : 0);
    dataBytes.addAll(ByteUtil.getUint8ListOfInt2(second));

    dataBytes.add(brightness);

    data = Uint8List.fromList(dataBytes);
  }
}