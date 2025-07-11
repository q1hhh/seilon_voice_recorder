import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';

import '../../../util/ByteUtil.dart';
import '../constants/LockControlCmd.dart';

class StartOtaMessage extends BleControlMessage {
  StartOtaMessage(int type, int length, Uint8List checksum, String version) {
    cmdCategory = LockControlCmd.CATEGORY_SYSTEM;
    cmd = LockControlCmd.CMD_SPECIAL_REQUEST_UPGRADE;

    var data = Uint8List(24);

    data[0] = type & 0xff;
    data.setRange(1, 5, ByteUtil.getUint8ListOfInt(length), 0);
    data.setRange(5, 9, checksum, 0);
    data.setRange(9, 9 + version.length, version.codeUnits, 0);

    this.data = data;
  }
}