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

  static final RxList _logs = [].obs;

  static void debug(String? log) {
    logger.d('${DateTime.now()}:$log');
    _logs.add(SelectableText('${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}:\n$log', style: TextStyle(color: Colors.black87, fontSize: 12),));
  }

  static void info(String? log) {
    logger.i('${DateTime.now()}:$log');
    _logs.add(SelectableText('${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}:\n$log', style: TextStyle(color: Colors.blue, fontSize: 12),));
  }

  static void error(String? log) {
    logger.e('${DateTime.now()}:$log');
    _logs.add(SelectableText('${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}:\n$log', style: TextStyle(color: Colors.redAccent, fontSize: 12),));
  }

  static void warn(String? log) {
    logger.w('${DateTime.now()}:$log');
    _logs.add(SelectableText('${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}:\n$log', style: TextStyle(color: Colors.yellow, fontSize: 12),));
  }

  static void clear() {
    _logs.clear();
  }
}

class MyFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}

class LoggerScreen extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();

  LoggerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: <Widget>[
          Expanded(
            child: Obx(() {
              // 每次有日志更新时，自动滚动到列表底部
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });

              return ListView.builder(
                controller: _scrollController,
                itemCount: ViewLogUtil._logs.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ViewLogUtil._logs[index],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}


