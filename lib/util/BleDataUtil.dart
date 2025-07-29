import 'dart:collection';
import 'dart:typed_data';

import '../ble/model/ManufacturerData.dart';
import 'ByteUtil.dart';

class BleDataUtil {
  static Queue<Uint8List> splitPacketForByte(Uint8List data, int size) {
    Queue<Uint8List> dataQueue = Queue<Uint8List>();
    if (data != null) {
      int index = 0;
      do {
        Uint8List surplusData = Uint8List.sublistView(data, index);
        Uint8List currentData;
        if (surplusData.length <= size) {
          currentData = Uint8List.fromList(surplusData);
          index += surplusData.length;
        } else {
          currentData = Uint8List.sublistView(data, index, index + size);
          index += size;
        }
        dataQueue.add(currentData);
      } while (index < data.length);
    }
    return dataQueue;
  }

  static ManufacturerData getScanData(Uint8List data) {
    var uint8listToHexFull = ByteUtil.uint8ListToHexFull(data);
    var manufacturerData = ManufacturerData();

    // manufacturerData.firmId = ByteUtil.getInt2(data, 0);
    manufacturerData.mac = String.fromCharCodes(data.sublist(0, 12));

    RegExp regex = RegExp(r'[A-Fa-f]'); // 匹配A到F或a到f中的任何一个字符

    int modelNoData1 = 0;
    var model1 = uint8listToHexFull.substring(24, 26);
    if (regex.hasMatch(model1)) {
      modelNoData1 = int.parse(model1, radix: 16);
    } else {
      modelNoData1 = int.parse(model1);
    }

    var model2 = uint8listToHexFull.substring(26, 28);
    int modelNoData2 = 0;
    if (regex.hasMatch(model2)) {
      modelNoData2 = int.parse(model2, radix: 16);
    } else {
      modelNoData2 = int.parse(model2);
    }

    manufacturerData.modelNo = modelNoData1 * 256 + modelNoData2;

    manufacturerData.bind = ByteUtil.getInt1(data, 14);
    manufacturerData.bleVersion = String.fromCharCodes(data.sublist(15, 3 + 15));

    if(data.length > 18) {
      manufacturerData.expandState = ByteUtil.getInt1(data, 18);
    }

    return manufacturerData;
  }
}
