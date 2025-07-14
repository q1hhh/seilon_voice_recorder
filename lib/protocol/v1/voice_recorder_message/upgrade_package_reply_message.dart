import '../../../util/ByteUtil.dart';
import '../../BleControlMessage.dart';

class UpgradePackageReplyMessage extends BleControlMessage {
  late int packetIndex;

  UpgradePackageReplyMessage(BleControlMessage message) {
    cmdCategory = message.cmdCategory;
    cmd = message.cmd;
    data = message.data;

    if (isSuccess()) {
      packetIndex = ByteUtil.getInt2(data, 1);
    }
  }

  bool isComplete() {
    if (data.isNotEmpty) return data[0] == 0x02 ? true : false;
    return false;
  }
}