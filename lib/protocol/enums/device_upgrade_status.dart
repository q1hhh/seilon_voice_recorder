enum DeviceUpgradeStatus {
  /**
   * 0：门锁
   */
  lock(value: 0,name:'门锁'),
  /**
   * 1：ble
   */
  ble(value: 1,name:'蓝牙'),
  /**
   * 2：wifi
   */
  WiFi(value: 2,name:'WI-FI');


  final int value;
  final String name;

  const DeviceUpgradeStatus({
    required this.value,
    required this.name,
  });
  static DeviceUpgradeStatus fromValue(int value) {
    var values = DeviceUpgradeStatus.values;

    for (var type in values) {
      if(type.value == value) {
        return type;
      }
    }
    return DeviceUpgradeStatus.lock;
  }
}