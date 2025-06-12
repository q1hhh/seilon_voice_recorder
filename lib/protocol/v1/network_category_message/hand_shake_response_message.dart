import 'dart:convert';
import 'dart:typed_data';

import '../../../util/ByteUtil.dart';
import '../../BleControlMessage.dart';

class HandShakeResponseMessage extends BleControlMessage {
  var aesKey;//交互密钥
  var bleMac;//蓝牙mac；
  var protocalVersion;//协议版本
  var product;//设备型号
  var moduleVersion;//模块版本
  var wakSource;//唤醒源
  var firtLockVersion;//前锁版本
  var backLockVersion;//后锁版本

  HandShakeResponseMessage(BleControlMessage message) {
    cmdCategory = message.cmdCategory;
    cmd = message.cmd;
    data = message.data;

    if (isSuccess()) {
      print('data len:${data.length}');

      var aesKeyByte = Uint8List(16);
      aesKeyByte.setRange(0, 16, data, 1);


      aesKey = ByteUtil.uint8ListToHexFull(aesKeyByte);

      Uint8List macByte = Uint8List(12);
      macByte.setRange(0, 12, data, 17);

      bleMac = utf8.decode(macByte).replaceAll(RegExp(r'\u0000'), '');

      var protocalByte = Uint8List(3);
      protocalByte.setRange(0, 3, message.data, 29);

      protocalVersion = utf8.decode(protocalByte).replaceAll(RegExp(r'\u0000'), '');

      var productByte = Uint8List(8);
      productByte.setRange(0, 8, message.data, 32);

      product = utf8.decode(productByte).replaceAll(RegExp(r'\u0000'), '');

      var moduleVersionByte = Uint8List(15);
      moduleVersionByte.setRange(0, 15, message.data, 40);

      moduleVersion = utf8.decode(moduleVersionByte).replaceAll(RegExp(r'\u0000'), '');

      ByteUtil.getInt2(data, 55);

      if (data.length > 57) {
        var firtLockVersionByte = Uint8List(15);
        firtLockVersionByte.setRange(0, 15, data, 57);

        firtLockVersion = utf8.decode(firtLockVersionByte).replaceAll(RegExp(r'\u0000'), '');
      }

      if (data.length > 72) {
        var backLockVersionByte = Uint8List(15);
        backLockVersionByte.setRange(0, 15, data, 72);

        backLockVersion = utf8.decode(backLockVersionByte).replaceAll(RegExp(r'\u0000'), '');
      }

    }


  }

  @override
  String toString() {
    return 'HandShakeResponseMessage{aesKey: $aesKey, bleMac: $bleMac, protocalVersion: $protocalVersion, product: $product, moduleVersion: $moduleVersion, wakSource: $wakSource, firtLockVersion: $firtLockVersion, backLockVersion: $backLockVersion}';
  }
}