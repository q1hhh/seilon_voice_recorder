import 'dart:io';
import 'dart:typed_data';

import 'package:opus_dart/opus_dart.dart';

class MyPcmUtil {

  static Future<Uint8List> decodeAllOpus(Uint8List fullData) async {
    const sampleRate = 16000;
    const channels = 1;
    final decoder = SimpleOpusDecoder(sampleRate: sampleRate, channels: channels);

    final pcmBuffer = BytesBuilder();
    final frameHeader = Uint8List.fromList([0x00, 0x00, 0x00, 0x28]);

    int offset = 0;
    while (offset < fullData.length) {
      int start = _indexOfBytes(fullData, frameHeader, offset);
      if (start == -1) break;

      int next = _indexOfBytes(fullData, frameHeader, start + 4);
      int end = next == -1 ? fullData.length : next;
      Uint8List frame = fullData.sublist(start + 4, end);

      try {
        final pcm = decoder.decode(input: frame);
        if (pcm.isNotEmpty) {
          pcmBuffer.add(Uint8List.view(pcm.buffer, pcm.offsetInBytes, pcm.length * 2));
        }
      } catch (e) {
        print('❌ 解码失败: $e');
      }

      offset = end;
    }

    decoder.destroy();
    return pcmBuffer.toBytes();
  }



  static int _indexOfBytes(Uint8List data, Uint8List pattern, [int start = 0]) {
    final limit = data.length - pattern.length;
    for (int i = start; i <= limit; i++) {
      bool matched = true;
      for (int j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          matched = false;
          break;
        }
      }
      if (matched) return i;
    }
    return -1;
  }
}