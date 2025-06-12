import 'package:Recording_pen/protocol/BleControlMessage.dart';

import '../constants/LockControlCmd.dart';

class SetBleNameMessage extends BleControlMessage {

  SetBleNameMessage() {
    cmdCategory = LockControlCmd.CATEGORY_RECORDER;
    cmd = LockControlCmd.CMD_RECORDER_SET_BLE_NAME;
  }
}