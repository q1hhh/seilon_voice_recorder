import 'package:get/get_navigation/src/root/internacionalization.dart';
import 'lang/en_us.dart';
import 'lang/zh_cn.dart';
import 'lang/zh_tw.dart';

// 英语、汉语、繁体
class LangPlugin extends Translations {
  @override
  Map<String, Map<String, String>> get keys =>
      {
        'zh_CN': zhCN,
        'en_US': enUS,
        'zh_TW': zhTW
      };
}
