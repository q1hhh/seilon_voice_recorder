import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';

import '../constants/LockControlCmd.dart';

class OtaMessage extends BleControlMessage {
  OtaMessage(Uint8List otaData) {
    cmdCategory = LockControlCmd.CATEGORY_RECORDER;
    cmd = LockControlCmd.CMD_RECORDER_OPEN_WIFI;

    data = otaData;
  }
}