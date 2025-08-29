import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// 单例模式的Notify回调速率计算器
class NotifyRateCalculator {
  // 私有构造函数
  NotifyRateCalculator._internal();

  // 静态实例
  static final NotifyRateCalculator _instance = NotifyRateCalculator._internal();

  // 工厂构造函数，返回单例实例
  factory NotifyRateCalculator() => _instance;

  // 获取实例的静态方法
  static NotifyRateCalculator get instance => _instance;

  // 基础统计
  int _packetCount = 0;
  DateTime? _startTime;

  // 实时速率统计
  Timer? _rateTimer;
  int _currentSecondCount = 0;
  double _currentRate = 0.0;

  // 数据统计
  int _totalBytes = 0;
  double _averagePacketSize = 0.0;

  // 自动统计功能
  Timer? _autoStatsTimer;
  bool _autoCalculationEnabled = false;
  bool _isRunning = false; // 防止重复启动
  Function(NotifyStats)? _onStatsUpdated;
  Function(String)? _onPerformanceAlert;

  // 性能监控
  List<double> _recentRates = [];
  DateTime? _lastAlertTime;

  // 检查是否正在运行
  bool get isRunning => _isRunning;

  // 开始统计（可选择是否启用自动计算）
  void start({
    bool enableAutoCalculation = false,
    Duration autoCalculationInterval = const Duration(seconds: 2),
    Function(NotifyStats)? onStatsUpdated,
    Function(String)? onPerformanceAlert,
  }) {
    if (_isRunning) {
      print('⚠️ NotifyRateCalculator已在运行中，跳过重复启动');
      return;
    }

    reset();
    _isRunning = true;
    _startRateTimer();

    if (enableAutoCalculation) {
      _enableAutoCalculation(
        interval: autoCalculationInterval,
        onStatsUpdated: onStatsUpdated,
        onPerformanceAlert: onPerformanceAlert,
      );
    }

    print('✅ NotifyRateCalculator单例已启动');
  }

  // 启用自动计算功能
  void _enableAutoCalculation({
    Duration interval = const Duration(seconds: 2),
    Function(NotifyStats)? onStatsUpdated,
    Function(String)? onPerformanceAlert,
  }) {
    _autoCalculationEnabled = true;
    _onStatsUpdated = onStatsUpdated;
    _onPerformanceAlert = onPerformanceAlert;

    _autoStatsTimer = Timer.periodic(interval, (timer) {
      if (_isRunning) {
        _performAutoCalculation();
      } else {
        timer.cancel();
      }
    });
  }

  // 执行自动计算和分析
  void _performAutoCalculation() {
    final stats = getStats();

    // 记录最近的速率用于趋势分析
    _recentRates.add(stats.currentRate);
    if (_recentRates.length > 10) {
      _recentRates.removeAt(0);
    }

    // 回调统计更新
    _onStatsUpdated?.call(stats);

    // 性能检查和警告
    _checkPerformanceAndAlert(stats);

    // 自动打印统计（可选）
    // if (_autoCalculationEnabled) {
    //   _printAutoStats(stats);
    // }
  }

  // 性能检查和警告
  void _checkPerformanceAndAlert(NotifyStats stats) {
    final now = DateTime.now();

    // 限制警告频率（5秒内不重复警告）
    if (_lastAlertTime != null &&
        now.difference(_lastAlertTime!).inSeconds < 5) {
      return;
    }

    String? alertMessage;

    if (stats.currentRate == 0.0 && _packetCount > 0) {
      alertMessage = "⚠️ Notify回调已停止";
    } else if (stats.currentRate > 200) {
      alertMessage = "⚠️ Notify频率过高: ${stats.currentRate.toStringAsFixed(1)}/s，可能需要优化";
    } else if (stats.currentRate < 10 && stats.currentRate > 0) {
      alertMessage = "⚠️ Notify频率偏低: ${stats.currentRate.toStringAsFixed(1)}/s，可能影响音频质量";
    } else if (_isRateUnstable()) {
      alertMessage = "⚠️ Notify频率不稳定，请检查蓝牙连接";
    }

    if (alertMessage != null) {
      _lastAlertTime = now;
      _onPerformanceAlert?.call(alertMessage);
      // print(alertMessage); // 同时输出到控制台
    }
  }

  // 检查速率是否不稳定
  bool _isRateUnstable() {
    if (_recentRates.length < 5) return false;

    final avg = _recentRates.reduce((a, b) => a + b) / _recentRates.length;
    if (avg == 0) return false;

    final variance = _recentRates
        .map((rate) => ((rate - avg) * (rate - avg)))
        .reduce((a, b) => a + b) / _recentRates.length;

    final coefficientOfVariation = (variance / (avg * avg));
    return coefficientOfVariation > 0.5; // 变异系数 > 0.5 认为不稳定
  }

  // 自动打印统计信息
  void _printAutoStats(NotifyStats stats) {
    print('🔄 Notify统计 - 速率: ${stats.currentRate.toStringAsFixed(1)}/s, '
        '数据: ${(stats.dataRatePerSecond/1024).toStringAsFixed(1)}KB/s, '
        '包大小: ${stats.averagePacketSize.toStringAsFixed(0)}字节');
  }

  // 停止统计
  void stop() {
    if (!_isRunning) {
      print('⚠️ NotifyRateCalculator未在运行');
      return;
    }

    _rateTimer?.cancel();
    _autoStatsTimer?.cancel();
    _autoCalculationEnabled = false;
    _isRunning = false;

    // 输出最终统计
    if (_packetCount > 0) {
      final finalStats = getStats();
      print('\n📊 NotifyRateCalculator最终统计结果:');
      print(finalStats.toString());
    }

    print('🛑 NotifyRateCalculator单例已停止');
  }

  // 重置统计（保持单例状态）
  void reset() {
    _packetCount = 0;
    _startTime = null;
    _currentSecondCount = 0;
    _currentRate = 0.0;
    _totalBytes = 0;
    _averagePacketSize = 0.0;
    _recentRates.clear();
    _lastAlertTime = null;
  }

  // 完全重置（包括停止运行）
  void fullReset() {
    stop();
    reset();
    _onStatsUpdated = null;
    _onPerformanceAlert = null;
  }

  // notify回调中调用这个方法
  void onNotifyReceived(Uint8List data) {
    if (!_isRunning) {
      print('⚠️ NotifyRateCalculator未启动，请先调用start()');
      return;
    }

    // 第一次回调记录开始时间
    _startTime ??= DateTime.now();

    // 统计数据
    _packetCount++;
    _currentSecondCount++;
    _totalBytes += data.length;
    _averagePacketSize = _totalBytes / _packetCount;

    // 如果启用自动计算，可以在这里做额外处理
    if (_autoCalculationEnabled) {
      _processDataPacket(data);
    }
  }

  // 处理数据包（内部计算逻辑）
  void _processDataPacket(Uint8List data) {
    // 可以在这里添加数据包分析逻辑
    // 比如：数据包质量检查、格式验证等

    // 示例：检查数据包是否为空或异常
    if (data.isEmpty) {
      print('⚠️ 收到空数据包');
    } else if (data.length > 500) {
      print('⚠️ 数据包异常大: ${data.length}字节');
    }

    // 示例：简单的数据质量分析
    _analyzeDataQuality(data);
  }

  // 数据质量分析
  void _analyzeDataQuality(Uint8List data) {
    // 检查数据是否全为零（可能是静音或错误数据）
    bool allZeros = data.every((byte) => byte == 0);
    if (allZeros && data.length > 10) {
      print('⚠️ 检测到可能的静音数据包');
    }

    // 检查数据模式（可选）
    if (_packetCount % 100 == 0) { // 每100个包分析一次
      final uniqueBytes = data.toSet().length;
      final entropy = uniqueBytes / 256.0;
      if (entropy < 0.1) {
        print('⚠️ 数据熵值较低，可能存在问题');
      }
    }
  }

  // 启动每秒统计定时器
  void _startRateTimer() {
    _rateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning) {
        _currentRate = _currentSecondCount.toDouble();
        _currentSecondCount = 0; // 重置计数器
      } else {
        timer.cancel();
      }
    });
  }

  // 获取当前速率 (包/秒)
  double getCurrentRate() => _currentRate;

  // 获取总体平均速率
  double getAverageRate() {
    if (_startTime == null || _packetCount == 0) return 0.0;

    final duration = DateTime.now().difference(_startTime!);
    if (duration.inMilliseconds == 0) return 0.0;

    return _packetCount * 1000.0 / duration.inMilliseconds;
  }

  // 获取数据速率 (字节/秒)
  double getDataRate() {
    return _currentRate * _averagePacketSize;
  }

  // 获取性能评估
  String getPerformanceAssessment() {
    final rate = _currentRate;
    final stability = _isRateUnstable() ? '不稳定' : '稳定';

    String performance;
    if (rate > 100) {
      performance = '高频率';
    } else if (rate > 40) {
      performance = '正常';
    } else if (rate > 10) {
      performance = '偏低';
    } else {
      performance = '异常';
    }

    return '$performance ($stability)';
  }

  // 获取统计信息
  NotifyStats getStats() {
    final runTime = _startTime != null
        ? DateTime.now().difference(_startTime!).inMilliseconds / 1000.0
        : 0.0;

    return NotifyStats(
      totalPackets: _packetCount,
      runTimeSeconds: runTime,
      currentRate: _currentRate,
      averageRate: getAverageRate(),
      totalBytes: _totalBytes,
      averagePacketSize: _averagePacketSize,
      dataRatePerSecond: getDataRate(),
      performanceAssessment: getPerformanceAssessment(),
      isStable: !_isRateUnstable(),
    );
  }
}

// 增强的统计信息类
class NotifyStats {
  final int totalPackets;
  final double runTimeSeconds;
  final double currentRate;
  final double averageRate;
  final int totalBytes;
  final double averagePacketSize;
  final double dataRatePerSecond;
  final String performanceAssessment;
  final bool isStable;

  NotifyStats({
    required this.totalPackets,
    required this.runTimeSeconds,
    required this.currentRate,
    required this.averageRate,
    required this.totalBytes,
    required this.averagePacketSize,
    required this.dataRatePerSecond,
    required this.performanceAssessment,
    required this.isStable,
  });

  @override
  String toString() {
    return '''
📊 Notify回调统计报告
━━━━━━━━━━━━━━━━━━━━
📦 数据包统计:
   总包数: $totalPackets 个
   运行时间: ${runTimeSeconds.toStringAsFixed(1)} 秒
   
📈 速率统计:
   当前速率: ${currentRate.toStringAsFixed(1)} 包/秒
   平均速率: ${averageRate.toStringAsFixed(1)} 包/秒
   
💾 数据统计:
   总数据量: ${(totalBytes/1024).toStringAsFixed(1)} KB
   平均包大小: ${averagePacketSize.toStringAsFixed(1)} 字节
   数据速率: ${(dataRatePerSecond/1024).toStringAsFixed(1)} KB/s
   
🎯 性能评估:
   状态: $performanceAssessment
   稳定性: ${isStable ? '✅ 稳定' : '⚠️ 不稳定'}
━━━━━━━━━━━━━━━━━━━━
''';
  }
}