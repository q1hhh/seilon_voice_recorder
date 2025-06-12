import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';

import '../constants/LockControlCmd.dart';

class OpenUDiskMessage extends BleControlMessage {

  OpenUDiskMessage(bool isOpen) {
    cmdCategory = LockControlCmd.CATEGORY_RECORDER;
    cmd = LockControlCmd.CMD_RECORDER_OPEN_U_DISK;

    if (isOpen) {
      data = Uint8List.fromList([1]);

    } else {
      data = Uint8List.fromList([0]);
    }
  }
}