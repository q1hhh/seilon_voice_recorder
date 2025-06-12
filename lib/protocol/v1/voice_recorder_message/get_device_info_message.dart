import 'package:Recording_pen/protocol/BleControlMessage.dart';

import '../constants/LockControlCmd.dart';

class GetDeviceInfoMessage extends BleControlMessage {
  GetDeviceInfoMessage() {
    cmdCategory = LockControlCmd.CATEGORY_RECORDER;
    cmd = LockControlCmd.CMD_RECORDER_DEVICE_INFO;
  }
}