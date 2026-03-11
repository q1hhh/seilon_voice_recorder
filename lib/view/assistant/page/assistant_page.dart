import 'dart:ui';
import 'package:Recording_pen/controllers/home_control.dart';
import 'package:Recording_pen/theme/app_colors.dart';
import 'package:Recording_pen/util/log_util.dart';
import 'package:Recording_pen/view/assistant/assistant_logic.dart';
import 'package:Recording_pen/wiget/aurora_background.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../controllers/deviceConnect.dart';
import '../../../util/view_log_util.dart';

class AssistantPage extends StatelessWidget {
  AssistantPage({super.key});

  final assistantLogic = Get.find<AssistantLogic>();
  final deviceConnectLogic = DeviceConnectLogic();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: AuroraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 降噪控制卡片
                _buildNoiseReductionCard(),

                // 文件状态信息卡片
                _buildFileStatusCard(),

                // 日志区域 - 限制最大高度
                _buildLogSection(),

                // 功能按钮区域 - 固定在底部
                _buildActionButtonsSection(),

                // 底部安全区域
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: Obx(() => Center(
        child: Text(assistantLogic.dataRate.value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      )),
      title: Text(
        assistantLogic.deviceInfo["deviceId"],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
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
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: () {
              _showDisconnectDialog();
            },
            icon: const Icon(Icons.bluetooth_disabled, color: Colors.white, size: 16),
            label: const AutoSizeText(
              "断开连接",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                  color: AppColors.shadowColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(Get.context!).copyWith(
                dividerColor: Colors.transparent,
                listTileTheme: const ListTileThemeData(
                  iconColor: AppColors.primaryColor,
                  textColor: AppColors.textColor,
                ),
                unselectedWidgetColor: AppColors.primaryColor,
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.primaryColor,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoiseReductionCard() {
    return _buildGlassCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Obx(() => ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.tune, color: AppColors.primaryColor, size: 20),
        ),
        title: const Text(
          '降噪控制',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
            letterSpacing: 1,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '降噪强度',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        '${assistantLogic.noiseReductionLevel.value.toInt()} dB',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(Get.context!).copyWith(
                    activeTrackColor: AppColors.primaryColor,
                    inactiveTrackColor: AppColors.primaryColor.withOpacity(0.3),
                    thumbColor: AppColors.primaryColor,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: assistantLogic.noiseReductionLevel.value,
                    min: -200.0,
                    max: 0.0,
                    divisions: 200,
                    onChangeEnd: (value) async {
                      assistantLogic.initDnr();
                    },
                    onChanged: (value) async {
                      assistantLogic.noiseReductionLevel.value = value;
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      )),
    );
  }

  Widget _buildFileStatusCard() {
    return _buildGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondaryColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.file_copy, color: AppColors.secondaryColor, size: 20),
        ),
        title: const Text(
          '文件状态',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
            letterSpacing: 1,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusItem(
                  "当前文件",
                  assistantLogic.currentFileName.value,
                  Icons.description,
                  AppColors.primaryColor,
                ),
                const SizedBox(height: 8),
                _buildProgressItem(
                  "读取进度",
                  assistantLogic.fileListContent.length,
                  assistantLogic.currentFileSize.value,
                  AppColors.primaryColor,
                ),
                const SizedBox(height: 16),
                _buildStatusItem(
                  "OTA文件",
                  assistantLogic.otaFileName.value,
                  Icons.system_update,
                  AppColors.secondaryColor,
                ),
                const SizedBox(height: 8),
                _buildProgressItem(
                  "升级进度",
                  assistantLogic.otaAlready.value,
                  assistantLogic.otaFileSize.value,
                  AppColors.secondaryColor,
                ),
              ],
            )),
          )
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor.withOpacity(0.8)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '无' : value,
            style: const TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w500,
              color: AppColors.textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 文件读取进度区域 - 独立组件，避免频繁重建影响其他UI
  Widget _buildFileReadProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 速率显示 - 仅速率变化时重建这一行
        Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "BLE速率:${assistantLogic.dataRate.value}\n"
                  "TCP速率:${assistantLogic.tcpDataRate.value}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        )),
        const SizedBox(height: 4),
        // 读取进度条 - 仅进度数据变化时重建（使用displayProgress避免频繁重建）
        Obx(() {
          final current = assistantLogic.displayProgress.value;
          final total = assistantLogic.currentFileSize.value;
          final progress = total > 0 ? current / total : 0.0;
          final percentage = (progress * 100).toStringAsFixed(1);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "读取进度",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.blue.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 4),
              Text(
                '$current / $total',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildProgressItem(String label, int current, int total, Color color) {
    final progress = total > 0 ? current / total : 0.0;
    final percentage = (progress * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
                shadows: [
                  Shadow(color: color.withOpacity(0.5), blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$current / $total',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLogSection() {
    return _buildGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bug_report, color: AppColors.accentColor, size: 20),
        ),
        title: const Text(
          "系统日志",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
            letterSpacing: 1,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => assistantLogic.clearLog(),
              icon: const Icon(Icons.clear_all, size: 20, color: AppColors.textSecondary),
              tooltip: "清空日志",
            ),
            const Icon(Icons.expand_more, color: AppColors.textSecondary),
          ],
        ),
        children: [
          Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            height: 250,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Theme(
              data: ThemeData.dark(),
              child: const LoggerScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsSection() {
    return _buildGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.touch_app, color: AppColors.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  '功能操作',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final buttonCount = assistantLogic.actionBtnList.length;
    final rowCount = (buttonCount / 2).ceil();
    final gridHeight = rowCount * 50 + (rowCount - 1) * 12.0; 

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: buttonCount,
        itemBuilder: (context, index) {
          return _buildButton(
            assistantLogic.actionBtnList[index]["text"],
            assistantLogic.actionBtnList[index]["press"],
          );
        },
      ),
    );
  }

  Widget _buildButton(String text, Function onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.05),
        foregroundColor: AppColors.primaryColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.primaryColor.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      onPressed: () => onPressed(),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showDisconnectDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.cardColor,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.errorColor.withOpacity(0.5)),
                    ),
                    child: const Icon(
                      Icons.bluetooth_disabled,
                      size: 32,
                      color: AppColors.errorColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '断开设备连接',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '确定要断开与设备的连接吗？\n断开后需要重新配对才能使用。',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                          ),
                          child: const Text(
                            '取消',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            _performDisconnect();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.errorColor.withOpacity(0.8),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '断开连接',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _performDisconnect() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryColor),
                  SizedBox(height: 16),
                  Text(
                    '正在断开连接...',
                    style: TextStyle(fontSize: 16, color: AppColors.textColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      deviceConnectLogic.disconnectDevice(assistantLogic.deviceInfo["deviceId"]);
      Future.delayed(const Duration(milliseconds: 1000), () {
        Get.back();
        Get.offAllNamed("/home");
        Get.snackbar(
          '断开成功',
          '设备连接已断开',
          icon: const Icon(Icons.check_circle, color: Colors.white),
          backgroundColor: AppColors.successColor.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      });
    } catch (e) {
      Get.back();
      Get.snackbar(
        '断开失败',
        '设备断开连接时出现错误',
        icon: const Icon(Icons.error, color: Colors.white),
        backgroundColor: AppColors.errorColor.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }
}