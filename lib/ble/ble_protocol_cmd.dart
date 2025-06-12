// Message types definition
const int MSG_TYPE_HANDSHAKE = 0x01; // 握⼿认证
const int MSG_TYPE_RUNNING_STATUS = 0x02; // 运⾏状态
const int MSG_TYPE_BATTERY_LEVEL = 0x03; // 电池电量
const int MSG_TYPE_VIBRATION_STRENGTH = 0x04; // 震动强度
const int MSG_TYPE_DEVICE_INFO = 0x05; // 设备信息
const int MSG_TYPE_CONTROL_CMD = 0x06; // 控制指令
const int MSG_TYPE_CONTROL_FEEDBACK = 0x07; // 控制反馈
const int MSG_TYPE_SENSOR_DATA = 0x08; // 传感器数据(此处特指毫⽶波雷达，包含实时数据/离线数据)

const int MSG_TYPE_VIBRATION_RECORD = 0x09; // 震动记录
const int MSG_TYPE_AUDIO_FILE = 0x10; // 录⾳⽂件（包含实时录⾳/离线录⾳）
const int MSG_TYPE_RECORDING_STATUS = 0x11; // 录⾳开关状态
const int MSG_TYPE_RADAR_STATUS = 0x13; //毫⽶波雷达开关状态
// 设备⼯作状态定义
const int PIE_WORKING_STATUS_IDLE = 0x00; // 空闲状态
const int PIE_WORKING_STATUS_VIBRATING = 0x01; // 震动中
const int PIE_WORKING_STATUS_SLEEPING = 0x02; // 休眠状态
const int PIE_WORKING_STATUS_CHARGING = 0x03; // 充电中
const int PIE_WORKING_STATUS_UPGRADING = 0x04; // 升级中
const int PIE_WORKING_STATUS_PAUSED = 0x05; // 震动暂停状态 PIE_WORKING_STATUS_ERROR = 0xFF; // 错误状态
// 录⾳开关状态定义
const int RECORDING_STATUS_OFF = 0x00; // 录⾳关闭
const int RECORDING_STATUS_ON = 0x01; // 录⾳开启