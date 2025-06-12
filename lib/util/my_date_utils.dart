import 'dart:typed_data';

import 'package:get/get.dart';

class MyDateUtils {
  static Uint8List getHexadecimalTime(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    var dateList = Uint8List(6);

    dateList[0] = int.parse((dateTime.year % 100).toString().padLeft(2, '0'));
    dateList[1] = int.parse(dateTime.month.toString().padLeft(2, '0'));
    dateList[2] = int.parse(dateTime.day.toString().padLeft(2, '0'));
    dateList[3] = int.parse(dateTime.hour.toString().padLeft(2, '0'));
    dateList[4] = int.parse(dateTime.minute.toString().padLeft(2, '0'));
    dateList[5] = int.parse(dateTime.second.toString().padLeft(2, '0'));
    return dateList;
  }

  static bool isToday(int timestamp) {
    DateTime now = DateTime.now();
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp); // 将时间戳转换为DateTime对象

    // 判断是否是今天
    if (now.year == date.year && now.month == date.month && now.day == date.day) {
      return true;
    }

    return false;
  }

  static bool isTYesterday(int timestamp) {
    DateTime now = DateTime.now();
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp); // 将时间戳转换为DateTime对象

    // 判断是否是昨天
    DateTime yesterday = now.subtract(Duration(days: 1));
    if (yesterday.year == date.year && yesterday.month == date.month && yesterday.day == date.day) {
      return true;
    }

    return false;
  }

  static String formatTimestampToMonthDay(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp); // 将时间戳转换为DateTime对象
    String month = date.day.toString();
    String day = date.day.toString();
    return '${month.tr} ${day}th';
  }

  static String convertLockMessageListTime(int timestamp) {
    DateTime now = DateTime.now();
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp); // 将时间戳转换为DateTime对象

    // 判断是否是今天
    if (now.year == date.year && now.month == date.month && now.day == date.day) {
      return '今天';//'today'.tr;
    }

    // 判断是否是昨天
    DateTime yesterday = now.subtract(Duration(days: 1));
    if (yesterday.year == date.year && yesterday.month == date.month && yesterday.day == date.day) {
      return '昨天';//'yesterday'.tr;
    }

    String month = date.month.toString();
    String day = date.day.toString();
    // return '${'${month}month'.tr} ${day}th';
    return '${'${month}月'} ${day}th';
  }

  static List<DateTime> getDatesInMonth(int year, int month) {
    // 获取下个月的第一天，然后减去一天以得到指定月份的最后一天
    final lastDayOfMonth = (month < 12)
        ? DateTime(year, month + 1, 1).subtract(Duration(days: 1))
        : DateTime(year + 1, 1, 1).subtract(Duration(days: 1));

    // 创建一个日期列表
    List<DateTime> days = [];

    // 使用循环生成每一天的日期，并添加到列表中
    for (int i = 0; i < lastDayOfMonth.day; i++) {
      days.add(DateTime(year, month, i + 1));
    }

    return days;
  }

}