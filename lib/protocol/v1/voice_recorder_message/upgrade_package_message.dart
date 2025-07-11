import 'dart:typed_data';
import '../../../util/ByteUtil.dart';
import '../../../util/crc_16_util.dart';
import '../../BleControlMessage.dart';
import '../constants/LockControlCmd.dart';

class UpgradePacketMessage extends BleControlMessage {
  UpgradePacketMessage(int type, int index, Uint8List data) {
    cmdCategory = LockControlCmd.CATEGORY_SYSTEM;
    cmd = LockControlCmd.CMD_SPECIAL_SEND_UPGRADE_DATA;

    var temp = Uint8List(data.length + 5);

    temp[0] = type & 0xff;
    temp.setRange(1, 3, ByteUtil.getUint8ListOfInt2(index));
    temp.setRange(3,  3 + data.length, data);

    var calculate = Crc16Util.calculateBigEndian(data);

    print('data check $check');

    temp.setRange(3 + data.length, temp.length, calculate);


    print( '----------${ByteUtil.uint8ListToHexFull(temp)}');
    this.data = temp;
  }
}