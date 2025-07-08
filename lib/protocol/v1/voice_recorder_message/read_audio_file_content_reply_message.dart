import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/log_util.dart';

import '../../../util/crc_16_util.dart';

class ReadAudioFileContentReplyMessage extends BleControlMessage {
  int? start; // 当前内容的起始位置
  List? fileContent; // 文件内容
  List<int>? fileContentCrc; // 文件内容crc16

  ReadAudioFileContentReplyMessage(BleControlMessage ble) {
    cmd = ble.cmd;
    cmdCategory = ble.cmdCategory;

    data = ble.data;

    if (ble.isSuccess()) {
      start = ByteUtil.getInt(data, 1);
      // 取文件内容
      fileContent = data.sublist(5, data.length - 2);
      fileContentCrc = data.sublist(data.length - 2);

      var crcRes = Crc16Util.calculateBigEndian(Uint8List.fromList(fileContent as List<int>));
      // LogUtil.log.i("设备回复的crc====>${fileContentCrc}");
      // LogUtil.log.i("解析的crc====>$crcRes");
      if(fileContentCrc?[0] != crcRes[0] || fileContentCrc?[1] != crcRes[1]) {
        LogUtil.log.e("CRC16错误: 设备回复的crc====>${fileContentCrc}, 解析的crc====>$crcRes");
      }
    }

  }

  @override
  String toString() {
    return '{fileContent: $fileContent fileContentCrc: $fileContentCrc}';
  }
}