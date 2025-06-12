import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MyConfigurator {
  late SharedPreferences _sharedPreferences;
  static final MyConfigurator _instance = MyConfigurator._internal();

  factory MyConfigurator() {
    return _instance;
  }

  MyConfigurator._internal();

  Future<void> initSharedPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  void setSharedString(String name, String value) {
    _sharedPreferences.setString(name, value);
  }

  String? getSharedString(String name) {
    var stringValue = _sharedPreferences.getString(name);

    if (stringValue != null) {
      return stringValue;
    }
    return null;
  }

  void setSharedInt(String name, int num) {
    _sharedPreferences.setInt(name, num);
  }

  int? getSharedInt(String name) {
    return _sharedPreferences.getInt(name);
  }

  Future<void> setSharedMap(String name, Map map) async {
    String jsonString = jsonEncode(map);

    await _sharedPreferences.setString(name, jsonString);
  }

  Map<String, dynamic>? getSharedMap(String name) {
    String? jsonString = _sharedPreferences.getString(name);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        print('保存的数据不是map: $e');
        return null;
      }
    }
    return null;
  }

  void cleanShared(String name) {
    _sharedPreferences.remove(name);
  }

  /// 更新指定Map中的某个键对应的值
  /// @param map 需要更新的Map对象
  /// @param key Map中的键
  /// @param value 新的值
  Future<void> updateSharedMapValue(
      String name, String key, dynamic value) async {
    final map = getSharedMap(name);
    if (map != null) {
      map[key] = value; // 更新 Map 中的值
      await setSharedMap(name, map); // 重新保存 Map
    }
  }
}
