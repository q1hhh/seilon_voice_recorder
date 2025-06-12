import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';

import '../constants/LockControlCmd.dart';

class ControlSoundRecordMessage extends BleControlMessage {
  ControlSoundRecordMessage(int control, int model) {
    cmdCategory = LockControlCmd.CATEGORY_RECORDER;
    cmd = LockControlCmd.CMD_RECORDER_CONTROL_SOUND_RECORD;

    data = Uint8List.fromList([
      control,
      model
    ]);
  }
}