import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/log_util.dart';

class ReadAudioFileListReplyMessage extends BleControlMessage {
  int? fileCount; // 文件数量
  List? fileList;

  ReadAudioFileListReplyMessage(BleControlMessage ble) {
    fileList = [];
    LogUtil.log.i("读取文件列表===>$ble");
    cmd = ble.cmd;
    cmdCategory = ble.cmdCategory;

    data = ble.data;

    if (ble.isSuccess()) {
      // 文件数量
      fileCount = data[1];
      // 偏移量, 从data[2]开始
      int offset = 2;

      for (int i = 0; i < fileCount!; i++) {
        if (offset >= data.length) break;

        // 文件名长度
        int nameLen = data[offset];
        // LogUtil.log.i("文件名长度===>$nameLen");
        offset += 1;

        // 文件名
        List<int> nameBytes = data.sublist(offset, offset + nameLen);
        // LogUtil.log.i("文件名===>$nameBytes");

        String fileName = String.fromCharCodes(nameBytes);
        offset += nameLen;
        // LogUtil.log.i("文件名解析了的===>$fileName");


        // 文件大小
        if (offset + 4 > data.length) break;
        // LogUtil.log.i("文件大小===>$data.sublist(offset, offset + 4)");

        int fileSize = ByteUtil.getInt(data.sublist(offset, offset + 4), 0);
        // LogUtil.log.i("文件解析了的大小===>$fileSize");

        offset += 4;

        // 存入数组
        fileList!.add({
          "nameLength": nameLen,
          "fileName": fileName,
          "fileSize": fileSize,
        });
      }
      // 旧的
      // for (int i = 0; i < fileData.length; i += 44) {
      //   // 每44切割
      //   int end = (i + 44 < fileData.length) ? i + 44 : fileData.length;
      //   // 每个文件
      //   var fileItem = fileData.sublist(i, end);
      //
      //   // 文件名称
      //   var fileName = String.fromCharCodes(fileItem.sublist(0, 40));
      //   // 文件大小
      //   var fileSize = ByteUtil.getInt(fileItem.sublist(40), 0);
      //   fileList!.add({
      //     "fileName": fileName,
      //     "fileSize": fileSize
      //   });
      // }
    }

  }

  @override
  String toString() {
    return '{fileCount: $fileCount fileList: $fileList}';
  }
}