import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';

import '../constants/LockControlCmd.dart';

class OpenWifiMessage extends BleControlMessage {
  OpenWifiMessage(bool isOpen) {
    cmdCategory = LockControlCmd.CATEGORY_RECORDER;
    cmd = LockControlCmd.CMD_RECORDER_OPEN_WIFI;

    data = Uint8List.fromList([isOpen ? 1 : 0]);
  }
}