import 'package:Recording_pen/controllers/home_control.dart';
import 'package:Recording_pen/theme/app_colors.dart';
import 'package:Recording_pen/util/log_util.dart';
import 'package:Recording_pen/view/assistant/assistant_logic.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../controllers/deviceConnect.dart';
import '../../../util/view_log_util.dart';

class AssistantPage extends StatelessWidget {
  AssistantPage({super.key});

  var assistantLogic = Get.find<AssistantLogic>();
  var deviceConnectLogic = DeviceConnectLogic();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () {
              deviceConnectLogic.disconnectDevice(assistantLogic.deviceInfo["deviceId"]);
              Get.offAllNamed("/home");
            }, 
            child: AutoSizeText("断开连接", style: TextStyle(color: Colors.white, fontSize: 15),)
          )
        ],
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
          "助手",
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
        child: Column(
          children: [
            // 日志区域
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(16),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "日志",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: LoggerScreen(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 按钮区域
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SingleChildScrollView(
                  child: Obx(() {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Text("读取的文件: ${assistantLogic.currentFileName.value}"),
                          SizedBox(
                            child: Text(
                              "读取文件的大小：(${assistantLogic.fileListContent.length}/${assistantLogic.currentFileSize.value})", style: TextStyle(color: Colors.deepPurpleAccent),
                            ),
                          ),
                          Text("OTA升级文件: ${assistantLogic.otaFileName.value}"),
                          SizedBox(
                            child: Text(
                              "OTA升级已发送：(${assistantLogic.otaAlready.value}/${assistantLogic.otaFileSize.value})", style: TextStyle(color: Colors.deepPurpleAccent),
                            ),
                          ),
                          _buildActionButtons(),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 功能按钮区
  Widget _buildActionButtons() {
    return SingleChildScrollView(
      child: Wrap(
        direction: Axis.horizontal,
        spacing: 8,
        runSpacing: 12,
        children: List.generate(assistantLogic.actionBtnList.length, (index) {
          return _buildButton(
            assistantLogic.actionBtnList[index]["text"],
            assistantLogic.actionBtnList[index]["press"],
          );
        }),
      ),
    );
  }

  Widget _buildButton(String text, Function onPressed) {
    return Container(
      height: 36,
      margin: const EdgeInsets.only(right: 8),
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
        onPressed: () => onPressed(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
