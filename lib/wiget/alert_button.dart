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
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: AppColors.shadowColor.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () {
              cancelCallback();
            },
            child: Text(cancelText!, style: TextStyle(fontSize: 15),),
          ),
        ),
        SizedBox(width: 20,),
        SizedBox(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: AppColors.shadowColor.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () {
              confirmCallback();
            },
            child: Text(confirmText!, style: TextStyle(fontSize: 15),),
          ),
        ),
      ],
    );
  }
}
