import 'dart:typed_data';

import 'package:Recording_pen/protocol/BleControlMessage.dart';

import '../constants/LockControlCmd.dart';

class ReadAudioListCount extends BleControlMessage {
  ReadAudioListCount() {
    cmdCategory = LockControlCmd.CATEGORY_RECORDER;
    cmd = LockControlCmd.CMD_RECORDER_AUDIO_FILE_COUNT;
  }
}