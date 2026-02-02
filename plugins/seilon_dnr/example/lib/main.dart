// 使用示例：dnr_example.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:seilon_dnr/seilon_dnr.dart';

class DnrExample extends StatefulWidget {
  @override
  _DnrExampleState createState() => _DnrExampleState();
}

class _DnrExampleState extends State<DnrExample> {
  bool _isInitialized = false;
  String _status = "未初始化";
  double _noiseReductionLevel = -10.0;
  StreamSubscription<int>? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _initializeDnr();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    DnrPlugin.dispose();
    super.dispose();
  }

  /// 初始化DNR
  Future<void> _initializeDnr() async {
    setState(() => _status = "正在初始化...");

    int status = await DnrPlugin.initialize(16000);
    if (status == DnrStatus.noError) {
      bool initialized = await DnrPlugin.isInitialized();
      if (initialized) {
        await DnrPlugin.setNoiseReductionLevel(_noiseReductionLevel);

        String? version = await DnrPlugin.getVersion();
        List<int>? bufferSizes = await DnrPlugin.getBufferSizes();

        setState(() {
          _isInitialized = true;
          _status = "初始化成功\n版本: ${version ?? 'Unknown'}\n缓冲区大小: ${bufferSizes ?? []}";
        });
      }
    } else {
      setState(() {
        _isInitialized = false;
        _status = "初始化失败: ${DnrStatus.getStatusMessage(status)}";
      });
    }
  }

  /// 处理单个PCM帧示例
  Future<void> _processSingleFrame() async {
    if (!_isInitialized) {
      _showSnackBar("DNR未初始化");
      return;
    }

    // 创建测试PCM数据（256个样本，模拟正弦波）
    List<int> testPcm = [];
    for (int i = 0; i < 256; i++) {
      double sample = math.sin(2 * math.pi * 440 * i / 16000) * 16000; // 440Hz正弦波
      testPcm.add(sample.round());
    }

    setState(() => _status = "处理单帧中...");

    PcmFrameResult? result = await DnrPlugin.processPcmFrame(testPcm);

    if (result != null && result.isSuccess) {
      // 计算处理前后的RMS值
      double originalRms = PcmUtils.calculateRMS(testPcm);
      double processedRms = PcmUtils.calculateRMS(result.processedPcm);

      setState(() {
        _status = "单帧处理成功!\n"
            "原始RMS: ${originalRms.toStringAsFixed(4)}\n"
            "处理后RMS: ${processedRms.toStringAsFixed(4)}";
      });
    } else {
      setState(() {
        _status = "单帧处理失败: ${result?.statusMessage ?? 'Unknown error'}";
      });
    }
  }

  /// 处理多个PCM帧示例
  Future<void> _processMultipleFrames() async {
    if (!_isInitialized) {
      _showSnackBar("DNR未初始化");
      return;
    }

    setState(() => _status = "生成测试数据...");

    // 生成多帧测试数据（5帧，总共1280个样本）
    List<List<int>> testFrames = [];
    for (int frame = 0; frame < 5; frame++) {
      List<int> frameData = [];
      for (int i = 0; i < 256; i++) {
        // 不同频率的正弦波叠加白噪声
        double signal = math.sin(2 * math.pi * (440 + frame * 100) * i / 16000) * 8000;
        double noise = (math.Random().nextDouble() - 0.5) * 4000; // 白噪声
        frameData.add((signal + noise).round());
      }
      testFrames.add(frameData);
    }

    // 监听进度
    _progressSubscription = DnrPlugin.progressStream.listen((progress) {
      setState(() => _status = "批量处理中... $progress%");
    });

    PcmFramesResult? result = await DnrPlugin.processPcmFrames(testFrames);
    _progressSubscription?.cancel();

    if (result != null && result.isSuccess) {
      setState(() {
        _status = "批量处理成功!\n"
            "处理帧数: ${result.totalFrames}\n"
            "总样本数: ${result.totalFrames * 256}";
      });
    } else {
      setState(() {
        _status = "批量处理失败: ${result?.statusMessage ?? 'Unknown error'}";
      });
    }
  }

  /// 实时处理示例
  Future<void> _startRealtimeProcessing() async {
    if (!_isInitialized) {
      _showSnackBar("DNR未初始化");
      return;
    }

    setState(() => _status = "启动实时处理...");

    // 创建实时处理器
    RealtimePcmProcessor processor = RealtimePcmProcessor();
    await processor.initialize(
      sampleRate: 16000,
      noiseReduction: _noiseReductionLevel,
    );

    // 模拟音频输入流
    Stream<List<int>> simulatedAudioStream = _generateSimulatedAudioStream();

    setState(() => _status = "实时处理中... (10秒)");

    // 处理音频流
    int processedFrames = 0;
    await for (var processedFrame in processor.processStream(simulatedAudioStream)) {
      processedFrames++;

      // 检查音频是否有效
      bool hasAudio = PcmUtils.hasValidAudio(processedFrame);

      setState(() {
        _status = "实时处理中...\n"
            "已处理帧数: $processedFrames\n"
            "当前帧有效: $hasAudio";
      });
    }

    await processor.dispose();
    setState(() => _status = "实时处理完成\n总处理帧数: $processedFrames");
  }

  /// 生成模拟音频流（10秒，每秒62.5帧）
  Stream<List<int>> _generateSimulatedAudioStream() async* {
    int totalFrames = 625; // 10秒 * 62.5帧/秒

    for (int frame = 0; frame < totalFrames; frame++) {
      List<int> frameData = [];

      for (int i = 0; i < 256; i++) {
        // 生成复合信号：语音 + 噪声
        double time = (frame * 256 + i) / 16000.0;
        double speech = math.sin(2 * math.pi * 300 * time) * 8000; // 模拟语音
        double noise = (math.Random().nextDouble() - 0.5) * 3000;   // 环境噪声

        frameData.add((speech + noise).round());
      }

      yield frameData;

      // 模拟实时处理延迟
      await Future.delayed(Duration(milliseconds: 16)); // ~62.5fps
    }
  }

  /// 处理字节数据示例
  Future<void> _processBytesExample() async {
    // 模拟从文件或网络获取的16位PCM字节数据
    List<int> originalPcm = [];
    for (int i = 0; i < 1024; i++) { // 4帧数据
      double sample = math.sin(2 * math.pi * 440 * i / 16000) * 10000;
      originalPcm.add(sample.round());
    }

    // 转换为字节
    Uint8List bytes = PcmUtils.pcm16ToBytes(originalPcm);

    // 从字节恢复PCM
    List<int> restoredPcm = PcmUtils.bytesToPcm16(bytes);

    // 分割成帧
    List<List<int>> frames = PcmUtils.splitIntoFrames(restoredPcm);

    // 处理帧
    PcmFramesResult? result = await DnrPlugin.processPcmFrames(frames);

    if (result != null && result.isSuccess) {
      // 合并处理后的帧
      List<int> processedPcm = PcmUtils.mergeFrames(
        result.processedFrames,
        originalPcm.length,
      );

      setState(() {
        _status = "字节处理示例完成!\n"
            "原始样本数: ${originalPcm.length}\n"
            "字节数据长度: ${bytes.length}\n"
            "处理后样本数: ${processedPcm.length}";
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DNR Plugin 示例'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('状态信息', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(_status, style: TextStyle(fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('降噪深度设置', style: TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: _noiseReductionLevel,
                      min: -200.0,
                      max: 0.0,
                      divisions: 200,
                      label: '${_noiseReductionLevel.toStringAsFixed(1)} dB',
                      onChanged: _isInitialized ? (value) async {
                        setState(() => _noiseReductionLevel = value);
                        await DnrPlugin.setNoiseReductionLevel(value);
                      } : null,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _isInitialized ? _processSingleFrame : null,
                    child: Text('处理单帧'),
                  ),
                  ElevatedButton(
                    onPressed: _isInitialized ? _processMultipleFrames : null,
                    child: Text('批量处理'),
                  ),
                  ElevatedButton(
                    onPressed: _isInitialized ? _startRealtimeProcessing : null,
                    child: Text('实时处理'),
                  ),
                  ElevatedButton(
                    onPressed: _isInitialized ? _processBytesExample : null,
                    child: Text('字节处理'),
                  ),
                  ElevatedButton(
                    onPressed: _initializeDnr,
                    child: Text('重新初始化'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await DnrPlugin.dispose();
                      setState(() {
                        _isInitialized = false;
                        _status = "已释放资源";
                      });
                    },
                    child: Text('释放资源'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}