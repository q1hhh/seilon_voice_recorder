import 'dart:typed_data';

import 'package:Recording_pen/ble/ble_common_message.dart';
import 'package:Recording_pen/util/ByteUtil.dart';

import '../ble_protocol_cmd.dart';

class ControlMessage extends BleMessage {

  /// commandType: 控制指令的类型
  ControlMessage(int commandId, int commandType, List<int> commandData) {
    type = MSG_TYPE_CONTROL_CMD;

    final overallData = Uint8List(3 + commandData.length);

    final commandIdBytes = ByteUtil.getUint8ListOfInt2(commandId & 0xFFFF);

    overallData.setRange(0, 2, commandIdBytes);

    overallData[2] = commandType;

    overallData.setRange(3, 3 + commandData.length, commandData);
    // data.addAll(commandIdBytes);
    // data.add(commandType);
    // data.addAll(commandData);

    this.data = overallData;
  }

  static Map getDataResult(List data) {
    int value = (data[1] << 8) | data[0];

    return {
      "commandId": value,
      "status": data[2],
      "errCode": data[3]
    };
  }


}