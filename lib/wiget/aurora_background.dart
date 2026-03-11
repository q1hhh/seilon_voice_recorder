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
        // 深色底色
        Container(color: AppColors.backgroundColor),
        
        // 极光渐变球 1 (青色)
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withOpacity(0.3),
            ),
          ),
        ),
        
        // 极光渐变球 2 (紫红)
        Positioned(
          bottom: -50,
          right: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryColor.withOpacity(0.3),
            ),
          ),
        ),

        // 极光渐变球 3 (深紫)
        Positioned(
          top: 200,
          right: -100,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentColor.withOpacity(0.3),
            ),
          ),
        ),

        // 极光渐变球 4 (青色补光)
        Positioned(
          bottom: 150,
          left: -50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withOpacity(0.2),
            ),
          ),
        ),

        // 高斯模糊层 (玻璃态毛玻璃效果)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
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
