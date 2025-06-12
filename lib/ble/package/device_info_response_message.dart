import 'dart:typed_data';

import 'package:Recording_pen/ble/ble_common_message.dart';
import 'package:Recording_pen/util/ByteUtil.dart';

class DeviceInfoResponseMessage extends BleMessage {
  var model;
  var mac;
  var firmwareVersion;
  var hardwareVersion;
  var serialNum;

  DeviceInfoResponseMessage(BleMessage bleMsg) {
    if (bleMsg.data.isNotEmpty) {

      Uint8List dataBytes = bleMsg.data;


      model = ByteUtil.safeStringFromBytes(bleMsg.data.sublist(0, 16));

      var macByte = dataBytes.sublist(16, 22);
      mac = ByteUtil.uint8ListToHexFull(macByte);

      var firmwareByte = dataBytes.sublist(22, 34);
      firmwareVersion = ByteUtil.safeStringFromBytes(firmwareByte);

      var hardwareByte = dataBytes.sublist(34, 42);
      hardwareVersion = ByteUtil.safeStringFromBytes(hardwareByte);

      var serialNumByte = dataBytes.sublist(42, 58);
      serialNum = ByteUtil.safeStringFromBytes(serialNumByte);
    }
  }

  @override
  String toString() {
    return '{model: $model, mac: $mac, firmwareVersion: $firmwareVersion, hardwareVersion: $hardwareVersion, serialNum: $serialNum}';
  }
}