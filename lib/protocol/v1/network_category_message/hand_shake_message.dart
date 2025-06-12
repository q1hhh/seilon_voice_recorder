import 'dart:typed_data';
import '../../../util/my_date_utils.dart';
import '../../BleControlMessage.dart';
import '../constants/LockControlCmd.dart';

class HandshakeMessage extends BleControlMessage {
  late Uint8List aesKey;
  late String mac;
  late String protocolVersion;
  late String product;
  late String firmwareVersion;
  late String wakeSource;
  late String firstLockVersion;
  late String backLockVersion;

  HandshakeMessage(String appId) {
    cmdCategory = LockControlCmd.CATEGORY_NET_WORK;
    cmd = LockControlCmd.CMD_SYSTEM_VERIFY_USER;

    Uint8List data = Uint8List(39);
    data.setRange(0, 32, appId.codeUnits);

    var hexadecimalTime = MyDateUtils.getHexadecimalTime(DateTime.now().millisecondsSinceEpoch);
    data.setRange(32, 38, hexadecimalTime, 0);

    data[38] = DateTime.now().timeZoneOffset.inHours;
    this.data = data;
  }
}