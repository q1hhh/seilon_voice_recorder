import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:Recording_pen/util/log_util.dart';
import 'package:flutter/cupertino.dart';
import 'dart:typed_data';
import 'package:opus_dart/opus_dart.dart';
import 'package:opus_flutter/opus_flutter.dart';

class AudioDecodeUtil {

  Stream<List<int>> opusStream(BuildContext context, String filePage) async* {
    const int portionSize = 65535;

    var data = await loadOpusFile(filePage);
    // ByteData data = await DefaultAssetBundle.of(context).load(filePage);
    int i = 0;
    while (i != data.lengthInBytes) {
      int r = min(portionSize, data.lengthInBytes - i);
      yield data.buffer.asUint8List(data.offsetInBytes + i, r);
      i += r;
      await Future.delayed(
          const Duration(milliseconds: 10)); //Simulate network latency
    }
  }

  Future<Uint8List> loadOpusFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception("文件不存在: $filePath");
    }
    return await file.readAsBytes();
  }

  Future<Uint8List> opusToWav(Stream<List<int>> input) async {
    const int sampleRate = 16000;
    const int channels = 1;
    List<Uint8List> output = [];
    output.add(Uint8List(wavHeaderSize));

    await input
        .transform(StreamOpusEncoder.bytes(
        floatInput: false,
        frameTime: FrameTime.ms20,
        sampleRate: sampleRate,
        channels: channels,
        application: Application.audio,
        copyOutput: true,
        fillUpLastFrame: true))
        .cast<Uint8List?>()
        .transform(StreamOpusDecoder.bytes(
        floatOutput: false,
        sampleRate: sampleRate,
        channels: channels,
        copyOutput: true,
        forwardErrorCorrection: false))
        .cast<Uint8List>()
        .forEach(output.add);
    int length = output.fold(0, (int l, Uint8List element) => l + element.length);
    //编写 wav 头部信息
    Uint8List header = wavHeader(channels: channels, sampleRate: sampleRate, fileSize: length);
    output[0] = header;
    // Merge into a single Uint8List
    Uint8List flat = Uint8List(length);
    int index = 0;
    for (Uint8List element in output) {
      flat.setAll(index, element);
      index += element.length;
    }
    return flat;
  }

  int wavHeaderSize = 44;

  Uint8List wavHeader(
      {required int sampleRate, required int channels, required int fileSize}) {
    const int sampleBits = 16; //We know this since we used opus
    const Endian endian = Endian.little;
    final int frameSize = ((sampleBits + 7) ~/ 8) * channels;
    ByteData data = ByteData(wavHeaderSize);
    data.setUint32(4, fileSize - 4, endian);
    data.setUint32(16, 16, endian);
    data.setUint16(20, 1, endian);
    data.setUint16(22, channels, endian);
    data.setUint32(24, sampleRate, endian);
    data.setUint32(28, sampleRate * frameSize, endian);
    data.setUint16(30, frameSize, endian);
    data.setUint16(34, sampleBits, endian);
    data.setUint32(40, fileSize - 44, endian);
    Uint8List bytes = data.buffer.asUint8List();
    bytes.setAll(0, ascii.encode('RIFF'));
    bytes.setAll(8, ascii.encode('WAVE'));
    bytes.setAll(12, ascii.encode('fmt '));
    bytes.setAll(36, ascii.encode('data'));
    return bytes;
  }

}