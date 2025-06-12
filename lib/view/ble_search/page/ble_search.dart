import 'package:Recording_pen/theme/app_colors.dart';
import 'package:Recording_pen/view/ble_search/ble_search_logic.dart';
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
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
                  fontWeight: FontWeight.w500,
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.gradientColors,
            ),
          ),
        ),
        title: const Text(
          "蓝牙设备",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: controller.reStartScan,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundColor,
              AppColors.backgroundColor.withOpacity(0.8),
            ],
          ),
        ),
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
                                color: AppColors.secondaryColor,
                                fontWeight: FontWeight.w500,
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
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowColor.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
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
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: AppColors.buttonGradient,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.bluetooth,
                                color: Colors.white,
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
