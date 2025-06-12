import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/log_util.dart';

class WifiOpenMessage extends BleControlMessage {

  String? apName;
  String? apPassword;

  WifiOpenMessage(BleControlMessage ble) {
    cmd = ble.cmd;
    cmdCategory = ble.cmdCategory;

    data = ble.data;

    if (ble.isSuccess()) {
      apName = String.fromCharCodes(data.sublist(1, 33));
      apPassword = String.fromCharCodes(data.sublist(33, 65));
    }
  }

  @override
  String toString() {
    return '{apName: $apName apPassword: $apPassword}';
  }
}