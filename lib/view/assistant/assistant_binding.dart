import 'package:get/get.dart';
import 'assistant_logic.dart';

class AssistantBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AssistantLogic());
  }
}
