// 震动状态
class ShakeStatus {
  int? shakeStatus; // 震动状态(0:空闲; 1:震动中; 2:休眠; 3:充电; 4:升级中; 5:暂停; 255:错误状态)
  int? duration_sec; // 设定的震动持续时⻓（秒）
  int? remaining_sec; // 剩余时⻓（秒）

  ShakeStatus(List<int> data) {
    shakeStatus = data[0];
    duration_sec = data[1];
    remaining_sec = data[2];
  }

  @override
  String toString() {
    return 'ShakeStatus{'
        'shakeStatus: $shakeStatus, '
        'duration_sec: $duration_sec, '
        'remaining_sec: $remaining_sec'
        '}';
  }

  Map<String, dynamic> toMap() {
    return {
      'shakeStatus': shakeStatus,
      'duration_sec': duration_sec,
      'remaining_sec': remaining_sec,
    };
  }
}