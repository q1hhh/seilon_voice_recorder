import 'package:Recording_pen/view/assistant/page/assistant_page.dart';
import 'package:get/get.dart';
import 'package:Recording_pen/view/home.dart';

import '../view/assistant/assistant_binding.dart';
import '../view/ble_search/ble_search_bingding.dart';
import '../view/ble_search/page/ble_search.dart';

class AppPage {
  static final routes = [
    GetPage(name: "/home",
      page: () => HomePage(),
    ),
    GetPage(name: "/search",
      page: () => BleSearchPage(),
      binding: BlueSearchBinding()
    ),
    GetPage(name: "/assistant",
      page: () => AssistantPage(),
      binding: AssistantBinding()
    ),
  ];
}
