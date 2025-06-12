import 'dart:typed_data';

class BleControlMessage {
  late int length = 0;
  late int cmdCategory = 0;
  late int cmd = 0;
  late Uint8List data = Uint8List(0);
  late int pid = 0;
  late int check = 0;
  late int dataCheck = 0;
  late int protocol = 0;


  static BleControlMessage parse(Uint8List bytes) {
  BleControlMessage message = BleControlMessage();
  message.data = (bytes);
  message.check = (message.countCheck());
  return message;
  }

  Uint8List toBytes() {
    length = (data == null ? 0 : data.length);
    Uint8List bytes =  Uint8List(length);
    if (length > 0) {
      bytes.setRange(0, length, data, 0);
    }
    check = countCheck();
    return bytes;
  }

  int countCheck() {
    int check = 0;
    if (data != null && data.length > 0) {
      for (int i = 0; i < data.length; i++) {
        check = (check ^ data[i]);
      }
    }
    return check;
  }

  bool isSuccess() {
    if (data.isNotEmpty) return data[0] == 0x00 ? true : false;
    return false;
  }

  bool isFail() {
    if(data.isEmpty) return true;
    return data[0] == 0x01 ? true : false;
  }

  @override
  String toString() {
    return 'BleControlMessage{length: $length, cmdCategory: $cmdCategory, cmd: $cmd, data: $data, pid: $pid, check: $check, dataCheck: $dataCheck, protocol: $protocol}';
  }
}