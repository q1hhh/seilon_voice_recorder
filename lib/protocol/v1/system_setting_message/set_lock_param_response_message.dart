import 'package:flutter/cupertino.dart';

import '../../../util/ByteUtil.dart';
import '../../BleControlMessage.dart';
import '../../enums/lock_param_type_enum.dart';
import '../constants/LockControlCmd.dart';

class SetLockParamResponseMessage extends BleControlMessage {
  SetLockParamResponseMessage(BleControlMessage message) {
    length = message.length;
    cmdCategory = message.cmdCategory;
    cmd = message.cmd;
    data = message.data;
  }

  Map<LockParamTypeEnum, int> getParamValues() {
    // int count = data[1] & 0xFF; // 获取参数数量
    Map<LockParamTypeEnum, int> paramValues = {};


    int count = ((data.length - 2) / 3).toInt();

    // print('参数：$d');

    int index = 2;
    for (int i = 0; i < count; i++) {
      // 获取参数类型
      LockParamTypeEnum type = LockParamTypeEnum.fromValue(data[index] & 0xFF);

      // 从字节数组中获取参数值
      int value = ByteUtil.getInt2(data, index + 1);

      // 存储到 Map 中
      paramValues[type] = value;

      // 移动索引到下一个参数
      index += 3;
    }

    return paramValues;
  }
}