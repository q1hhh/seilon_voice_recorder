class DeviceUser {
  late int userId;
  late int userType;
  late int enable;
  late int userAttribute;
  late int userDateInfo;
  late int startTime;
  late int endTime;
  var password;

  @override
  String toString() {
    return 'DeviceUser{userId: $userId, userType: $userType, enable: $enable, userAttribute: $userAttribute, userDateInfo: $userDateInfo, startTime: $startTime, endTime: $endTime, password: $password}';
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['userId'] = userId;
    map['userType'] = userType;
    map['enable'] = enable;
    map['userAttribute'] = userAttribute;
    map['userDateInfo'] = userDateInfo;
    map['startTime'] = startTime;
    map['endTime'] = endTime;
    map['password'] = password;
    return map;
  }
}