
import 'dart:convert';
import 'dart:typed_data';

import '../../../util/ByteUtil.dart';
import '../../BleControlMessage.dart';

class GetTripletsResponseMessage extends BleControlMessage {
  var productId;
  var deviceName;
  var deviceSecret;
  var wifiMac;

  GetTripletsResponseMessage(BleControlMessage message) {
    cmdCategory = message.cmdCategory;
    cmd = message.cmd;
    data = message.data;

    if (isSuccess()) {
      int index = 1;
      var productIdLen = data[index];//productId长度

      if (productIdLen > 0) {
        var productIdByte = Uint8List(productIdLen);
        ;

        productIdByte.setRange(0, productIdLen, data, index + 1);//2
        productId = String.fromCharCodes(productIdByte).replaceAll(RegExp(r'\u0000'), '');;
        print(productId);
      }
      index = index + productIdLen;


      index++;
      var deviceNameLen = data[index];
      if (deviceNameLen > 0) {
        var deviceNameByte = Uint8List(deviceNameLen);
        index++;
        deviceNameByte.setRange(0, deviceNameLen, data, index);
        deviceName = String.fromCharCodes(deviceNameByte).replaceAll(RegExp(r'\u0000'), '');;
        print(deviceName);
      }
      index = index + deviceNameLen;

      // index++;
      var deviceSecretLen = data[index];
      if (deviceSecretLen > 0) {
        print(deviceSecretLen);
        var deviceSecretByte = Uint8List(deviceSecretLen);
        index++;
        deviceSecretByte.setRange(0, deviceSecretLen, data, index + 1);
        deviceSecret = String.fromCharCodes(deviceSecretByte).replaceAll(RegExp(r'\u0000'), '');;
        print(deviceSecret);
      }
      index = index + deviceSecretLen;

      // index++;
      var wifiMacLen = data[index];
      if(wifiMacLen > 0) {
        var wifiMacByte = Uint8List(wifiMacLen);
        index++;
        wifiMacByte.setRange(0, wifiMacLen, data, index);
        wifiMac = ByteUtil.uint8ListToHexFull(wifiMacByte).replaceAll(RegExp(r'\u0000'), '');;
      }

    }
  }

  @override
  String toString() {
    return 'GetTripletsResponseMessage{productId: $productId, deviceName: $deviceName, deviceSecret: $deviceSecret, wifiMac: $wifiMac}';
  }
}