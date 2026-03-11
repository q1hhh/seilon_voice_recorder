import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Recording_pen/theme/app_colors.dart';
import 'package:Recording_pen/wiget/aurora_background.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "工具箱",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Get.toNamed("/settings"),
          ),
        ],
      ),
      body: AuroraBackground(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // 工具选项网格
              Expanded(
                child: ToolsGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ToolsGrid extends StatelessWidget {
  ToolsGrid({super.key});

  final List<ToolOption> tools = [
    ToolOption(
      name: "蓝牙录音",
      description: "蓝牙录音测试",
      icon: Icons.bluetooth_outlined,
      route: "/search",
      color: AppColors.primaryColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return ToolCard(tool: tool);
      },
    );
  }
}

class ToolCard extends StatelessWidget {
  final ToolOption tool;

  const ToolCard({
    super.key,
    required this.tool,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showClickAnimation(context);
        Future.delayed(const Duration(milliseconds: 150), () {
          Get.toNamed(tool.route);
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: tool.color.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图标容器 (发光效果)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tool.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tool.color.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: tool.color.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      tool.icon,
                      color: tool.color,
                      size: 28,
                    ),
                  ),

                  const Spacer(),

                  // 工具名称
                  Text(
                    tool.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // 工具描述
                  Text(
                    tool.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showClickAnimation(BuildContext context) {
    // 简单水波纹/按压动画，通过 GestureDetector 天然支持或外部包装 InkWell
  }
}

class ToolOption {
  final String name;
  final String description;
  final IconData icon;
  final String route;
  final Color color;

  ToolOption({
    required this.name,
    required this.description,
    required this.icon,
    required this.route,
    required this.color,
  });
}