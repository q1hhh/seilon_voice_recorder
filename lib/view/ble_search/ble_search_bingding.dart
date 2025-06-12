import 'package:get/get.dart';
import 'package:Recording_pen/view/ble_search/ble_search_logic.dart';

class BlueSearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BleSearchLogic());
  }
}
