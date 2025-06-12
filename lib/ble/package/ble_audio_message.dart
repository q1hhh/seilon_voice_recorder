import 'dart:typed_data';

import 'package:Recording_pen/ble/ble_common_message.dart';

import '../../util/ByteUtil.dart';


class BleAudioMessage extends BleMessage {
  int? frameId; // ⾳频帧编号
  int? frameSize; // 当前OPUS编码帧的⼤⼩
  int? chunkId; // 当前分块编号, 从0开始，最⼤值为(Total Chunks - 1)
  int? totalChunks; // 总分块数
  int? timestamp; // ⾳频帧时间戳（毫秒）
  List<int> opusData = []; // OPUS编码数据

  BleAudioMessage(BleMessage ble) {
    frameId = ByteUtil.getInt2(ble.data, 0);
    frameSize = ByteUtil.getInt2(ble.data, 2);
    chunkId = ble.data[4];
    totalChunks = ble.data[5];

    timestamp = ByteUtil.bytesToInt64(ble.data.sublist(6, 14));

    Uint8List opusBytes = ble.data.sublist(14);

    if (totalChunks != null) {
      List<int> firstData = [00, 00, 00, frameSize!];
      int index = 0;
      for (int i = 0; i < totalChunks!; i++) {
        List<int> subData = opusBytes.sublist(index, index + frameSize!);
        index = index + frameSize!;

        opusData.addAll([...firstData, ...subData]);
      }
    }
  }

  @override
  String toString() {
    return 'BleAudioMessage{'
        'frameId: $frameId, '
        'frameSize: $frameSize, '
        'chunkId: $chunkId, '
        'totalChunks: $totalChunks, '
        'timestamp: $timestamp, '
        'opusData: $opusData}, '
        '}';
  }
}