class LockParam {
  final int value;
  final String nameEn;
  final String nameZh;

  const LockParam(this.value, this.nameEn, this.nameZh);

  static final Map<int, LockParam> _valueToType = {
    0x00: LockParam(0x00, 'LockType // to do', '锁类型'),
    0x01: LockParam(0x01, 'Verify // to do', '验证方式'),
    0x02: LockParam(0x02, 'Volume  // to do ', '音量'),
    0x03: LockParam(0x03, 'language', '语言'),
    0x04: LockParam(0x04, 'Card Encryption // to do', '是否开启卡片加密'),
    0x05: LockParam(0x05, 'Motor Running Time // to do', '电机转动时间'),
    0x06: LockParam(0x06, 'Sensitivity // to do', '按键灵敏度'),
    0x07: LockParam(0x07, 'Dynamic Cipher // to do', '是否使能动态密码'),
    0x08: LockParam(0x08, 'Enabling NFC // to do', '是否开启nfc'),
    0x09: LockParam(0x09, 'Local Entry // to do', '是否支持本地录入'),
    0x0A: LockParam(0x0A, 'Fingerprint Module // to do', '指纹模组类型'),
    0x0B: LockParam(0x0B, 'Automatic Wake Up Night // to do', '是否使能凌晨2点到凌晨4点自动自动唤醒'),
    0x0C: LockParam(0x0C, 'Automatic Wake Up Day // to do', '门锁早上9点到晚上9点自动唤醒时间'),
    0x0D: LockParam(0x0D, 'BLE Remote // to do', '是否开启蓝牙远程调试'),
    0x0E: LockParam(0x0E, 'User Use Door // to do', '是否允许用户开门'),
    0x0F: LockParam(0x0F, 'Fingerprint Error Number // to do', '指纹最大试错次数'),
    0x10: LockParam(0x10, 'Max Users Number // to do', '支持最大用户数量'),
    0x11: LockParam(0x11, 'Door Unclosed Alarm // to do', '设置门未关报警相关参数'),
    0x12: LockParam(0x12, 'Remote Communication Version // to do', '门锁支持远程通信协议版本'),
    0x13: LockParam(0x13, 'Offline Password Version // to do', '门锁支持离线密码版本'),
    0x14: LockParam(0x14, 'Door Direction // to do', '设置门开门方向'),
    0x15: LockParam(0x15, 'Tongue Wake Up  // to do', '是否使能碰舌唤醒'),
    0x16: LockParam(0x16, 'Local Normally Open // to do', '使能本地常开'),
    0x17: LockParam(0x17, 'Auto Lock // to do', '定时上锁'),
    0x18: LockParam(0x18, 'Dwelling Detection // to do', '逗留检测'),
    0x19: LockParam(0x19, 'Torque Setting // to do', '扭力设置'),
    0x1A: LockParam(0x1A, 'radarSensitivity', '雷达灵敏度'),
    0x21: LockParam(0x21, 'BatteryLevel', '门锁电量'),
    0x22: LockParam(0x22, 'Motor Status // to do', '电机状态'),
    0x23: LockParam(0x23, 'Keyboard Disable // to do', '键盘禁用'),
    0x24: LockParam(0x24, 'LED Disable // to do', '指示灯禁用'),
    0x25: LockParam(0x25, 'opening // to do', '常开状态'),
    0x30: LockParam(0x30, 'opening // to do', '大屹常开模式'),
    0x31: LockParam(0x31, 'alarmAntiPick', '防撬开关使能'),
    0x32: LockParam(0x32, 'firstOpen', '大屹前锁常开模式'),
    0x33: LockParam(0x33, 'backOpen', '大屹后锁常开模式'),
    0x34: LockParam(0x34, 'sensitve', '大屹按键灵敏度'),
    0xFF: LockParam(0xFF, 'Types  // to do', '获取所有参数类型'),
  };

  static LockParam? fromValue(int value) {
    return _valueToType[value];
  }
}