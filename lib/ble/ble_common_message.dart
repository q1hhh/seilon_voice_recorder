import 'dart:typed_data';

import 'package:Recording_pen/util/ByteUtil.dart';

class BleMessage {
  var header = 0xAA;
  int type = 0;
  int length = 0;
  int version = 1;
  int crc16 = 0;
  late Uint8List data;

  //协议封装
  Uint8List toBytes() {
    // 1. 定义常量提高可读性
    const headerSize = 7;
    const magicNumber1 = 0x34;
    const magicNumber2 = 0x12;

    // 2. 安全处理null情况
    final int dataLength = data.length ?? 0;
    final overallLength = headerSize + dataLength;

    // 3. 一次性分配内存
    final overallData = Uint8List(overallLength);

    // 4. 写入头部信息
    overallData[0] = header;
    overallData[1] = type;

    // 5. 更安全的长度写入
    final lengthBytes = ByteUtil.getUint8ListOfInt2(dataLength & 0xFFFF);
    overallData.setRange(2, 4, lengthBytes);

    overallData[4] = version;
    // 6. 写入魔数
    overallData[5] = magicNumber1;
    overallData[6] = magicNumber2;

    // 7. 安全写入数据
    if (data != null && dataLength > 0) {
      overallData.setRange(headerSize, overallLength, data!);
    }

    return overallData;
  }


  // 解析返回的蓝牙数据
  void analysisData(Uint8List data) {
    assert (data[0] == 0xAA);

    type = data[1];

    length = ByteUtil.getInt2(data, 2);

    version = data[4];

    crc16 = ByteUtil.getInt2(data, 5);

    this.data = data.sublist(7);
  }

  @override
  String toString() {
    return '{header: $header, type: $type, length: $length, version: $version, crc16: $crc16, data: $data}';
  }
}