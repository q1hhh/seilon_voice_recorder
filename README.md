# 录音笔 demo

本项目使用的是 Flutter 语言进行开发。

---

### 1. 环境要求
- Flutter 3.x 及以上
- Dart 2.17 及以上
- 推荐使用 Android Studio 或 VSCode 作为开发工具
- 需具备 Android 或 iOS 设备进行真机调试

### 2. 安装与运行
1. 克隆本仓库：
   ```bash
   git clone <本项目地址>
   cd <项目目录>
   ```
2. 安装依赖：
   ```bash
   flutter pub get
   ```
3. 运行项目：
   ```bash
   flutter run
   ```

### 3. 主要功能
- 蓝牙搜索与过滤设备
- 设备连接与认证
- 录音文件（Opus格式）解码为PCM
- 设备管理与展示

### 4. 蓝牙搜索过滤
- 通过 ServiceId 过滤目标设备：
  ```
  0f417647-9d55-6d98-ca43-cdd098d726e1
  ```

### 5. 握手认证
- 应用端生成一个随机 6 位验证码 + UUID + 账户代码，通过如下特征值写入到设备端：
  ```
  0000A001-0000-1000-8000-00805F9B34FB
  ```
- 蓝牙连接成功后，所有数据传输均需通过该特征值。

### 6. Opus 文件解码为 PCM
- 项目内集成了 `opus_dart` ，可将 Opus 格式音频解码为 PCM。
- 使用方法：
  1. 点击主界面右下角按钮，选择 Opus 文件。
  2. 程序会自动解码并保存为 `output.pcm` 文件。
  3. 相关代码位于 `lib/view/home.dart` 的 `floatingActionButton` 事件中。

### 7. 常见问题
- **Q: 运行时报找不到依赖？**
  - A: 请先执行 `flutter pub get`。
- **Q: 蓝牙无法搜索到设备？**
  - A: 请确认设备已开启并靠近手机，且 ServiceId 设置正确。
- **Q: Opus 文件解码失败？**
  - A: 请确认文件格式正确，或查看日志获取详细错误信息。

### 8. 目录结构说明
- `lib/` 主要源码目录
- `lib/view/` 页面相关代码
- `lib/theme/` 主题与样式
- `README..md` 中文说明文档

---
