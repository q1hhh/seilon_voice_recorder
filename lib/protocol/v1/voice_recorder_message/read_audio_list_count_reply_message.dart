import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/log_util.dart';

class ReadAudioListCountReplyMessage extends BleControlMessage {
  int? fileCount; // 总数量
  int? pageCount; // 单页最大数量
  int? maxFileContentLength; // 单次拉取的文件内容最大长度

  ReadAudioListCountReplyMessage(BleControlMessage ble) {
    LogUtil.log.i("读取文件列表数量===》$ble");
    cmd = ble.cmd;
    cmdCategory = ble.cmdCategory;

    data = ble.data;

    if (ble.isSuccess()) {
      fileCount = ByteUtil.getInt2(data, 1);
      pageCount = data[3];
      fileCount = ByteUtil.getInt2(data, 4);
    }

  }

  @override
  String toString() {
    return '{fileCount: $fileCount pageCount: $pageCount maxFileContentLength: $maxFileContentLength}';
  }
}