import '../../../util/ByteUtil.dart';
import '../../BleControlMessage.dart';

class DeviceInfoReplyMessage extends BleControlMessage {
  String? mac;
  String? model;// 型号
  String? version;// 版本
  String? sn;
  int? battery; // 电量
  int? powerBank;// 充电宝状态(0:充电, 1:放电)
  int? chargePower; // 充电功率
  int? dischargePower; // 放电功率
  int? recordStatus; // 录音状态(0:未录音, 1:会议录音, 2:通话录音)
  int? wifiStatus; // wifi状态(1:开启 0:关闭)
  int? emmcUsedCapacity; // emmc已用容量(单位MB)
  int? emmcCapacityTotal; // emmc总容量(单位MB)
  int? uDiskStatus; // u盘状态(1:开启, 0:关闭)
  int? recordFormat; // 录音格式(0: opus, 1: PCM)
  int? capacityAlertValue; // 容量不足提醒阈值(0~20)，默认剩余容量不足20%提醒
  int? forgetCloseRecordValue; // 忘记关闭录音提醒(单位: 小时)
  int? typeCBattery; // Type-C停止输出电量(0~100例如阈值是20，电芯容量低于20%时，移动电源和无线充将无法给手机和其他设备充电，剩余电量仅用于录音功能。)
  int? fileEncryptionOption; // 文件加密选项(0:不加密 1:加密)
  int? recordLight; // 录音指示灯(0:录音时保持灭灯, 1录音时常亮显示)


  DeviceInfoReplyMessage(BleControlMessage ble) {
    cmdCategory = ble.cmdCategory;
    cmd = ble.cmd;
    data = ble.data;

    if(ble.isSuccess()) {
      mac = ByteUtil.uint8ListToHexFull(data.sublist(1, 7));
      model = String.fromCharCodes(data.sublist(7, 27));
      version = String.fromCharCodes(data.sublist(27, 37));
      sn = String.fromCharCodes(data.sublist(37, 57));
      battery = data[57];
      powerBank = data[58];
      chargePower = ByteUtil.getInt2(data, 59);
      dischargePower = ByteUtil.getInt2(data, 61);
      recordStatus = data[63];
      wifiStatus = data[64];
      emmcUsedCapacity = ByteUtil.getInt(data, 65);
      emmcCapacityTotal = ByteUtil.getInt(data, 69);
      uDiskStatus = data[73];
      recordFormat = data[74];
      capacityAlertValue = data[75];
      forgetCloseRecordValue = data[76];
      typeCBattery = data[77];
      fileEncryptionOption = data[78];
      recordLight = data[79];
    }
  }

  @override
  String toString() {
    return 'DeviceInfoReplyMessage{'
        'mac: $mac, '
        'model: $model, '
        'version: $version, '
        'sn: $sn, '
        'battery: $battery, '
        'powerBank: $powerBank, '
        'chargePower: $chargePower, '
        'dischargePower: $dischargePower, '
        'recordStatus: $recordStatus, '
        'wifiStatus: $wifiStatus, '
        'emmcUsedCapacity: $emmcUsedCapacity, '
        'emmcCapacityTotal: $emmcCapacityTotal, '
        'uDiskStatus: $uDiskStatus, '
        'recordFormat: $recordFormat, '
        'capacityAlertValue: $capacityAlertValue, '
        'forgetCloseRecordValue: $forgetCloseRecordValue, '
        'typeCBattery: $typeCBattery, '
        'fileEncryptionOption: $fileEncryptionOption, '
        'recordLight: $recordLight'
        '}';
  }

}