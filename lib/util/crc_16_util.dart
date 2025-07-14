import 'dart:typed_data';

class Crc16Util {
  static int _crc16(List<int> buffer) {
    int crc = 0xFFFF;

    for (int b in buffer) {
      crc ^= b;

      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }

    return crc;
  }

  /// 标准CRC32实现
  static int _crc32(List<int> buffer) {
    int crc = 0xFFFFFFFF;
    for (final b in buffer) {
      crc ^= b;
      for (int i = 0; i < 8; i++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc ^ 0xFFFFFFFF;
  }

  static Uint8List calculate(Uint8List data) {
    int crc = _crc16(data);
    return Uint8List.fromList([crc & 0xFF, (crc >> 8) & 0xFF]);
  }

  static Uint8List calculateBigEndian(Uint8List data) {
    int crc = _crc16(data);
    // Big-endian: high byte first, then low byte
    return Uint8List.fromList([(crc >> 8) & 0xFF, crc & 0xFF]);
  }

  /// 返回4字节大端（高位在前）的CRC32
  static Uint8List calculateCrc32BigEndian(Uint8List data) {
    int crc = _crc32(data);
    return Uint8List.fromList([
      (crc >> 24) & 0xFF,
      (crc >> 16) & 0xFF,
      (crc >> 8) & 0xFF,
      crc & 0xFF,
    ]);
  }

}