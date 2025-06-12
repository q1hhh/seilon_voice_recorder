import 'dart:convert';
import 'dart:typed_data';

class ByteUtil {
  static final List<String> hexArray = "0123456789ABCDEF".split('');

  //字节 转 十六进制字符串
  static String uint8ListToHex(Uint8List bytes, int len) {
    List<String> hexChars = List.filled(len * 2, '');
    for (int j = 0; j < len; j++) {
      int v = bytes[j] & 0xFF;
      hexChars[j * 2] = hexArray[v >> 4];
      hexChars[j * 2 + 1] = hexArray[v & 0x0F];
    }
    return hexChars.join();
  }
  static Uint8List hexStringToUint8ListLittleEndian(String hexString) {
    List<int> bytes = [];
    for (int i = hexString.length - 2; i >= 0; i -= 2) {
      String hexByte = hexString.substring(i, i + 2);
      int byteValue = int.parse(hexByte, radix: 16);
      bytes.add(byteValue);
    }

    return Uint8List.fromList(bytes);
  }
  //字节 转 十六进制字符串
  static String uint8ListToHexFull(Uint8List bytes) {
    List<String> hexChars = List.filled(bytes.length * 2, '');
    for (int j = 0; j < bytes.length; j++) {
      int v = bytes[j] & 0xFF;
      hexChars[j * 2] = hexArray[v >> 4];
      hexChars[j * 2 + 1] = hexArray[v & 0x0F];
    }
    return hexChars.join();
  }

  //从数组的index处的连续4个字节获得一个int
  static int getLongInt(Uint8List data, int index) {
    return ((data[index + 3] & 0xff) << 24) +
        ((data[index + 2] & 0xff) << 16) +
        ((data[index + 1] & 0xff) << 8) +
        (data[index] & 0xff);
  }


  static Uint8List getUint8ListOfLongInt(int val) {
    Uint8List b = Uint8List(4);

    if (val >= 0xffffffff) {
      // 达到或超过最大值，使用0xFFFFFFFE
      b = Uint8List.fromList([0xFE, 0xFF, 0xFF, 0xFF]);
    } else {
      b[0] = (val & 0x00000000000000ff);
      b[1] = (val & 0x000000000000ff00) >> 8;
      b[2] = (val & 0x0000000000ff0000) >> 16;
      b[3] = (val & 0x00000000ff000000) >> 24;
    }

    return b;
  }

  //byte转string字符串（去空格）
  static String safeStringFromBytes(Uint8List bytes) {
    // 先找到第一个\0或非打印字符
    final end = bytes.indexWhere((b) => b == 0 || b < 32);
    final validRange = bytes.sublist(0, end == -1 ? bytes.length : end);

    // 再修剪尾部空格
    return String.fromCharCodes(validRange).trimRight();
  }


  //十六字符串 转 字节
  static Uint8List? hexStringToUint8List(String hexString) {
    if (hexString == null || hexString.isEmpty) {
      return null;
    }

    hexString = hexString.toUpperCase();
    int length = hexString.length ~/ 2;
    List<int> d = List.filled(length, 0);
    for (int i = 0; i < length; i++) {
      int pos = i * 2;
      d[i] = (charToByte(hexString[pos]) << 4 | charToByte(hexString[pos + 1]));
    }

    return Uint8List.fromList(d);
  }

  //十六字符串 转 字节
  static List<int> hexStringToList(String hexString) {

    hexString = hexString.toUpperCase();
    int length = hexString.length ~/ 2;
    List<int> d = List.filled(length, 0);
    for (int i = 0; i < length; i++) {
      int pos = i * 2;
      d[i] = (charToByte(hexString[pos]) << 4 | charToByte(hexString[pos + 1]));
    }

    return d;
  }

  static int charToByte(String c) {
    return "0123456789ABCDEF".indexOf(c);
  }

// 将int转换为4数组
  static Uint8List getUint8ListOfInt(int val) {
    Uint8List b = Uint8List(4);

    b[0] = (val & 0x000000ff);
    b[1] = (val & 0x0000ff00) >> 8;
    b[2] = (val & 0x00ff0000) >> 16;
    b[3] = (val & 0xff000000) >> 24;

    return b;
  }

  // 将int转换为2数组
  static Uint8List getUint8ListOfInt2(int val) {
    Uint8List b = Uint8List(2);

    b[0] = (val & 0x000000ff);
    b[1] = (val & 0x0000ff00) >> 8;

    return b;
  }

  // 高到低
  static Uint8List getUint8ListOfInt2BigEndian(int val) {
    Uint8List b = Uint8List(2);
    b[0] = (val & 0x0000ff00) >> 8;  // 高字节在前
    b[1] = (val & 0x000000ff);       // 低字节在后
    return b;
  }

  // 将数组转化成一个int(低到高)
  static int getLittleValue(Uint8List data) {
    int value = (data[1] << 8) | data[0];
    return value;
  }

  // 将int转换为1数组
  static Uint8List getUint8ListOfInt1(int val) {
    Uint8List b = Uint8List(1);

    b[0] = (val & 0x000000ff);

    return b;
  }

  // 从byte数组的index处的连续4个字节获得一个int
  static int getInt(Uint8List data, int index) {
    return ((data[index + 3] & 0xff) << 24) +
        ((data[index + 2] & 0xff) << 16) +
        ((data[index + 1] & 0xff) << 8) +
        (data[index] & 0xff);
  }

  // 从byte数组的index处的连续2个字节获得一个int
  static int getInt2(Uint8List data, int index) {
    return ((data[index + 1] & 0xff) << 8) +
        (data[index] & 0xff);
  }

  // 从byte数组的index处的连续1个字节获得一个int
  static int getInt1(Uint8List data, int index) {
    return (data[index] & 0xff);
  }
 
  // 转化广播值为设备类型
  static int getModelNo(List<int> typedArray) {
    var modelNo1 = containsLetterInHex(typedArray[0]) ? typedArray[0] : int.parse(typedArray[0].toRadixString(16));
    var modelNo2 = containsLetterInHex(typedArray[1]) ? typedArray[1] : int.parse(typedArray[1].toRadixString(16));
    return modelNo2 * 256 + modelNo1 ;
  }
  // 将十进制数转换为十六进制字符串  检查十六进制字符串中是否包含字母 A-F
  static  bool containsLetterInHex(int decimalNumber) { 
   String hexString = decimalNumber.toRadixString(16).toUpperCase(); 
   return hexString.contains(RegExp(r'[A-F]'));
  }

  /**
   * 8字节转int
   */
  static int bytesToInt64(Uint8List bytes) {
    if (bytes.length != 8) throw ArgumentError('必须提供 8 个字节');
    int result = 0;
    for (int i = 0; i < 8; i++) {
      result |= (bytes[i] & 0xFF) << (8 * i); // 小端序
    }
    return result;
  }

  /**
   * int转8字节
   */
  static Uint8List timestampToBytes(int timestamp) {
    final bytes = Uint8List(8);
    for (int i = 0; i < 8; i++) {
      bytes[i] = (timestamp >> (8 * i)) & 0xFF; // 小端序
    }
    return bytes;
  }

}
