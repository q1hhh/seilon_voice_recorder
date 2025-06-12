import 'dart:typed_data';


import '../../../util/ByteUtil.dart';
import '../../BleControlMessage.dart';

class BindDeviceResponseMessage extends BleControlMessage {
  var appid;

  BindDeviceResponseMessage(BleControlMessage message) {
    cmdCategory = message.cmdCategory;
    cmd = message.cmd;
    data = message.data;

    if (isFail()) {
      appid = ByteUtil.uint8ListToHex(data, 1);
    }

  }
}