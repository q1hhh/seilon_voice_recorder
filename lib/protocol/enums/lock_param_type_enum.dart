enum LockParamTypeEnum {
  // Enum values
  Unknown(-1),
  All(255),
  BusinessType(0),
  VerifyType(1),
  Volume(2),
  Language(3),
  EnableEncryptCard(4),
  MotorRotationTime(5),
  KeySensitivity(6),
  EnableDynamicPwd(7),
  EnablePhoneCardSupport(8),
  EnableSupportLocalOperation(9),
  AutomaticWakeupFunction(11),
  SetAutoWakeTime(12),
  EnableBLETest(13),
  EnableLock(14),
  FingerMaxError(15),
  LockMaxUserCount(16),
  AlarmLockNotClosed(17),
  DoorOpenDirection(20),
  TongueDepressor(21),
  TimedLock(23),
  StayCheck(24),
  TorsionSetting(25),
  RadarSensitivity(26),
  OneClickOpen(27),
  ChildLock(28),
  AntiLock(29),
  DoorBellVolume(30),
  HumanDetection(31),
  LowPower(32),
  Electric(33),
  OPENING(48),
  AlarmAntiPick(49),
  FIRSTOPENING(50),
  BACKOPENING(51),
  SENSITVE(52),
  OPENINGCYCLE(64),
  OPENINGSTARTTIME(65),
  OPENINGENDTIME(66),
  FIRMWAREVERSION(67),
  BATTERY(68),
  DISABLEKEYBOARD(69),
  DISABLEFINGERPRINT(70);

  // Value of the enum
  final int value;

  const LockParamTypeEnum(this.value);

  // Static method to get the enum from a value
  static LockParamTypeEnum fromValue(int value) {
    return LockParamTypeEnum.values.firstWhere(
          (e) => e.value == value,
      orElse: () => LockParamTypeEnum.Unknown,
    );
  }
}
