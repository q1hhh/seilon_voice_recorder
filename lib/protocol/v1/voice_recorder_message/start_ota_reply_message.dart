import '../../../util/ByteUtil.dart';
import '../../BleControlMessage.dart';

class StartOtaReplyMessage extends BleControlMessage {
  late int maxLength;

  StartOtaReplyMessage(BleControlMessage message) {
    cmdCategory = message.cmdCategory;
    cmd = message.cmd;
    data = message.data;
  }

  int getMaxLength() {
    //升级包数据最大长度。若无此2字节，则升级包数据最大长度为默认的224字节。
    if(data.length > 1) {
      maxLength = ByteUtil.getInt2(data, 1);
    } else {
      maxLength = 224;
    }
    return maxLength;
  }
}