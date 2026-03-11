import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AlertButton extends StatelessWidget {
  final String? confirmText;
  final String? cancelText;
  final VoidCallback confirmCallback;
  final VoidCallback cancelCallback;

  const AlertButton({
    super.key,
    required this.confirmCallback,
    required this.cancelCallback,
    this.confirmText = "确认",
    this.cancelText = "取消"
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              cancelCallback();
            },
            child: Text(cancelText!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),),
          ),
        ),
        const SizedBox(width: 20,),
        SizedBox(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor.withOpacity(0.8),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              confirmCallback();
            },
            child: Text(confirmText!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),),
          ),
        ),
      ],
    );
  }
}

