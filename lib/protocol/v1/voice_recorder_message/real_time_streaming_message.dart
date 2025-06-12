import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';

class RealTimeStreamingMessage extends BleControlMessage {
  int? totalChunks; // 总分块数
  List<List<int>> opusData = []; // OPUS编码数据

  RealTimeStreamingMessage(BleControlMessage message) {
    length = message.length;
    cmdCategory = message.cmdCategory;
    cmd = message.cmd;
    data = message.data;

    totalChunks = data[0];

    Uint8List opusBytes = data.sublist(1);

    if (totalChunks != null && totalChunks != 0) {
      double dataLength = (opusBytes.length / totalChunks!);
      List<int> firstData = [00, 00, 00, dataLength.toInt()];
      int index = 0;

      for (int i = 0; i < totalChunks!; i++) {
        List<int> subData = opusBytes.sublist(index, index + dataLength.toInt());
        index = index + dataLength.toInt();

        opusData.add([...firstData, ...subData]);
      }
    }

  }
}