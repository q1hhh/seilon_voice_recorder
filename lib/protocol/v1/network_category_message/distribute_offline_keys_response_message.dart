import '../../BleControlMessage.dart';

class DistributeOfflineKeysResponseMessage extends BleControlMessage {
  DistributeOfflineKeysResponseMessage(BleControlMessage message) {
    data = message.data;
  }
}