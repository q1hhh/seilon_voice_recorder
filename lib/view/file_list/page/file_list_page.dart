import 'package:Recording_pen/view/assistant/assistant_logic.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../wiget/alert_button.dart';

class FileListPage extends StatelessWidget {
  FileListPage({super.key});

  var assistantLogic = Get.find<AssistantLogic>();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: SingleChildScrollView(
        child: Obx(() => Column(
          children: List.generate(assistantLogic.fileList.length, (fileIndex) {
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              width: double.infinity,
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.blueAccent),
                  const SizedBox(width: 3),
                  Expanded(
                    child: GestureDetector(
                      // 长按删除文件
                      onLongPress: () {
                        print("长按删除文件-->${assistantLogic.fileList[fileIndex]["fileName"]}");
                        Get.defaultDialog(
                          title: "删除文件",
                          titleStyle: const TextStyle(fontSize: 18),
                          middleText: "确定要删除[${assistantLogic.fileList[fileIndex]["fileName"]}]这个文件吗？",
                          actions: [
                            AlertButton(
                              confirmCallback: () {
                                assistantLogic.removeAudioFile(assistantLogic.fileList[fileIndex]["fileName"] as String?);
                                Get.back();
                              },
                              cancelCallback: () {
                                Get.back();
                              },
                            )
                          ]
                        );
                      },
                      // 点击读取文件内容
                      onTap: () {
                        Get.defaultDialog(
                          title: "读取文件",
                          titleStyle: const TextStyle(fontSize: 18),
                          middleText: "确定要读取[${assistantLogic.fileList[fileIndex]["fileName"]}]这个文件吗？",
                          actions: [
                            AlertButton(
                              confirmCallback: () {
                                assistantLogic.readAudioFileContent(
                                  assistantLogic.fileList[fileIndex]["fileName"],
                                  assistantLogic.fileList[fileIndex]["fileSize"]
                                );
                              },
                              cancelCallback: () {
                                Get.back();
                              },
                            )
                          ]
                        );
                      },
                      child: Text(
                        assistantLogic.fileList[fileIndex]["fileName"],
                        style: const TextStyle(fontSize: 15, color: Colors.blueAccent, overflow: TextOverflow.ellipsis),
                      ),
                    )
                  ),
                  const SizedBox(width: 3),
                  GestureDetector(
                    onTap: () {},
                    child: Text("${(assistantLogic.fileList[fileIndex]["fileSize"] / 1000).toStringAsFixed(2)}k", style: TextStyle(fontSize: 12),),
                  ),
                  const SizedBox(width: 3),
                ],
              ),
            );
          }),
        ))
      ),
    );
  }
}

