// import 'dart:async';
// import 'dart:math' as Math;
// import 'dart:typed_data';
// import 'package:Recording_pen/util/my_pcm_util.dart';
// import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
//
// // 音频调试播放器 - 找出声音问题
// class DebugAudioPlayer {
//   bool _isInitialized = false;
//   bool _isStreaming = false;
//
//   // 可调整的音频参数
//   int sampleRate;
//   int channels;
//
//   // 调试统计
//   int _totalFrames = 0;
//   int _playedFrames = 0;
//   List<int> _sampleValues = []; // 记录采样值用于调试
//
//   DebugAudioPlayer({
//     this.sampleRate = 16000,
//     this.channels = 2,
//   });
//
//   // 初始化并测试不同参数
//   Future<void> initialize() async {
//     if (_isInitialized) return;
//
//     print('🎵 调试播放器初始化 - 采样率:$sampleRate, 声道:$channels');
//
//     await FlutterPcmSound.setup(
//       sampleRate: sampleRate,
//       channelCount: channels,
//     );
//
//     await FlutterPcmSound.setFeedThreshold(500);
//     FlutterPcmSound.setFeedCallback(_debugCallback);
//
//     _isInitialized = true;
//     print('✅ 调试播放器初始化完成');
//   }
//
//   void _debugCallback(int remainingFrames) {
//     // 简单回调，主要用直接播放
//   }
//
//   Future<void> startStreaming() async {
//     if (!_isInitialized || _isStreaming) return;
//
//     _isStreaming = true;
//     await FlutterPcmSound.start();
//     print('🔊 调试播放开始');
//   }
//
//   // 测试直接播放（已知可以播放但声音有问题）
//   Future<void> testDirectPlay(Uint8List opusData) async {
//     if (!_isStreaming) return;
//
//     _totalFrames++;
//
//     try {
//       // 1. 解码 Opus
//       final pcmData = await MyPcmUtil.decodeAllOpus(opusData);
//       print('📥 Opus解码: ${opusData.length}字节 -> ${pcmData.length}字节');
//
//       if (pcmData.isEmpty) {
//         print('❌ 解码后PCM数据为空');
//         return;
//       }
//
//       // 2. 检查PCM数据
//       _analyzePcmData(pcmData);
//
//       // 3. 转换为采样
//       final samples = _convertToPcmInt16(pcmData);
//       print('🔄 PCM转换: ${pcmData.length}字节 -> ${samples.length}采样');
//
//       if (samples.isEmpty) {
//         print('❌ 转换后采样数据为空');
//         return;
//       }
//
//       // 4. 检查采样值
//       _analyzeSamples(samples);
//
//       // 5. 播放
//       await FlutterPcmSound.feed(PcmArrayInt16.fromList(samples));
//       _playedFrames++;
//
//       print('✅ 播放成功[$_playedFrames]: ${samples.length}采样');
//
//     } catch (e) {
//       print('❌ 测试播放失败: $e');
//     }
//   }
//
//   // 分析PCM原始数据
//   void _analyzePcmData(Uint8List pcmData) {
//     if (pcmData.length < 10) {
//       print('⚠️  PCM数据太短: ${pcmData.length}字节');
//       return;
//     }
//
//     // 检查前几个字节
//     final first10 = pcmData.take(10).toList();
//     print('📊 PCM前10字节: ${first10.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
//
//     // 检查是否全是0或同一值
//     final unique = pcmData.toSet();
//     if (unique.length == 1) {
//       print('⚠️  PCM数据全是同一值: 0x${unique.first.toRadixString(16)}');
//     }
//
//     // 检查字节分布
//     int zeros = pcmData.where((b) => b == 0).length;
//     double zeroRate = zeros / pcmData.length;
//     print('📊 零字节比例: ${(zeroRate * 100).toStringAsFixed(1)}%');
//   }
//
//   // 分析采样值
//   void _analyzeSamples(List<int> samples) {
//     if (samples.isEmpty) return;
//
//     // 统计采样值分布
//     int positives = samples.where((s) => s > 0).length;
//     int negatives = samples.where((s) => s < 0).length;
//     int zeros = samples.where((s) => s == 0).length;
//
//     int maxSample = samples.reduce((a, b) => a > b ? a : b);
//     int minSample = samples.reduce((a, b) => a < b ? a : b);
//
//     print('📊 采样分析:');
//     print('   正值: $positives, 负值: $negatives, 零值: $zeros');
//     print('   范围: $minSample 到 $maxSample');
//     print('   前5个采样: ${samples.take(5).toList()}');
//
//     // 检查是否有明显问题
//     if (zeros == samples.length) {
//       print('❌ 所有采样都是0 - 这会导致无声');
//     } else if (maxSample == minSample) {
//       print('❌ 所有采样都是同一值 - 这会导致DC偏移噪音');
//     } else if (maxSample > 32767 || minSample < -32768) {
//       print('⚠️  采样值超出16位范围');
//     }
//
//     // 记录一些采样值用于趋势分析
//     _sampleValues.addAll(samples.take(3));
//     if (_sampleValues.length > 100) {
//       _sampleValues = _sampleValues.sublist(_sampleValues.length - 100);
//     }
//   }
//
//   // 标准PCM转换
//   List<int> _convertToPcmInt16(Uint8List pcmBytes) {
//     final samples = <int>[];
//
//     for (int i = 0; i < pcmBytes.length - 1; i += 2) {
//       final sample = (pcmBytes[i + 1] << 8) | pcmBytes[i];
//       final signed = sample > 32767 ? sample - 65536 : sample;
//       samples.add(signed);
//     }
//
//     return samples;
//   }
//
//   // 尝试不同的PCM转换方法
//   Future<void> testDifferentConversions(Uint8List opusData) async {
//     if (!_isStreaming) return;
//
//     final pcmData = await MyPcmUtil.decodeAllOpus(opusData);
//     if (pcmData.isEmpty) return;
//
//     print('🔬 测试不同转换方法:');
//
//     // 方法1: 标准小端序
//     final samples1 = <int>[];
//     for (int i = 0; i < pcmData.length - 1; i += 2) {
//       final sample = (pcmData[i + 1] << 8) | pcmData[i];
//       samples1.add(sample > 32767 ? sample - 65536 : sample);
//     }
//     print('方法1(小端序): ${samples1.take(5).toList()}');
//
//     // 方法2: 大端序
//     final samples2 = <int>[];
//     for (int i = 0; i < pcmData.length - 1; i += 2) {
//       final sample = (pcmData[i] << 8) | pcmData[i + 1];
//       samples2.add(sample > 32767 ? sample - 65536 : sample);
//     }
//     print('方法2(大端序): ${samples2.take(5).toList()}');
//
//     // 方法3: 只取单声道（左声道）
//     final samples3 = <int>[];
//     for (int i = 0; i < pcmData.length - 3; i += 4) { // 每4字节取2字节
//       final sample = (pcmData[i + 1] << 8) | pcmData[i];
//       samples3.add(sample > 32767 ? sample - 65536 : sample);
//     }
//     print('方法3(单声道): ${samples3.take(5).toList()}');
//
//     // 测试播放方法1
//     try {
//       await FlutterPcmSound.feed(PcmArrayInt16.fromList(samples1));
//       print('✅ 方法1播放成功');
//     } catch (e) {
//       print('❌ 方法1播放失败: $e');
//     }
//   }
//
//   // 测试不同音频参数
//   Future<void> testDifferentParameters(Uint8List opusData) async {
//     print('🔬 测试不同音频参数:');
//
//     // 参数组合列表
//     final testParams = [
//       {'rate': 16000, 'channels': 1},  // 单声道
//       {'rate': 16000, 'channels': 2},  // 立体声
//       {'rate': 8000, 'channels': 1},   // 低采样率
//       {'rate': 44100, 'channels': 2},  // CD质量
//     ];
//
//     for (final params in testParams) {
//       try {
//         print('📝 测试参数: ${params['rate']}Hz, ${params['channels']}声道');
//
//         await FlutterPcmSound.setup(
//           sampleRate: params['rate'] as int,
//           channelCount: params['channels'] as int,
//         );
//
//         await FlutterPcmSound.setFeedThreshold(500);
//         await FlutterPcmSound.start();
//
//         // 解码和播放
//         final pcmData = await MyPcmUtil.decodeAllOpus(opusData);
//         if (pcmData.isNotEmpty) {
//           final samples = _convertToPcmInt16(pcmData);
//           await FlutterPcmSound.feed(PcmArrayInt16.fromList(samples));
//           print('✅ 参数${params['rate']}Hz-${params['channels']}ch 播放成功');
//         }
//
//         await Future.delayed(Duration(milliseconds: 100));
//
//       } catch (e) {
//         print('❌ 参数${params['rate']}Hz-${params['channels']}ch 失败: $e');
//       }
//     }
//   }
//
//   // 生成测试音频确认播放器正常
//   Future<void> generateTestTone() async {
//     if (!_isStreaming) return;
//
//     print('🎵 生成440Hz测试音调...');
//
//     const frequency = 440; // A4音符
//     const duration = 1.0; // 1秒
//     final samplesCount = (sampleRate * duration).round();
//
//     final samples = <int>[];
//     for (int i = 0; i < samplesCount; i++) {
//       final t = i / sampleRate;
//       final amplitude = 0.3; // 30%音量避免过响
//       final sample = (amplitude * 32767 * Math.sin(2 * Math.pi * frequency * t)).round();
//       samples.add(sample);
//
//       // 如果是立体声，添加相同的右声道
//       if (channels == 2) {
//         samples.add(sample);
//       }
//     }
//
//     try {
//       await FlutterPcmSound.feed(PcmArrayInt16.fromList(samples));
//       print('✅ 测试音调播放完成');
//     } catch (e) {
//       print('❌ 测试音调播放失败: $e');
//     }
//   }
//
//   Future<void> stopStreaming() async {
//     if (!_isStreaming) return;
//     _isStreaming = false;
//     print('🔇 调试播放停止');
//   }
//
//   void dispose() {
//     _isStreaming = false;
//   }
//
//   // 打印完整诊断报告
//   void printDiagnostics() {
//     print('📋 音频诊断报告:');
//     print('   总帧数: $_totalFrames');
//     print('   播放帧数: $_playedFrames');
//     print('   当前参数: ${sampleRate}Hz, ${channels}声道');
//
//     if (_sampleValues.isNotEmpty) {
//       final maxVal = _sampleValues.reduce((a, b) => a > b ? a : b);
//       final minVal = _sampleValues.reduce((a, b) => a < b ? a : b);
//       print('   采样值范围: $minVal 到 $maxVal');
//     }
//   }
//
//   bool get isStreaming => _isStreaming;
// }