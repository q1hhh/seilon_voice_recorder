import 'package:flutter/material.dart';

class OtaUpgradeProcess extends StatelessWidget {
  final double progress; // 0.0 ~ 1.0

  const OtaUpgradeProcess({
    super.key,
    required this.progress
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            value: progress,         // 填充百分比
            strokeWidth: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        Text(
          "${(progress * 100).toStringAsFixed(0)}%",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
