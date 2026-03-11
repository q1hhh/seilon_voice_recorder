import 'dart:ui';
import 'package:Recording_pen/theme/app_colors.dart';
import 'package:Recording_pen/view/ble_search/ble_search_logic.dart';
import 'package:Recording_pen/wiget/aurora_background.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BleSearchPage extends StatelessWidget {
  const BleSearchPage({super.key});

  String _getSignalQuality(int rssi) {
    if (rssi >= -50) return 'excellent';  // 非常近
    if (rssi >= -65) return 'good';      // 较近
    if (rssi >= -80) return 'fair';      // 中等距离
    return 'poor';                       // 较远
  }

  Widget _buildSignalIcon(int rssi) {
    final quality = _getSignalQuality(rssi);
    final color = AppColors.signalColors[quality]!;

    IconData iconData;
    switch (quality) {
      case 'excellent':
        iconData = Icons.signal_cellular_alt;
        break;
      case 'good':
        iconData = Icons.signal_cellular_alt_2_bar;
        break;
      case 'fair':
        iconData = Icons.signal_cellular_alt_1_bar;
        break;
      default:
        iconData = Icons.signal_cellular_0_bar;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 0,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: color, size: 16),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${rssi}dBm',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BleSearchLogic>();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textColor),
        title: const Text(
          "蓝牙设备",
          style: TextStyle(
            color: AppColors.textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textColor),
            onPressed: controller.reStartScan,
          ),
        ],
      ),
      body: AuroraBackground(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
          child: Column(
            children: [
              const SizedBox(height: 16),
              GetBuilder<BleSearchLogic>(
                id: 'scanBle',
                builder: (control) {
                  if (control.scanDeviceMap.isEmpty) {
                    return const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth_searching,
                              size: 64,
                              color: AppColors.primaryColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "正在搜索设备...",
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Expanded(
                    child: ListView.builder(
                      itemCount: control.scanDeviceMap.length,
                      itemBuilder: (context, index) {
                        String key = control.scanDeviceMap.keys.elementAt(index);
                        var device = control.scanDeviceMap[key];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.shadowColor.withOpacity(0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primaryColor.withOpacity(0.5),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryColor.withOpacity(0.3),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.bluetooth,
                                      color: AppColors.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  title: AutoSizeText(
                                    maxLines: 1,
                                    device.device.platformName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  subtitle: AutoSizeText(
                                    maxLines: 1,
                                    key,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  trailing: _buildSignalIcon(device.rssi),
                                  onTap: () => controller.toDeviceInfo(key),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
