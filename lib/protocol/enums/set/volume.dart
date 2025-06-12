// 音量
enum Volume {
  silent(0, '高'),
  low(1, '中'),
  medium(2, '低'),
  high(3, '静');

  final int value;
  final String chineseName;

  const Volume(this.value, this.chineseName);

  String getChineseName() => chineseName;

  static Volume fromValue(int value) {
    return Volume.values.firstWhere((v) => v.value == value, orElse: () => Volume.silent);
  }
}
