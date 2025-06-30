import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/ByteUtil.dart';

class TcpServerParseMessage extends BleControlMessage {
  List? tcpIp;
  int? tcpPort;

  TcpServerParseMessage(BleControlMessage ble) {
    cmd = ble.cmd;
    cmdCategory = ble.cmdCategory;

    data = ble.data;

    if (ble.isSuccess()) {
      tcpIp = data.sublist(1, 5);
      tcpPort = ByteUtil.getInt2(data, 5);
    }
  }

  @override
  String toString() {
    return '{tcpIp: $tcpIp tcpPort: $tcpPort}';
  }
}