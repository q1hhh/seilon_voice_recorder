enum DeviceUserAttribute {
  /**
   * 管理用户
   */
  Manager(value: 1),
  /**
   * 普通用户
   */
  Normal(value: 2),
  /**
   * 其他用户（备用）
   */
  Other(value: 3),
  /**
   * 时效性用户
   */
  TimeBased(value: 4),
  /**
   * 一次性用户
   */
  OneTime(value: 5),
  /**
   * 周期性
   */
  Period(value: 6),
  /**
   * 临时用户
   */
  Temporary(value: 90),
  /**
   * 无网络用户
   */
  DynamicInfo(value: 100);

  final int value;

  const DeviceUserAttribute({
    required this.value,
  });
}