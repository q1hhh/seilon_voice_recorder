enum SetLockParamType {
  SET_LOCK_TYPE(0x00), // 锁类型
  SET_LOCK_VERIFY(0x01), // 验证方式
  SET_LOCK_VOLUME(0x02), // 音量
  SET_LOCK_LANGUAGE(0x03), // 语言
  SET_LOCK_OPEN_CARD_AND_PASSWORD(0x04), // 是否开启卡片加密码
  SET_LOCK_MOTOR_RUNTIME(0x05), // 电机转动时间
  SET_LOCK_KEYING_SENSITIVITY(0x06), // 按键灵敏度
  SET_LOCK_DYNAMIC_PASSWORDS(0x07), // 是否能使用动态密码
  SET_LOCK_OPEN_NFC(0x08), // 是否开启nfc
  SET_LOCK_SUPPORT_LOCAL_INPUT(0x09), // 是否支持本地录入
  SET_LOCK_FINGERPRINT_MODULE(0x0A), // 指纹模块的类型
  SET_LOCK_NIGHT_AUTOMATIC_WAKEUP(0x0B), // 是否半夜2-4点自动唤醒
  SET_LOCK_MORNING_AUTOMATIC_WAKEUP(0x0C), // 设置早上唤醒时间
  SET_LOCK_BLE_REMOTE(0x0D), // 是否开启蓝牙远程调试
  SET_LOCK_USER_USE_DOOR(0x0E), // 是否允许用户使用门锁
  SET_LOCK_FINGERPRINT_ERR_NUM(0x0F), // 指纹最大是错次数1-254
  SET_LOCK_MAX_USERS_NUM(0x10), // 支持最大用户数量
  SET_LOCK_RADAR(0x1A), // 雷达灵敏度
  SET_LOCK_NORMALLY_OPEN(0x30), // 常开模式
  SET_LOCK_PICK_PROOF_OPEN(0x31), // 防撬开关
  SET_LOCK_BEFORE_OPEN(0x32), // 前锁常开
  SET_LOCK_AFTER_OPEN(0x33), // 后锁常开
  SET_LOCK_KEY(0x34); // 按键灵敏度

  final int value;
  const SetLockParamType(this.value);
  
  static SetLockParamType fromValue(int value) {
    return SetLockParamType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid value: $value'),
    );
  }
 
}