
import 'package:get/get.dart';

class HomeControl extends GetxController {
  // 唯一标识控制指令的id, 要一直递增(范围：0~65535), 超出上限重0开始
  RxInt commandId = 0.obs;
  // 需要记录发送指令id, 用来和控制反馈的id匹配
  RxInt lastSentCommandId = 0.obs;

  @override
  void onReady() {
    super.onReady();
  }

  int getNextCommandId() {
    final nextId = commandId.value;
    lastSentCommandId.value = nextId;
    commandId.value = (commandId.value < 65535) ? commandId.value + 1 : 0;
    return nextId;
  }

  startScan() {
  }
}