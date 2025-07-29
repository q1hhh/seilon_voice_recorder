
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ManufacturerData {
  late BluetoothDevice device;
  late String uuid;
  late int firmId;
  late String mac;
  late int modelNo = 0;
  late int bind;
  late String bleVersion;
  var expandState;

  @override
  String toString() {
    return 'ManufacturerData{device: $device, uuid: $uuid, firmId: $firmId, mac: $mac, modelNo: $modelNo, bind: $bind, bleVersion: $bleVersion, expandState: $expandState}';
  }
}