import 'package:flutter/material.dart';

class AppColors {
  // 主色调 - 活力渐变蓝
  static const primaryColor = Color(0xFF4F46E5);  // 靛蓝色
  static const secondaryColor = Color(0xFF7C3AED);  // 紫色
  static const accentColor = Color(0xFFFF3E5C);  // 珊瑚粉
  static const backgroundColor = Color(0xFFF8FAFC);  // 浅灰蓝背景
  static const cardColor = Colors.white;  // 卡片背景色
  static const textColor = Color(0xFF1E293B);  // 深灰文字

  // 渐变背景 - 活力渐变
  static const gradientColors = [
    Color(0xFF4F46E5),  // 靛蓝色
    Color(0xFF7C3AED),  // 紫色
  ];

  // 信号强度颜色 - 活力配色
  static const signalColors = {
    'excellent': Color(0xFF10B981),  // 翠绿色 - 信号极好
    'good': Color(0xFF4F46E5),      // 靛蓝色 - 信号良好
    'fair': Color(0xFFF59E0B),      // 橙色 - 信号一般
    'poor': Color(0xFFEF4444),      // 红色 - 信号差
  };

  // 按钮渐变
  static const buttonGradient = [
    Color(0xFF4F46E5),  // 靛蓝色
    Color(0xFF7C3AED),  // 紫色
  ];

  // 卡片阴影颜色
  static const shadowColor = Color(0xFF4F46E5);

  // 文字颜色变体
  static const textSecondary = Color(0xFF64748B);  // 次要文字
  static const textTertiary = Color(0xFF94A3B8);  // 第三级文字

  // 状态颜色
  static const successColor = Color(0xFF10B981);  // 成功绿
  static const warningColor = Color(0xFFF59E0B);  // 警告橙
  static const errorColor = Color(0xFFEF4444);    // 错误红
  static const infoColor = Color(0xFF3B82F6);     // 信息蓝
} 