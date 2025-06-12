import 'package:Recording_pen/util/my_phone_device_util.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../theme/app_colors.dart';

class MainFrame extends StatefulWidget {
  final Widget child;
  const MainFrame({super.key, required this.child});

  @override
  State<StatefulWidget> createState() => _MainFrameState();
}

class _MainFrameState extends State<MainFrame> {
  String appName = '';
  String appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  void _loadAppInfo() async {
    final name = await MyPhoneDeviceUtil.getAppName();
    final version = await MyPhoneDeviceUtil.getAppVersion();
    setState(() {
      appName = name;
      appVersion = version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onPanStart: (_) => windowManager.startDragging(),
          child: Container(
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.gradientColors,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Text(
                  "$appName $appVersion",
                  style: const TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.none,),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.white, size: 17,),
                  onPressed: () => windowManager.minimize(),
                ),
                IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.white, size: 17,),
                  onPressed: () => windowManager.close(),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
