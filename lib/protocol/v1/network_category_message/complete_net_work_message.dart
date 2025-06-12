import 'dart:typed_data';

import '../../BleControlMessage.dart';
import '../constants/LockControlCmd.dart';


class CompleteNetWorkMessage extends BleControlMessage {
  CompleteNetWorkMessage(bool isComplete) {
    cmdCategory = LockControlCmd.CATEGORY_NET_WORK;
    cmd = LockControlCmd.CMD_SYSTEM_COMPLETE_NET_WORK;
    var value = isComplete ? 0x00 : 0x01;
    data = Uint8List.fromList([value]);
  }
}