import 'dart:typed_data';

import 'package:Recording_pen/ble/ble_common_message.dart';
import 'package:Recording_pen/util/ByteUtil.dart';

import '../ble_protocol_cmd.dart';

class HandShakeMessage extends BleMessage {

  HandShakeMessage(List<int> code, String uuid, int step, [List<int>? accountId]) {
    type = MSG_TYPE_HANDSHAKE;

    List<int> data = [];
    data.add(step);
    data.addAll(code);
    data.addAll(ByteUtil.hexStringToList(uuid));

    // 握手请求要发账户id(4字节)
    if(accountId != null) {
      // data.addAll(accountId);
      // 先发0000, 测试阶段呢
      data.addAll(ByteUtil.hexStringToList("00000000"));
    }

    this.data = Uint8List.fromList(data);
  }


}