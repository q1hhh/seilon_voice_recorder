import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Recording_pen/theme/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
          "我的设备",
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
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => Get.toNamed("/search"),
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
              Expanded(
                child: DeviceList(),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: const Text(
                  "点击右上角添加新设备",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeviceList extends StatelessWidget {
  DeviceList({super.key});

  final List<DeviceItem> devices = [
    DeviceItem(
      name: "录音笔 1",
      lastConnected: "2024-03-10",
      isConnected: true,
    ),
    DeviceItem(
      name: "录音笔 2",
      lastConnected: "2024-03-11",
      isConnected: false,
    ),
    DeviceItem(
      name: "录音笔 3",
      lastConnected: "2024-03-12",
      isConnected: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return DeviceCard(device: device);
      },
    );
  }
}

class DeviceCard extends StatelessWidget {
  final DeviceItem device;

  const DeviceCard({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
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
            Icons.record_voice_over,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        subtitle: Text(
          "上次连接: ${device.lastConnected}",
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: ConnectionStatus(isConnected: device.isConnected),
        onTap: () => Get.toNamed("/assistant"),
      ),
    );
  }
}

class ConnectionStatus extends StatelessWidget {
  final bool isConnected;

  const ConnectionStatus({
    super.key,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? AppColors.successColor : AppColors.textSecondary;

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
          Icon(
            Icons.circle,
            color: color,
            size: 8,
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? "已连接" : "未连接",
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceItem {
  final String name;
  final String lastConnected;
  final bool isConnected;

  DeviceItem({
    required this.name,
    required this.lastConnected,
    required this.isConnected,
  });
}
