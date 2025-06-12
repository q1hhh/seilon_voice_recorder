import 'package:Recording_pen/ble/ble_common_message.dart';

class BatteryLevelMessage extends BleMessage {
  var battery;

  BatteryLevelMessage(BleMessage bleMsg) {
    if (bleMsg.data.isNotEmpty) {
      battery = bleMsg.data[0];
    }
  }
}