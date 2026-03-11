import 'package:flutter/material.dart';

class AppColors {
  // 主色调 - Aurora 极光渐变风格 (Neon Cyan, Magenta, Purple)
  static const primaryColor = Color(0xFF00FFCC);  // 极光青/青色
  static const secondaryColor = Color(0xFFFF00FF);  // 极光紫红/洋红
  static const accentColor = Color(0xFF7000FF);  // 极光深紫
  
  // 背景色 - 深色背景以凸显极光效果
  static const backgroundColor = Color(0xFF0B0F19);  // 极深蓝灰
  
  // 卡片背景色 - 毛玻璃效果的基础色 (半透明白/灰)
  static const cardColor = Color(0x15FFFFFF);  // 极光半透明玻璃态
  static const textColor = Color(0xFFF1F5F9);  // 亮灰白文字

  // 极光渐变背景
  static const gradientColors = [
    Color(0xFF00FFCC),  // 青
    Color(0xFF7000FF),  // 深紫
    Color(0xFFFF00FF),  // 紫红
  ];

  // 信号强度颜色 - 活力配色保持高对比度
  static const signalColors = {
    'excellent': Color(0xFF00FFCC),  // 极光青
    'good': Color(0xFF3B82F6),       // 蓝
    'fair': Color(0xFFF59E0B),       // 橙色
    'poor': Color(0xFFFF0055),       // 极光红/粉红
  };

  // 按钮渐变
  static const buttonGradient = [
    Color(0xFF7000FF),  // 深紫
    Color(0xFFFF00FF),  // 紫红
  ];

  // 卡片阴影颜色 (用于发光效果)
  static const shadowColor = Color(0x6600FFCC); // 青色发光

  // 文字颜色变体
  static const textSecondary = Color(0xFF94A3B8);  // 次要文字
  static const textTertiary = Color(0xFF64748B);   // 第三级文字

  // 状态颜色
  static const successColor = Color(0xFF00FFCC);  // 成功青
  static const warningColor = Color(0xFFF59E0B);  // 警告橙
  static const errorColor = Color(0xFFFF0055);    // 错误极光粉
  static const infoColor = Color(0xFF3B82F6);     // 信息蓝
} 