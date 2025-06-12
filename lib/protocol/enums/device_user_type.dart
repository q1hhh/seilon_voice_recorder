enum DeviceUserType {
  /**
   * 未知
   */
  Unknown(value: -1),
  /**
   * 0x1 -指纹
   */
  FingerPrint(value: 1),
  /**
   * 0x2 -密码
   */
  Password(value: 2),
  /**
   * 0x3 -卡
   */
  Card(value: 3),
  /**
   * 0x4 -远程授权[带时效]
   */
  RemotePassword(value: 4),
  /**
   * 超级SIM卡
   */
  SuperSimCard(value: 5),
  /**
   * 0x06 临时密码[一次有效]
   */
  TempPassword(value: 6),
  /**
   * 0x07 动态密码
   */
  DynamicPassword(value: 7),
  /**
   * 0x8 -机械钥匙
   */
  MetalKey(value: 8),
  /**
   * 0x0A -蓝牙开锁
   */
  BluetoothOpen(value: 10),
  /**
   *  蓝牙密码
   */
  BluetoothPassword(value: 11),
  /**
   * 0x0C -人脸
   */
  Face(value: 12),
  /**
   * 内门开锁
   */
  IndoorOpen(value: 13);

  final int value;

  const DeviceUserType({
    required this.value,
  });
}