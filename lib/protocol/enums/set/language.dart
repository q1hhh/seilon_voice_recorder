enum Language {
  ZH(0, '中文'),
  EN(1, '英文');

  final int value;
  final String chineseName;

  const Language(this.value, this.chineseName);

  String getChineseName() => chineseName;
}
