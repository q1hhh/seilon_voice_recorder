import 'dart:typed_data';
import '../../BleControlMessage.dart';
import '../constants/LockControlCmd.dart';
import '../../../util/ByteUtil.dart';

class UpgradeMessage extends BleControlMessage {
  UpgradeMessage(int type, int length, String checksum, String version) {
    cmdCategory = LockControlCmd.CATEGORY_SYSTEM;
    cmd = LockControlCmd.CMD_SPECIAL_REQUEST_UPGRADE;

    var data = Uint8List(24);
    data[0] = type & 0xff;
    data.setRange(1, 5, ByteUtil.getUint8ListOfInt(length), 0);
    data.setRange(5, 9, ByteUtil.hexStringToUint8ListLittleEndian(checksum), 0);
    data.setRange(9, 9 + version.length, version.codeUnits, 0);

    this.data = data;
  }
}