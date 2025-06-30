class LockControlCmd {

  static const CATEGORY_SYSTEM    = 0x01;
  static const CATEGORY_NET_WORK  = 0x02;
  static const CATEGORY_RECORDER  = 0x12;

  //0x01系统类型======================================================================================
  static const CMD_SYSTEM_QUERY_DEVICE_INFO       = 0x01;//查询设备信息
  static const CMD_SYSTEM_RESET                   = 0x02;//恢复出厂设置
  static const CMD_SYSTEM_SET_TIME_TIMEZONE       = 0x03;//设置门锁时间
  static const CMD_SPECIAL_REQUEST_UPGRADE        = 0x05;//进入升级
  static const CMD_SPECIAL_SEND_UPGRADE_DATA      = 0x06;//发送升级包
  static const CMD_SYSTEM_CLEAR_DATA              = 0x07;//清除所有数据

  //0x02配网类型==================================================================

  static const CMD_SYSTEM_BIND_DEVICE     = 0x07;//绑定设备
  static const CMD_SYSTEM_VERIFY_USER     = 0x08;//验证身份
  static const CMD_SYSTEM_COMPLETE_NET_WORK = 0x10;//完成配网


  //0x12录音笔===================================================================

  static const CMD_RECORDER_DEVICE_INFO           = 0x01;//录音笔设备信息
  static const CMD_RECORDER_SET_BLE_NAME          = 0x02;//设置蓝牙名称
  static const CMD_RECORDER_SET_RECORD_INFO       = 0x03;//录音参数设置
  static const CMD_RECORDER_OPEN_U_DISK           = 0x04;//打开U盘
  static const CMD_RECORDER_SCREEN_CONTROL        = 0x05;//屏幕控制
  static const CMD_RECORDER_CONTROL_SOUND_RECORD  = 0x06;//开启或关闭录音
  static const CMD_RECORDER_OPEN_WIFI             = 0x07;//打开WI-FI
  static const CMD_RECORDER_QUERY_TCP_SERVICE     = 0x08;//查询TCP服务IP和端口
  static const CMD_RECORDER_BATTERY_REPORT        = 0x10;//电量上报
  static const CMD_RECORDER_RECORDING_REPORT      = 0x12;//录音上报
  static const CMD_RECORDER_CONTROL_KEYS          = 0x13;//拨码开关上报
  static const CMD_RECORDER_TIMEOUT_RECORDING_PROMPT= 0x14;//忘记录音提示上报

  static const CMD_RECORDER_REAL_TIME_STREAMING   = 0x20;//实时流语音上传
  static const CMD_RECORDER_AUDIO_FILE_COUNT  = 0x21;//音频文件列表数量读取
  static const CMD_RECORDER_AUDIO_FILE_LIST   = 0x22;//音频文件列表读取
}