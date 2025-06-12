import 'package:flutter/material.dart';
import './theme_colors.dart';

class ThemeText {
  static TextTheme textTheme() {
    return TextTheme(
      // 自定义的文本样式
      displayLarge: TextStyle(
        color: ThemeColors.colorWhite,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: ThemeColors.colorWhite,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: const Color.fromARGB(255, 56, 56, 56),
        fontSize: 24,
      ),
      bodyMedium: TextStyle(
        color: Color.fromARGB(255, 56, 56, 56),
        fontSize: 16,
      ),
      bodySmall: TextStyle(
        color: const Color.fromARGB(255, 56, 56, 56),
        fontSize: 12,
      ),
      labelLarge: TextStyle(
        color: const Color.fromARGB(255, 166, 166, 166),
        fontSize: 24,
      ),
      labelMedium: TextStyle(
        color: const Color.fromARGB(255, 166, 166, 166),
        fontSize: 16,
      ),
      labelSmall: TextStyle(
        color: const Color.fromARGB(255, 166, 166, 166),
        fontSize: 12,
      ),
    );
  }

  //配网内容标题
  static TextStyle netWorkTitleStyle
  = const TextStyle(color: Color.fromARGB(255, 56, 56, 56),
    fontSize: 24,
    fontWeight: FontWeight.bold,);

  //配网内容rgb(1, 99, 97, 105)
  static TextStyle netWorkContentStyle
  = const TextStyle(color: Color.fromARGB(255, 99, 97, 105),
    fontSize: 14,
    fontWeight: FontWeight.w400,);

  static TextStyle commonTitleStyle
  = const TextStyle(color: Color.fromARGB(255, 56, 56, 56),
    fontSize: 20,
    fontWeight: FontWeight.bold,);

  //配网内容
  static TextStyle chooseItemStyle
  = const TextStyle(color: Colors.black,
    fontSize: 16,
    fontWeight: FontWeight.bold,);


}
