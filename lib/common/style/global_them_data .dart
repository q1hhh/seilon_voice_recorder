import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './theme_colors.dart';
import './theme_text.dart';

class GlobalThemData {
  // 聚焦色
  static final Color _lightFocusColor = Colors.black.withOpacity(0.12);
  static final Color _darkFocusColor = Colors.white.withOpacity(0.12);

  static ThemeData lightThemeData =
      themeData(lightColorScheme, _lightFocusColor);
  static ThemeData darkThemeData = themeData(darkColorScheme, _darkFocusColor);

  // 主题样式
  static ThemeData themeData(ColorScheme colorScheme, Color focusColor) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0.0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          )),//使用滑动组件appbar回变色问题
      colorScheme: colorScheme,
      canvasColor: colorScheme.background,
      scaffoldBackgroundColor: colorScheme.background,
      highlightColor: Colors.transparent,
      focusColor: focusColor,
      fontFamily: "Roboto",
      textTheme: ThemeText.textTheme(),
    );
  }

  // 白天主题色
  static ColorScheme lightColorScheme = const ColorScheme(
    primary: const Color.fromARGB(197, 0, 0, 0),
    onPrimary: ThemeColors.colorWhite,
    // onPrimary:  Color.fromARGB(255, 240, 239, 239),
    secondary: ThemeColors.colorPrimary,
    onSecondary: ThemeColors.colorWhite,
    error: ThemeColors.colorError,
    onError: ThemeColors.colorWhite,
    // background: ThemeColors.colorWhite,
    background: Color(0xFFFFFFFF),
    onBackground: ThemeColors.colorWhite,
    surface: ThemeColors.colorWhite,
    onSurface: Color.fromARGB(255, 49, 49, 49),
    brightness: Brightness.light,
  );

  // 夜间主题色
  static ColorScheme darkColorScheme = const ColorScheme(
    primary: ThemeColors.colorBlack,
    secondary: ThemeColors.colorBlack,
    background: ThemeColors.colorBlack,
    surface: ThemeColors.colorBlack,
    onBackground: ThemeColors.colorBlack,
    error: ThemeColors.colorBlack,
    onError: ThemeColors.colorBlack,
    onPrimary: ThemeColors.colorBlack,
    onSecondary: ThemeColors.colorBlack,
    onSurface: ThemeColors.colorBlack,
    brightness: Brightness.dark,
  );
}
