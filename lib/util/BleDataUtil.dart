import 'dart:collection';
import 'dart:typed_data';

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
}
