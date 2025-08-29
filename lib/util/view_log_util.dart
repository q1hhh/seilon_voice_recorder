import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

class ViewLogUtil {

  static final RxList logs = [].obs;

  static void debug(String? log) {
    logger.d('${DateTime.now()}:$log');
    logs.add(SelectableText('${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}:\n$log', style: TextStyle(color: Colors.black87, fontSize: 12),));
  }

  static void info(String? log) {
    logger.i('${DateTime.now()}:$log');
    logs.add(SelectableText('${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}:\n$log', style: TextStyle(color: Colors.blue, fontSize: 12),));
  }

  static void error(String? log) {
    logger.e('${DateTime.now()}:$log');
    logs.add(SelectableText('${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}:\n$log', style: TextStyle(color: Colors.redAccent, fontSize: 12),));
  }

  static void warn(String? log) {
    logger.w('${DateTime.now()}:$log');
    logs.add(SelectableText('${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}:\n$log', style: TextStyle(color: Colors.yellow, fontSize: 12),));
  }

  static void clear() {
    logs.clear();
  }

  static int length() {
    return logs.length;
  }
}

class MyFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}

class LoggerScreen extends StatefulWidget {
  const LoggerScreen({super.key});

  @override
  State<LoggerScreen> createState() => _LoggerScreenState();
}

class _LoggerScreenState extends State<LoggerScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAutoScroll = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && _isAutoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // 日志控制栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.terminal,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '系统日志',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${ViewLogUtil.length()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    )),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 自动滚动开关
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isAutoScroll = !_isAutoScroll;
                        });
                        if (_isAutoScroll) {
                          _scrollToBottom();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 滚动到底部按钮
                    InkWell(
                      onTap: () {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 日志内容区域
          Expanded(
            child: Obx(() {
              // 触发自动滚动
              _scrollToBottom();

              if (ViewLogUtil.logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '暂无日志',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: ViewLogUtil.logs.length,
                itemBuilder: (context, index) {
                  final logItem = ViewLogUtil.logs[index];
                  return _buildLogItem(logItem, index);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(Widget logWidget, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 序号
          Container(
            width: 30,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // 时间戳（如果需要的话）
          // Container(
          //   width: 60,
          //   child: Text(
          //     _formatTime(DateTime.now()),
          //     style: TextStyle(
          //       fontSize: 10,
          //       color: Colors.grey.shade600,
          //       fontFamily: 'monospace',
          //     ),
          //   ),
          // ),
          // 日志内容
          Expanded(
            child: DefaultTextStyle(
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontFamily: 'monospace',
                height: 1.2,
              ),
              child: logWidget,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}


