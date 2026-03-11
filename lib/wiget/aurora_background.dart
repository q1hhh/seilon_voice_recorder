import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:Recording_pen/theme/app_colors.dart';

class AuroraBackground extends StatelessWidget {
  final Widget child;

  const AuroraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 浅色底色
        Container(color: AppColors.backgroundColor),
        
        // 极光渐变球 1 (靛蓝)
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withOpacity(0.12),
            ),
          ),
        ),
        
        // 极光渐变球 2 (品红)
        Positioned(
          bottom: -50,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryColor.withOpacity(0.1),
            ),
          ),
        ),

        // 极光渐变球 3 (天空蓝)
        Positioned(
          top: 250,
          right: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentColor.withOpacity(0.12),
            ),
          ),
        ),

        // 极光渐变球 4 (补色靛蓝)
        Positioned(
          bottom: 150,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withOpacity(0.08),
            ),
          ),
        ),

        // 高斯模糊层 (增强玻璃感)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // 顶层内容
        SafeArea(child: child),
      ],
    );
  }
}
