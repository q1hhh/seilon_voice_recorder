import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/log_util.dart';

class ReadAudioFileContentReplyMessage extends BleControlMessage {
  List? fileContent; // 文件内容
  int? fileContentCrc; // 文件内容crc16

  ReadAudioFileContentReplyMessage(BleControlMessage ble) {
    LogUtil.log.i("读取文件内容===》$ble");
    cmd = ble.cmd;
    cmdCategory = ble.cmdCategory;

    data = ble.data;

    if (ble.isSuccess()) {
      // 取文件内容
      fileContent = data.sublist(1, data.length - 2);
      fileContentCrc = ByteUtil.getInt2(data.sublist(data.length - 2), 0);
    }

  }

  @override
  String toString() {
    return '{fileContent: $fileContent fileContentCrc: $fileContentCrc}';
  }
}