import 'dart:convert';
import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';
import 'package:Recording_pen/util/ByteUtil.dart';
import 'package:Recording_pen/util/log_util.dart';

class WifiOpenMessage extends BleControlMessage {

  String? apName;
  String? apPassword;

  WifiOpenMessage(BleControlMessage ble) {
    cmd = ble.cmd;
    cmdCategory = ble.cmdCategory;

    data = ble.data;

    if (ble.isSuccess()) {
      apName = fixedBytesToString(data, 1, 32);
      apPassword = fixedBytesToString(data, 33, 32);
    }
  }

  @override
  String toString() {
    return '{apName: $apName apPassword: $apPassword}';
  }

  String fixedBytesToString(Uint8List data, int start, int length) {
    // 先取出这一段
    final slice = data.sublist(start, start + length);

    // 找到第一个 0 作为结束
    final zeroIndex = slice.indexOf(0);
    final realBytes = zeroIndex == -1
        ? slice
        : slice.sublist(0, zeroIndex);

    // 如果是 ASCII/UTF-8
    return utf8.decode(realBytes);
  }
}