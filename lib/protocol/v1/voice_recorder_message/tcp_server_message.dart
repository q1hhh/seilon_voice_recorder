import 'package:Recording_pen/protocol/BleControlMessage.dart';

import '../constants/LockControlCmd.dart';

class TcpServerMessageMessage extends BleControlMessage {
  TcpServerMessageMessage() {
    cmdCategory = LockControlCmd.CATEGORY_RECORDER;
    cmd = LockControlCmd.CMD_RECORDER_QUERY_TCP_SERVICE;
  }
}