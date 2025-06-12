// 设备信息
class DeviceMessage {
  String? model; // 设备的型号和版本信息
  String? macAddress; // 设备mac地址
  String? firmware_version; // 设备的固件版本号
  String? hardware_version; // 设备的硬件版本号
  String? serial_num; // 设备序列号

  DeviceMessage(List<int> data) {
  }

  Map<String, dynamic> toMap() {
    return {
      'model': model,
      'macAddress': macAddress,
      'firmware_version': firmware_version,
      'hardware_version': hardware_version,
      'serial_num': serial_num,
    };
  }

  /// 调试用字符串输出
  @override
  String toString() {
    return '''
      DeviceMessage {
        model: $model,
        macAddress: $macAddress,
        firmware_version: $firmware_version,
        hardware_version: $hardware_version,
        serial_num: $serial_num
      }''';
  }
}