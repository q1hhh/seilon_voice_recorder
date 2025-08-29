// 数据速率格式化工具类
import 'notify_rate_calculator.dart';

class DataRateFormatter {
  static const int _bytesSize = 1000;
  
  // 格式化字节速率为可读的单位
  static String formatDataRate(double bytesPerSecond) {
    if (bytesPerSecond >= _bytesSize * _bytesSize) {
      // MB/s
      final mbPerSecond = bytesPerSecond / (_bytesSize * _bytesSize);
      return '${mbPerSecond.toStringAsFixed(2)} MB/s';
    } else if (bytesPerSecond >= _bytesSize) {
      // KB/s
      final kbPerSecond = bytesPerSecond / _bytesSize;
      return '${kbPerSecond.toStringAsFixed(1)} KB/s';
    } else {
      // B/s
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    }
  }
  
  // 格式化数据量为可读的单位
  static String formatDataSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      // GB
      final gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      // MB
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      // KB
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else {
      // B
      return '$bytes B';
    }
  }
  
  // 格式化包速率
  static String formatPacketRate(double packetsPerSecond) {
    if (packetsPerSecond >= 1000) {
      final kPacketsPerSecond = packetsPerSecond / 1000;
      return '${kPacketsPerSecond.toStringAsFixed(1)}K 包/s';
    } else {
      return '${packetsPerSecond.toStringAsFixed(1)} 包/s';
    }
  }
  
  // 综合格式化统计信息
  static String formatComprehensiveStats(NotifyStats stats) {
    final dataRate = formatDataRate(stats.dataRatePerSecond);
    final packetRate = formatPacketRate(stats.currentRate);
    final totalData = formatDataSize(stats.totalBytes);
    final avgPacketSize = stats.averagePacketSize.toStringAsFixed(0);
    
    return '📊 $packetRate | $dataRate | 总计: $totalData | 平均包大小: ${avgPacketSize}B';
  }
  
  // 获取颜色提示（用于UI显示）
  static DataRateLevel getDataRateLevel(double bytesPerSecond) {
    final kbPerSecond = bytesPerSecond / 1024;
    
    if (kbPerSecond >= 100) {
      return DataRateLevel.high;      // 高速率 >= 100KB/s
    } else if (kbPerSecond >= 10) {
      return DataRateLevel.medium;    // 中速率 >= 10KB/s
    } else if (kbPerSecond >= 1) {
      return DataRateLevel.low;       // 低速率 >= 1KB/s
    } else {
      return DataRateLevel.veryLow;   // 极低速率 < 1KB/s
    }
  }
}

// 数据速率等级枚举
enum DataRateLevel {
  veryLow,  // < 1KB/s
  low,      // 1-10KB/s
  medium,   // 10-100KB/s
  high,     // >= 100KB/s
}

// 扩展NotifyRateCalculator以支持格式化输出
extension NotifyRateCalculatorFormatter on NotifyRateCalculator {
  
  // 获取格式化的当前数据速率
  String getFormattedDataRate() {
    final stats = getStats();
    return DataRateFormatter.formatDataRate(stats.dataRatePerSecond);
  }
  
  // 获取格式化的包速率
  String getFormattedPacketRate() {
    final stats = getStats();
    return DataRateFormatter.formatPacketRate(stats.currentRate);
  }
  
  // 获取简洁的状态信息
  String getFormattedStatus() {
    final stats = getStats();
    return DataRateFormatter.formatComprehensiveStats(stats);
  }
}