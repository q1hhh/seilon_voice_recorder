// 灵敏度
enum Sensitivity {
  low(0, false, '低灵敏度'),
  high(1, false, '高灵敏度');

  final int value;
  final bool flag;
  final String chineseName;

  const Sensitivity(this.value, this.flag, this.chineseName);

  String getChineseName() => chineseName;
}