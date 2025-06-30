import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/log_util.dart';

class ReadAudioFileListReplyMessage extends BleControlMessage {
  int? fileCount; // 文件数量
  List? fileList;

  ReadAudioFileListReplyMessage(BleControlMessage ble) {
    LogUtil.log.i("读取文件列表===>$ble");
    cmd = ble.cmd;
    cmdCategory = ble.cmdCategory;

    data = ble.data;

    if (ble.isSuccess()) {
      fileCount = data[1];

      var fileData = data.sublist(2);

      for (int i = 0; i < fileData.length; i += 44) {
        // 每44切割
        int end = (i + 44 < fileData.length) ? i + 44 : fileData.length;
        // 每个文件
        var fileItem = fileData.sublist(i, end);
        // 文件名称
        var fileName = String.fromCharCodes(fileItem.sublist(0, 40));
        // 文件大小
        var fileSize = ByteUtil.getInt(fileItem.sublist(40), 0);
        fileList!.add({
          "fileName": fileName,
          "fileSize": fileSize
        });
      }
    }

  }

  @override
  String toString() {
    return '{fileCount: $fileCount fileList: $fileList}';
  }
}