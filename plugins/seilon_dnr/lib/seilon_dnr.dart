// dnr_plugin.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';

/// DNRçŠ¶æ€ç
class DnrStatus {
  static const int noError = 0;
  static const int notReady = 1;
  static const int invalidParam = 2;
  static const int invalidLicense = 3;
  static const int bufferOverflow = 4;
  static const int bufferTooSmall = 5;

  static String getStatusMessage(int status) {
    switch (status) {
      case noError:
        return "No error";
      case notReady:
        return "Not ready";
      case invalidParam:
        return "Invalid parameter";
      case invalidLicense:
        return "Invalid license";
      case bufferOverflow:
        return "Buffer overflow";
      case bufferTooSmall:
        return "Buffer too small";
      default:
        return "Unknown error";
    }
  }
}

/// PCMå¸§å¤„ç†ç»"æžœ
class PcmFrameResult {
  final int status;
  final List<int> processedPcm;

  PcmFrameResult({
    required this.status,
    required this.processedPcm,
  });

  factory PcmFrameResult.fromMap(Map<dynamic, dynamic> map) {
    // 安全地转换状态码
    int statusCode = DnrStatus.notReady;
    if (map['status'] != null) {
      if (map['status'] is int) {
        statusCode = map['status'] as int;
      } else if (map['status'] is String) {
        statusCode = int.tryParse(map['status']) ?? DnrStatus.notReady;
      }
    }

    // 安全地转换PCM数据
    List<int> pcmList = [];
    if (map['processedPcm'] != null) {
      try {
        var rawList = map['processedPcm'];
        if (rawList is List) {
          for (var item in rawList) {
            if (item is int) {
              pcmList.add(item);
            } else if (item is num) {
              pcmList.add(item.toInt());
            }
          }
        }
      } catch (e) {
        print('Error parsing processedPcm: $e');
      }
    }

    return PcmFrameResult(
      status: statusCode,
      processedPcm: pcmList,
    );
  }

  bool get isSuccess => status == DnrStatus.noError;
  String get statusMessage => DnrStatus.getStatusMessage(status);
}

/// æ‰¹é‡PCMå¸§å¤„ç†ç»"æžœ
class PcmFramesResult {
  final int status;
  final List<List<int>> processedFrames;
  final int totalFrames;

  PcmFramesResult({
    required this.status,
    required this.processedFrames,
    required this.totalFrames,
  });

  factory PcmFramesResult.fromMap(Map<dynamic, dynamic> map) {
    // 安全地转换状态码
    int statusCode = DnrStatus.notReady;
    if (map['status'] != null) {
      if (map['status'] is int) {
        statusCode = map['status'] as int;
      } else if (map['status'] is String) {
        statusCode = int.tryParse(map['status']) ?? DnrStatus.notReady;
      }
    }

    // 安全地转换帧数据
    List<List<int>> frames = [];
    if (map['processedFrames'] != null) {
      try {
        var rawFrames = map['processedFrames'];
        if (rawFrames is List) {
          for (var frame in rawFrames) {
            if (frame is List) {
              List<int> frameInts = [];
              for (var sample in frame) {
                if (sample is int) {
                  frameInts.add(sample);
                } else if (sample is num) {
                  frameInts.add(sample.toInt());
                }
              }
              frames.add(frameInts);
            }
          }
        }
      } catch (e) {
        print('Error parsing processedFrames: $e');
      }
    }

    // 安全地转换总帧数
    int totalFramesCount = 0;
    if (map['totalFrames'] != null) {
      if (map['totalFrames'] is int) {
        totalFramesCount = map['totalFrames'] as int;
      } else if (map['totalFrames'] is num) {
        totalFramesCount = (map['totalFrames'] as num).toInt();
      }
    }

    return PcmFramesResult(
      status: statusCode,
      processedFrames: frames,
      totalFrames: totalFramesCount,
    );
  }

  bool get isSuccess => status == DnrStatus.noError;
  String get statusMessage => DnrStatus.getStatusMessage(status);
}

/// DNRæ'ä»¶æŽ¥å£
class DnrPlugin {
  static const MethodChannel _channel = MethodChannel('dnr_plugin');
  static const EventChannel _eventChannel = EventChannel('dnr_plugin/progress');

  /// è¿›åº¦ç›'å¬æµ
  static Stream<int>? _progressStream;

  /// èŽ·å–è¿›åº¦ç›'å¬æµ
  static Stream<int> get progressStream {
    _progressStream ??= _eventChannel.receiveBroadcastStream().cast<int>();
    return _progressStream!;
  }

  /// åˆå§‹åŒ–DNR
  /// [sampleRate] é‡‡æ ·çŽ‡ï¼Œé€šå¸¸ä¸º16000
  /// è¿"å›žDNRçŠ¶æ€ç
  static Future<int> initialize(int sampleRate) async {
    try {
      final int result = await _channel.invokeMethod('initialize', {
        'sampleRate': sampleRate,
      });
      return result;
    } catch (e) {
      print('DNR initialize error: $e');
      return DnrStatus.notReady;
    }
  }

  /// æ£€æŸ¥DNRæ˜¯å¦å·²åˆå§‹åŒ–
  static Future<bool> isInitialized() async {
    try {
      final bool result = await _channel.invokeMethod('isInitialized');
      return result;
    } catch (e) {
      print('DNR isInitialized error: $e');
      return false;
    }
  }

  /// èŽ·å–DNRç‰ˆæœ¬ä¿¡æ¯
  static Future<String?> getVersion() async {
    try {
      final String? result = await _channel.invokeMethod('getVersion');
      return result;
    } catch (e) {
      print('DNR getVersion error: $e');
      return null;
    }
  }

  /// èŽ·å–DNRç¼"å†²åŒºå¤§å°ä¿¡æ¯
  /// è¿"å›žåŒ…å«ä¸¤ä¸ªå…ƒç´ çš„åˆ—è¡¨ï¼š[buffer1_size, buffer2_size]
  static Future<List<int>?> getBufferSizes() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getBufferSizes');
      return result.cast<int>();
    } catch (e) {
      print('DNR getBufferSizes error: $e');
      return null;
    }
  }

  /// è®¾ç½®é™å™ªæ·±åº¦
  /// [dB] é™å™ªæ·±åº¦ï¼ŒèŒƒå›´ -200 åˆ° 0 dB
  ///      -200: æœ€å¤§é™å™ª
  ///      0: æ— é™å™ª
  static Future<bool> setNoiseReductionLevel(double dB) async {
    try {
      await _channel.invokeMethod('setNoiseReductionLevel', {
        'dB': dB,
      });
      return true;
    } catch (e) {
      print('DNR setNoiseReductionLevel error: $e');
      return false;
    }
  }

  /// å¤„ç†éŸ³é¢'æ–‡ä»¶
  /// [filePath] éŸ³é¢'æ–‡ä»¶è·¯å¾„
  /// è¿"å›žå¤„ç†åŽçš„WAVæ ¼å¼éŸ³é¢'æ•°æ®
  static Future<Uint8List?> processAudioFile(String filePath) async {
    try {
      final Uint8List? result = await _channel.invokeMethod('processAudioFile', {
        'filePath': filePath,
      });
      return result;
    } catch (e) {
      print('DNR processAudioFile error: $e');
      return null;
    }
  }

  /// å¤„ç†å•ä¸ªPCMå¸§ï¼ˆæŽ¨èä½¿ç"¨ï¼‰
  /// [pcmData] PCMæ•°æ®ï¼Œå¿…é¡»åŒ…å«256ä¸ª16ä½é‡‡æ ·ç‚¹
  /// è¿"å›žå¤„ç†ç»"æžœï¼ŒåŒ…å«çŠ¶æ€ç å'Œå¤„ç†åŽçš„PCMæ•°æ®
  static Future<PcmFrameResult?> processPcmFrame(List<int> pcmData) async {
    if (pcmData.length != 256) {
      print('PCM frame must contain exactly 256 samples, got ${pcmData.length}');
      return PcmFrameResult(
        status: DnrStatus.invalidParam,
        processedPcm: [],
      );
    }

    try {
      final result = await _channel.invokeMethod('processPcmFrame', {
        'pcmData': pcmData,
      });

      if (result == null) {
        print('Received null result from native');
        return PcmFrameResult(
          status: DnrStatus.notReady,
          processedPcm: [],
        );
      }

      // 安全地转换结果
      Map<dynamic, dynamic> resultMap;
      if (result is Map<String, dynamic>) {
        resultMap = result;
      } else if (result is Map) {
        resultMap = Map<dynamic, dynamic>.from(result);
      } else {
        print('Unexpected result type: ${result.runtimeType}');
        return PcmFrameResult(
          status: DnrStatus.notReady,
          processedPcm: [],
        );
      }

      return PcmFrameResult.fromMap(resultMap);

    } catch (e) {
      print('DNR processPcmFrame error: $e');
      return PcmFrameResult(
        status: DnrStatus.notReady,
        processedPcm: [],
      );
    }
  }

  /// æ‰¹é‡å¤„ç†å¤šä¸ªPCMå¸§
  /// [frames] PCMå¸§åˆ—è¡¨ï¼Œæ¯ä¸ªå¸§å¿…é¡»åŒ…å«256ä¸ª16ä½é‡‡æ ·ç‚¹
  /// è¿"å›žå¤„ç†ç»"æžœï¼ŒåŒ…å«çŠ¶æ€ç å'Œæ‰€æœ‰å¤„ç†åŽçš„PCMå¸§
  static Future<PcmFramesResult?> processPcmFrames(List<List<int>> frames) async {
    if (frames.isEmpty) {
      print('Frames list cannot be empty');
      return PcmFramesResult(
        status: DnrStatus.invalidParam,
        processedFrames: [],
        totalFrames: 0,
      );
    }

    // éªŒè¯æ¯ä¸ªå¸§çš„é•¿åº¦
    for (int i = 0; i < frames.length; i++) {
      if (frames[i].length != 256) {
        print('Frame $i must contain exactly 256 samples, got ${frames[i].length}');
        return PcmFramesResult(
          status: DnrStatus.invalidParam,
          processedFrames: [],
          totalFrames: 0,
        );
      }
    }

    try {
      final result = await _channel.invokeMethod('processPcmFrames', {
        'frames': frames,
      });

      if (result == null) {
        return PcmFramesResult(
          status: DnrStatus.notReady,
          processedFrames: [],
          totalFrames: 0,
        );
      }

      // 安全地转换结果
      Map<dynamic, dynamic> resultMap;
      if (result is Map<String, dynamic>) {
        resultMap = result;
      } else if (result is Map) {
        resultMap = Map<dynamic, dynamic>.from(result);
      } else {
        return PcmFramesResult(
          status: DnrStatus.notReady,
          processedFrames: [],
          totalFrames: 0,
        );
      }

      return PcmFramesResult.fromMap(resultMap);

    } catch (e) {
      print('DNR processPcmFrames error: $e');
      return PcmFramesResult(
        status: DnrStatus.notReady,
        processedFrames: [],
        totalFrames: 0,
      );
    }
  }

  /// å¤„ç†åŽŸå§‹éŸ³é¢'æ•°æ®ï¼ˆQ31æ ¼å¼ï¼Œä¿ç•™å…¼å®¹æ€§ï¼‰
  /// [audioData] Q31æ ¼å¼éŸ³é¢'æ•°æ®ï¼Œå¿…é¡»åŒ…å«256ä¸ªæ ·æœ¬ç‚¹
  /// è¿"å›žå¤„ç†ç»"æžœMap
  static Future<Map<String, dynamic>?> processAudioData(List<int> audioData) async {
    if (audioData.length != 256) {
      print('Audio data must contain exactly 256 samples');
      return null;
    }

    try {
      final Map<String, dynamic> result = await _channel.invokeMethod('processAudioData', {
        'audioData': audioData,
      });
      return result;
    } catch (e) {
      print('DNR processAudioData error: $e');
      return null;
    }
  }

  /// å–æ¶ˆå½"å‰å¤„ç†ä»»åŠ¡
  static Future<bool> cancelProcessing() async {
    try {
      await _channel.invokeMethod('cancelProcessing');
      return true;
    } catch (e) {
      print('DNR cancelProcessing error: $e');
      return false;
    }
  }

  /// é‡Šæ"¾èµ„æº
  static Future<bool> dispose() async {
    try {
      await _channel.invokeMethod('dispose');
      return true;
    } catch (e) {
      print('DNR dispose error: $e');
      return false;
    }
  }
}

/// PCMå¤„ç†å¸®åŠ©å·¥å…·ç±»
class PcmUtils {
  /// å°†16ä½PCMçš„å­—èŠ‚æ•°æ®è½¬æ¢ä¸ºintåˆ—è¡¨
  /// [bytes] 16ä½PCMå­—èŠ‚æ•°æ®ï¼ˆå°ç«¯åºï¼‰
  /// è¿"å›žintåˆ—è¡¨ï¼Œæ¯ä¸ªå…ƒç´ ä»£è¡¨ä¸€ä¸ª16ä½PCMæ ·æœ¬
  static List<int> bytesToPcm16(Uint8List bytes) {
    List<int> pcmData = [];

    // ç¡®ä¿å­—èŠ‚æ•°ä¸ºå¶æ•°ï¼ˆ16ä½ = 2å­—èŠ‚ï¼‰
    if (bytes.length % 2 != 0) {
      throw ArgumentError('Byte array length must be even for 16-bit PCM');
    }

    for (int i = 0; i < bytes.length; i += 2) {
      // å°ç«¯åºï¼šä½Žå­—èŠ‚åœ¨å‰ï¼Œé«˜å­—èŠ‚åœ¨åŽ
      int lowByte = bytes[i] & 0xFF;
      int highByte = bytes[i + 1] & 0xFF;

      // ç»„åˆæˆ16ä½æœ‰ç¬¦å·æ•´æ•°
      int sample = (highByte << 8) | lowByte;

      // å¤„ç†æœ‰ç¬¦å·æ•°ï¼ˆå¦‚æžœæœ€é«˜ä½ä¸º1ï¼Œåˆ™ä¸ºè´Ÿæ•°ï¼‰
      if (sample >= 32768) {
        sample -= 65536;
      }

      pcmData.add(sample);
    }

    return pcmData;
  }

  /// å°†intåˆ—è¡¨è½¬æ¢ä¸º16ä½PCMå­—èŠ‚æ•°æ®
  /// [pcmData] intåˆ—è¡¨ï¼Œæ¯ä¸ªå…ƒç´ ä»£è¡¨ä¸€ä¸ª16ä½PCMæ ·æœ¬
  /// è¿"å›ž16ä½PCMå­—èŠ‚æ•°æ®ï¼ˆå°ç«¯åºï¼‰
  static Uint8List pcm16ToBytes(List<int> pcmData) {
    Uint8List bytes = Uint8List(pcmData.length * 2);

    for (int i = 0; i < pcmData.length; i++) {
      int sample = pcmData[i];

      // ç¡®ä¿æ ·æœ¬å€¼åœ¨16ä½èŒƒå›´å†…
      if (sample < -32768) sample = -32768;
      if (sample > 32767) sample = 32767;

      // å¤„ç†è´Ÿæ•°
      if (sample < 0) {
        sample += 65536;
      }

      // å°ç«¯åºï¼šä½Žå­—èŠ‚åœ¨å‰ï¼Œé«˜å­—èŠ‚åœ¨åŽ
      bytes[i * 2] = sample & 0xFF;         // ä½Žå­—èŠ‚
      bytes[i * 2 + 1] = (sample >> 8) & 0xFF; // é«˜å­—èŠ‚
    }

    return bytes;
  }

  /// å°†PCMæ•°æ®åˆ†å‰²æˆ256æ ·æœ¬çš„å¸§
  /// [pcmData] å®Œæ•´çš„PCMæ•°æ®
  /// è¿"å›žå¸§åˆ—è¡¨ï¼Œæ¯å¸§åŒ…å«256ä¸ªæ ·æœ¬
  static List<List<int>> splitIntoFrames(List<int> pcmData) {
    List<List<int>> frames = [];
    const int frameSize = 256;

    for (int i = 0; i < pcmData.length; i += frameSize) {
      int endIndex = i + frameSize;
      if (endIndex > pcmData.length) {
        // æœ€åŽä¸€å¸§ä¸è¶³256æ ·æœ¬ï¼Œç"¨0å¡«å……
        List<int> frame = List<int>.from(pcmData.sublist(i));
        while (frame.length < frameSize) {
          frame.add(0);
        }
        frames.add(frame);
      } else {
        frames.add(pcmData.sublist(i, endIndex));
      }
    }

    return frames;
  }

  /// å°†å¤šä¸ªå¸§åˆå¹¶æˆå®Œæ•´çš„PCMæ•°æ®
  /// [frames] å¸§åˆ—è¡¨
  /// [originalLength] åŽŸå§‹æ•°æ®é•¿åº¦ï¼ˆå¯é€‰ï¼Œç"¨äºŽåŽ»é™¤å¡«å……çš„0ï¼‰
  /// è¿"å›žåˆå¹¶åŽçš„PCMæ•°æ®
  static List<int> mergeFrames(List<List<int>> frames, [int? originalLength]) {
    List<int> mergedData = [];

    for (var frame in frames) {
      mergedData.addAll(frame);
    }

    // å¦‚æžœæŒ‡å®šäº†åŽŸå§‹é•¿åº¦ï¼Œæˆªå–åˆ°æŒ‡å®šé•¿åº¦
    if (originalLength != null && originalLength < mergedData.length) {
      return mergedData.sublist(0, originalLength);
    }

    return mergedData;
  }

  /// è®¡ç®—PCMæ•°æ®çš„RMSï¼ˆå‡æ–¹æ ¹ï¼‰å€¼ï¼Œç"¨äºŽéŸ³é‡æ£€æµ‹
  /// [pcmData] PCMæ•°æ®
  /// è¿"å›žRMSå€¼ï¼ˆ0.0 - 1.0èŒƒå›´ï¼‰
  static double calculateRMS(List<int> pcmData) {
    if (pcmData.isEmpty) return 0.0;

    double sum = 0.0;
    for (int sample in pcmData) {
      double normalized = sample / 32768.0; // æ ‡å‡†åŒ–åˆ° -1.0 ~ 1.0
      sum += normalized * normalized;
    }

    return math.sqrt(sum / pcmData.length);
  }

  /// æ£€æŸ¥PCMå¸§æ˜¯å¦åŒ…å«æœ‰æ•ˆéŸ³é¢'ï¼ˆéžé™éŸ³ï¼‰
  /// [pcmFrame] PCMå¸§æ•°æ®
  /// [threshold] é™éŸ³é˜ˆå€¼ï¼ˆ0.0 - 1.0ï¼‰ï¼Œé»˜è®¤0.01
  /// è¿"å›žtrueè¡¨ç¤ºåŒ…å«æœ‰æ•ˆéŸ³é¢'
  static bool hasValidAudio(List<int> pcmFrame, {double threshold = 0.01}) {
    double rms = calculateRMS(pcmFrame);
    return rms > threshold;
  }
}

/// å®žæ—¶PCMå¤„ç†å™¨ç¤ºä¾‹
class RealtimePcmProcessor {
  final DnrPlugin _dnrPlugin = DnrPlugin();
  bool _isProcessing = false;

  /// åˆå§‹åŒ–å¤„ç†å™¨
  Future<bool> initialize({int sampleRate = 16000, double noiseReduction = -10.0}) async {
    int status = await DnrPlugin.initialize(sampleRate);
    if (status == DnrStatus.noError) {
      await DnrPlugin.setNoiseReductionLevel(noiseReduction);
      return true;
    }
    return false;
  }

  /// å¤„ç†å®žæ—¶PCMæ•°æ®æµ
  /// [pcmStream] è¾"å…¥PCMæ•°æ®æµ
  /// è¿"å›žå¤„ç†åŽçš„PCMæ•°æ®æµ
  Stream<List<int>> processStream(Stream<List<int>> pcmStream) async* {
    if (!await DnrPlugin.isInitialized()) {
      throw StateError('DNR not initialized');
    }

    _isProcessing = true;
    List<int> buffer = [];

    await for (var pcmData in pcmStream) {
      if (!_isProcessing) break;

      buffer.addAll(pcmData);

      // å¤„ç†å®Œæ•´çš„256æ ·æœ¬å¸§
      while (buffer.length >= 256) {
        List<int> frame = buffer.sublist(0, 256);
        buffer.removeRange(0, 256);

        var result = await DnrPlugin.processPcmFrame(frame);
        if (result != null && result.isSuccess) {
          yield result.processedPcm;
        }
      }
    }

    // å¤„ç†å‰©ä½™æ•°æ®
    if (buffer.isNotEmpty && _isProcessing) {
      while (buffer.length < 256) {
        buffer.add(0); // å¡«å……0
      }

      var result = await DnrPlugin.processPcmFrame(buffer);
      if (result != null && result.isSuccess) {
        yield result.processedPcm;
      }
    }
  }

  /// åœæ­¢å¤„ç†
  void stopProcessing() {
    _isProcessing = false;
  }

  /// é‡Šæ"¾èµ„æº
  Future<void> dispose() async {
    stopProcessing();
    await DnrPlugin.dispose();
  }
}