import 'package:flutter/material.dart';

class AppColors {
  // 主色调 - 清新极光渐变 (Indigo, Sky Blue, Fuchsia)
  static const primaryColor = Color(0xFF6366F1);  // 靛蓝
  static const secondaryColor = Color(0xFFD946EF);  // 品红
  static const accentColor = Color(0xFF0EA5E9);  // 天空蓝
  
  // 背景色 - 清爽浅色背景
  static const backgroundColor = Color(0xFFF3F7FF);  // 浅灰蓝
  
  // 卡片背景色 - 毛玻璃效果的基础色 (更饱满的白色玻璃态)
  static const cardColor = Color(0x66FFFFFF);  // 40% 不透明白
  static const textColor = Color(0xFF0F172A);  // 深蓝黑文字

  // 极光渐变背景
  static const gradientColors = [
    Color(0xFF6366F1),  // 靛蓝
    Color(0xFF0EA5E9),  // 天空蓝
    Color(0xFFD946EF),  // 品红
  ];

  // 信号强度颜色 - 清新高对比配色
  static const signalColors = {
    'excellent': Color(0xFF10B981),  // 翠绿色
    'good': Color(0xFF3B82F6),       // 蓝色
    'fair': Color(0xFFF59E0B),       // 橙色
    'poor': Color(0xFFEF4444),       // 红色
  };

  // 按钮渐变
  static const buttonGradient = [
    Color(0xFF6366F1),  // 靛蓝
    Color(0xFFD946EF),  // 品红
  ];

  // 卡片阴影颜色
  static const shadowColor = Color(0x226366F1); // 浅紫色阴影

  // 文字颜色变体
  static const textSecondary = Color(0xFF64748B);  // 次要文字 (石板灰)
  static const textTertiary = Color(0xFF94A3B8);   // 第三级文字 (淡灰)

  // 状态颜色
  static const successColor = Color(0xFF10B981);  // 成功绿
  static const warningColor = Color(0xFFF59E0B);  // 警告橙
  static const errorColor = Color(0xFFEF4444);    // 错误红
  static const infoColor = Color(0xFF0EA5E9);     // 信息蓝
} 