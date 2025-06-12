// 功能
enum Feature {
  frontPanelAlwaysOn(50, false, '前面板常开'),
  backPanelAlwaysOn(51, false, '后面板常开'),
  alwaysOn(48, false, '常开'),
  antiTamperAlarm(49, false, '防撬报警'),
  panelSensitivity(52, '', '面板灵敏度'),
  radarSensitivity(26, '', '雷达感应距离');

  final int type;
  final dynamic value;
  final String chineseName;

  const Feature(this.type, this.value, this.chineseName);

  String getChineseName() => chineseName;
}