import 'dart:ui';
import 'package:Recording_pen/theme/app_colors.dart';
import 'package:Recording_pen/view/assistant/assistant_logic.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../wiget/alert_button.dart';

class FileListPage extends StatelessWidget {
  FileListPage({super.key});

  final assistantLogic = Get.find<AssistantLogic>();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent, // 背景由父组件控制 (如 AuroraBackground)
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Obx(() {
          if (assistantLogic.fileList.isEmpty) {
            return const Center(
              child: Text(
                "暂无文件记录",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: assistantLogic.fileList.length,
            itemBuilder: (context, index) {
              final fileItem = assistantLogic.fileList[index];
              final fileName = fileItem["fileName"] as String? ?? "未知文件";
              final fileSize = fileItem["fileSize"] ?? 0;
              final fileIndexLabel = "${(index + 1) + (assistantLogic.filePageSize.value) * (assistantLogic.filePageNum.value - 1)}";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowColor.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                          ),
                          child: const Icon(
                            Icons.description,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColor,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "大小: ${formatFileSize(fileSize)}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "#$fileIndexLabel",
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          _showReadDialog(fileName, fileSize);
                        },
                        onLongPress: () {
                          _showDeleteDialog(fileName);
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  void _showDeleteDialog(String fileName) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.errorColor, size: 40),
                  const SizedBox(height: 16),
                  const Text(
                    "删除文件",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "确定要删除文件 [$fileName] 吗？操作不可恢复。",
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text("取消", style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorColor.withOpacity(0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          assistantLogic.removeAudioFile(fileName);
                          Get.back();
                        },
                        child: const Text("确定删除", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReadDialog(String fileName, num fileSize) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.file_download_outlined, color: AppColors.primaryColor, size: 40),
                  const SizedBox(height: 16),
                  const Text(
                    "读取文件",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "确定要读取文件 [$fileName] 的内容吗？",
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text("取消", style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor.withOpacity(0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Get.back();
                          assistantLogic.readAudioFileContent(fileName, fileSize.toInt());
                        },
                        child: const Text("确定读取", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String formatFileSize(num size) {
  if (size < 1024) {
    return "$size b";
  } else if (size < 1024 * 1024) {
    return "${(size / 1024).toStringAsFixed(2)} KB";
  } else if (size < 1024 * 1024 * 1024) {
    return "${(size / (1024 * 1024)).toStringAsFixed(2)} MB";
  } else {
    return "${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }
}
