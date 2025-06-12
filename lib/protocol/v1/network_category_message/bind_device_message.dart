import 'dart:typed_data';

import '../../BleControlMessage.dart';
import '../constants/LockControlCmd.dart';

class BindDeviceMessage extends BleControlMessage {
  late String appId;

  BindDeviceMessage(String appId) {
    cmdCategory = LockControlCmd.CATEGORY_NET_WORK;
    cmd = LockControlCmd.CMD_SYSTEM_BIND_DEVICE;

    Uint8List data = Uint8List(32);
    data.setRange(0, 32, appId.codeUnits);

    this.data = data;
  }
}