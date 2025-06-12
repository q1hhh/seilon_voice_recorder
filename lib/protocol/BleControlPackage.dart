import 'dart:typed_data';
import 'package:flutter/cupertino.dart';

import '../util/ByteUtil.dart';
import 'BleControlMessage.dart';
import 'LockControllAES.dart';

class BleControlPackage {
  static final Uint8List START = Uint8List.fromList([0x66, 0xAA]); //包头
  static final int END = 0xFE; //包尾

  late int startExtraLength; //开始字节
  late Uint8List start; //包头
  late int sn; //包序号
  late int pid; //分包标识
  late int length; //包长度
  late int version; //版本号

  late int send; //发送方类型
  late int recipient; //接收方类型
  late String deviceId; //设备id
  late String gatewayId; //网关id

  late int cmdCategory; //命令字(命令簇)
  late int cmd; //子命令
  late BleControlMessage message; //消息对象
  late Uint8List messageData; //消息数据
  late int dataCheckLength; //数据区补长
  late int dataCheck; //数据区校验值
  late int check; //校验位
  late int end; //包尾

  BleControlPackage() {
    start = START;
    end = END;
    pid = 0;
    sn = 0;
    version = 0xB1;
  }

  static BleControlPackage toBleLockPackage(BleControlMessage message, int sn) {
    return toPackage(message, sn, "0000000000000000", "0000000000000000", 0xA0, 0xFF);
  }

  static BleControlPackage toPackage(BleControlMessage cmessage, int sn, String deviceSn, String gatewaySn, int recipient, int send) {
    var bleControlPackage = BleControlPackage();
    bleControlPackage.start = (START);
    bleControlPackage.sn = (sn%65535);
    bleControlPackage.gatewayId = (gatewaySn);
    bleControlPackage.deviceId = (deviceSn);
    bleControlPackage.message = (cmessage);
    bleControlPackage.cmdCategory = (cmessage.cmdCategory);
    bleControlPackage.cmd = (cmessage.cmd);
    bleControlPackage.send = (send%65535);
    bleControlPackage.recipient = (recipient%65535);

    if (cmessage != null) {
      bleControlPackage.pid = (cmessage.pid);
    }

    return bleControlPackage;
  }

  ///组装数据成协议字节
  Uint8List toBytes(String key) {
    var alignData = getAlignData(message.toBytes());
    Uint8List data = LockControlAES.encryptAES(
        alignData, key);


    length = (data.length & 0xFFFF) + 32;
    dataCheck = message.check;

    Uint8List bytes = Uint8List(length & 0xFFFF);
    bytes.setRange(0, 2, START);

    bytes.setRange(2, 4, ByteUtil.getUint8ListOfInt2(sn));

    bytes[4] = (pid & 0xFFFF);

    bytes.setRange(5, 7, ByteUtil.getUint8ListOfInt2(length & 0xFFFF));
    bytes[7] = version;

    bytes[8] = send;
    bytes[9] = recipient;

    if (deviceId.length == 12) {
      deviceId = deviceId + "0000";
    }

    bytes.setRange(10, 18, ByteUtil.hexStringToUint8List(deviceId)!);

    if (gatewayId.length == 12) {
      gatewayId = gatewayId + "0000";
    }

    bytes.setRange(18, 26, ByteUtil.hexStringToUint8List(gatewayId)!);

    bytes[26] = cmdCategory;
    bytes[27] = cmd;

    bytes.setRange(28,  28 + data.length, data);

    bytes[length - 1] = END;

    bytes[length - 3] = dataCheck;
    bytes[length - 4] = dataCheckLength;
    check = countCheck(data);

    bytes[length - 2] = check;

    return bytes;
  }

  Uint8List getAlignData(Uint8List data) {
    int length = data.length & 0xFFFF;

    if (length % 16 == 0) {
      dataCheckLength = 0;
      return data;
    } else {
      int padding = 16 - (length % 16);
      int aLength = length + padding;
      Uint8List alignData = Uint8List(aLength);
      alignData.setRange(0, length, data, 0);

      for (int i = length; i < aLength; i++) {
        alignData[i] = 0x00;
      }
      dataCheckLength = (alignData.length - data.length);
      return alignData;
    }
  }

  ///协议解析
  static BleControlPackage? parse(Uint8List bytes) {
    int index = 0;
    if (bytes[index] != START[0] && bytes[index + 1] != START[1]) {
      index++;
    }

    if (index >= bytes.length - 3 ||
        (bytes[index] != START[0] && bytes[index + 1] != START[1])) {
      return null;
    }
    var packge = BleControlPackage();

    packge.startExtraLength = index;

    packge.sn = (ByteUtil.getInt2(bytes, index + 2));
    packge.pid = (bytes[4]);

    packge.length = (ByteUtil.getInt2(bytes, 5));
    packge.version = (bytes[7]);

    packge.send = (bytes[8]);
    packge.recipient = (bytes[9]);

    var deviceSn = Uint8List(8);
    deviceSn.setRange(0, 8, bytes, index + 10);
    packge.deviceId = ByteUtil.uint8ListToHexFull(deviceSn);

    var gatewaySn = Uint8List(8);
    gatewaySn.setRange(0, 8, bytes, index + 18);
    packge.gatewayId = ByteUtil.uint8ListToHexFull(gatewaySn);

    packge.cmdCategory = (bytes[26]);
    packge.cmd = (bytes[27]);

    if ((index + packge.length) > bytes.length || bytes[index + packge.length -1] != END) {
      return null;
    }

    packge.dataCheckLength = (bytes[packge.length - 4]);
    packge.dataCheck = (bytes[packge.length - 3]);
    packge.check = (bytes[packge.length - 2]);


    var data = Uint8List(packge.length - 32);

    try {
      data.setRange(0, data.length, bytes, index + 28);
      packge.messageData = data;
      var check = packge.countCheck(data);

      if (check == bytes[index + packge.length -2]) {
        if (deviceSn[deviceSn.length - 1] == 0x00 && deviceSn[deviceSn.length - 2] == 0x00) {
          packge.deviceId = ByteUtil.uint8ListToHex(deviceSn, 6);
        } else {
          packge.deviceId = ByteUtil.uint8ListToHexFull(deviceSn);
        }

        return packge;
      } else {
        return null;
      }

    } catch(e) {
      print(e);
      return null;
    }
  }

  ///解析数据区数据（有秘钥）
  bool parseMessage(String key) {
    try {
      var decryptData = LockControlAES.decryptAES(messageData, key);
      var data = Uint8List(decryptData.length - dataCheckLength);
      data.setRange(0, data.length, decryptData);
      print('data:${ByteUtil.uint8ListToHexFull(data)}');
      BleControlMessage message = BleControlMessage.parse(data);

      if (message != null) {
        print(message.check);
        print(dataCheck);
        if (message.check == dataCheck) {
          message.pid = pid;
          message.cmdCategory = cmdCategory;
          message.cmd = cmd;
          message.protocol = version;
          this.message = message;
          return true;
        } else {
          return false;
        }
      } else {
        print('message is null');
      }
    } catch (e) {
      print(e);
      return false;
    }
    return false;
  }

  ///解析数据区数据（无秘钥）
  bool parseNotKeyMessage() {
    try {
      BleControlMessage bleControlMessage = BleControlMessage();

      if(bleControlMessage!=null) {
        Uint8List decrypt = messageData;
        Uint8List data = Uint8List(decrypt.length - dataCheckLength);
        data.setRange(0, data.length, decrypt);

        bleControlMessage.data = (data);
        bleControlMessage.pid = (pid);
        bleControlMessage.check = (dataCheck);
        bleControlMessage.cmdCategory = (cmdCategory);
        bleControlMessage.cmd = (cmd);
        message = bleControlMessage;
        return true;
      }
    } catch (e) {
      print(e);
      return false;
    }

    return false;
  }

  ///XOR校验
  int countCheck(Uint8List data) {
    int check = 0;
    List<int> snBytes = ByteUtil.getUint8ListOfInt2(sn);
    check = check ^ snBytes[0];
    check = check ^ snBytes[1];

    check = check ^ pid;

    List<int> lengthNumberBytes = ByteUtil.getUint8ListOfInt2(length);
    check = check ^ lengthNumberBytes[0];
    check = check ^ lengthNumberBytes[1];

    check = check ^ version;

    check = check ^ send;
    check = check ^ recipient;

    List<int> macBytes = ByteUtil.hexStringToList(deviceId);
    for (int i = 0; i < macBytes.length; i++) {
      check = check ^ macBytes[i];
    }

    List<int> gatewayBytes = ByteUtil.hexStringToList(gatewayId);
    for (int i = 0; i < gatewayBytes.length; i++) {
      check = check ^ gatewayBytes[i];
    }

    check = check ^ cmdCategory.toInt();
    check = check ^ cmd;

    for (int i = 0; i < data.length; i++) {
      check = check ^ data[i];
    }

    check = check ^ dataCheckLength;
    check = check ^ dataCheck;

    return check;
  }

  @override
  String toString() {
    return 'BleControlPackage{startExtraLength: $startExtraLength, start: $start, sn: $sn, pid: $pid, length: $length, version: $version, send: $send, recipient: $recipient, deviceId: $deviceId, gatewayId: $gatewayId, cmdCategory: $cmdCategory, cmd: $cmd, message: $message, messageData: $messageData, dataCheckLength: $dataCheckLength, dataCheck: $dataCheck, check: $check, end: $end}';
  }
}