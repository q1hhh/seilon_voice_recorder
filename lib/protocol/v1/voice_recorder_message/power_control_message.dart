import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';

import '../constants/LockControlCmd.dart';

class PowerControlMessage extends BleControlMessage {
  PowerControlMessage(int value) {
    cmdCategory = LockControlCmd.CATEGORY_RECORDER;
    cmd = LockControlCmd.CMD_RECORDER_POWER_OFF;

    data = Uint8List.fromList([value]);
  }
}