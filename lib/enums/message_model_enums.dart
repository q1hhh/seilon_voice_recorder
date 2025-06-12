enum DeviceStatus {
  workingStatus(2, '工作状态'),
  batteryLevel(3, '电池电量'),
  vibrationIntensity(4, '震动强度'),
  hardwareInfo(5, '硬件信息'),
  controlCommand(6, '控制指令'),
  controlFeedback(7, '控制反馈'),
  sensorData(8, '传感器数据'),
  vibrationRecord(9, '震动记录'),
  audioData(10, '音频数据'),
  recordingStatus(11, '录音状态'),
  offlineAudioData(12, '离线音频数据'),
  radarStatus(13, '毫米波雷达状态'),
  offlineSensorData(14, '离线传感器数据'),
  heartbeatReport(15, '心跳上报');

  final int code;
  final String description;

  const DeviceStatus(this.code, this.description);

  static DeviceStatus? fromCode(int code) {
    return DeviceStatus.values.firstWhere((e) => e.code == code);
  }
}