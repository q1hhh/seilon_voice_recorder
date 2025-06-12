import '../../BleControlMessage.dart';

class GetLockDataResponseMessage extends BleControlMessage {
  int volume = 0;
  int language = 0;
  String protocolVersion = '';
  GetLockDataResponseMessage(BleControlMessage message) {
    data = message.data;
    if (data[0] == 0x00) {
      for (var i = 0; i < data[1]; i++) {
        var value = ((data[(i * 3) + 4] & 0xff) << 8) + (data[(i * 3) + 3] & 0xff);
        if(data[(i * 3) + 2] == 3){
          language = value;
        }
        if(data[(i * 3) + 2] == 2){
          volume = value;
        }
      }
    }
  }
}