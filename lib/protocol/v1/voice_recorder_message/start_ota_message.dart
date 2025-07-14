import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/log_util.dart';
import 'package:get/get.dart';

import '../../../util/ByteUtil.dart';
import '../constants/LockControlCmd.dart';

class StartOtaMessage extends BleControlMessage {
  StartOtaMessage(int type, int length, String checksum, String version) {
    cmdCategory = LockControlCmd.CATEGORY_SYSTEM;
    cmd = LockControlCmd.CMD_SPECIAL_REQUEST_UPGRADE;

    var data = Uint8List(24);

    data[0] = type & 0xff;
    data.setRange(1, 5, ByteUtil.getUint8ListOfInt(length));

    data.setRange(5, 9, ByteUtil.hexStringToUint8ListLittleEndian(checksum) + List.filled(2, 0));

    var versionBytes = ByteUtil.toFixedLengthBytes(version, length: 15);
    data.setRange(9, 9 + versionBytes.length, versionBytes);
    LogUtil.log.i("开始升级==> 类型: ${data[0]}, bin文件大小: ${data.getRange(1, 5)}, CRC: ${data.getRange(5, 9)}, 版本号: ${data.getRange(9, 24)}");
    this.data = data;
  }
}