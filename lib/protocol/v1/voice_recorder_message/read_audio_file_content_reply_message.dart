import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/log_util.dart';

import '../../../util/crc_16_util.dart';

class ReadAudioFileContentReplyMessage extends BleControlMessage {
  List? fileContent; // 文件内容
  List<int>? fileContentCrc; // 文件内容crc16

  ReadAudioFileContentReplyMessage(BleControlMessage ble) {
    LogUtil.log.i("读取文件内容长度===》${ble.data.length}");
    cmd = ble.cmd;
    cmdCategory = ble.cmdCategory;

    data = ble.data;

    if (ble.isSuccess()) {
      // 取文件内容
      fileContent = data.sublist(1, data.length - 2);
      fileContentCrc = data.sublist(data.length - 2);

      var crcRes = Crc16Util.calculateBigEndian(Uint8List.fromList(fileContent as List<int>));
      LogUtil.log.i("设备回复的crc====>${fileContentCrc}");
      LogUtil.log.i("解析的crc====>$crcRes");
    }

  }

  @override
  String toString() {
    return '{fileContent: $fileContent fileContentCrc: $fileContentCrc}';
  }
}