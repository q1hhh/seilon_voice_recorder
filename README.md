# Seilon Voice Recorder (Recording Pen Demo)

A modern, high-performance Flutter-based application for interacting with smart voice recording devices via Bluetooth Low Energy (BLE). Featuring a stunning **Aurora UI** with glassmorphism aesthetics.

---

## 🌍 Language / 语言
- [English](#english-documentation)
- [中文文档](#中文文档)

---

## English Documentation

### 1. Overview
This project provides a comprehensive solution for managing BLE-connected recording pens. It handles device discovery, secure handshake authentication, real-time data streaming, and advanced audio processing (Opus to PCM decoding).

### 2. Core Logic & Features
- **Aurora UI Design**: A cutting-edge visual experience using deep dark backgrounds, neon gradients, and glassmorphism (translucent blur effects).
- **BLE Management**: 
  - **Discovery**: Filters devices by Service ID (`0f417647-9d55-6d98-ca43-cdd098d726e1`).
  - **Authentication**: Secure handshake involving a 6-digit random code + UUID + Account code written to characteristic `0000A001-0000-1000-8000-00805F9B34FB`.
- **Audio Processing**: 
  - **Opus Decoding**: High-efficiency decoding of Opus audio streams into raw PCM data using the `opus_dart` library.
  - **Waveform Rendering**: Real-time visualization of audio data.
- **Device Control**: Remote DNR (Digital Noise Reduction) level adjustment, file management (listing, reading, deleting), and OTA firmware updates.

### 3. Requirements
- Flutter 3.x+
- Dart 2.17+
- Physical Android/iOS device (BLE is not supported on most emulators).

### 4. Getting Started
1. **Clone & Install**:
   ```bash
   git clone <repository-url>
   flutter pub get
   ```
2. **Run**:
   ```bash
   flutter run
   ```

---

## 中文文档

### 1. 项目简介
本项目是一个基于 Flutter 开发的现代化智能录音笔管理应用。它通过低功耗蓝牙 (BLE) 与硬件设备连接，实现了从设备发现、安全认证到实时音频流处理及文件管理的全套逻辑。

### 2. 核心逻辑与功能
- **极光 (Aurora) UI 设计**: 采用前沿的视觉风格，结合深色背景、霓虹渐变以及毛玻璃（高斯模糊）效果，提供沉浸式的操作体验。
- **蓝牙 (BLE) 逻辑**:
  - **设备过滤**: 自动通过特定的 Service ID (`0f417647-9d55-6d98-ca43-cdd098d726e1`) 筛选目标录音笔。
  - **握手认证**: 应用端生成 6 位随机验证码 + UUID + 账户代码，写入特征值 `0000A001-0000-1000-8000-00805F9B34FB` 完成安全握手，后续所有指令均基于此安全通道。
- **音频处理能力**:
  - **Opus 解码**: 集成 `opus_dart` 库，可高效地将录音笔生成的 Opus 压缩格式实时解码为 PCM 原始音频数据。
  - **波形展示**: 实时渲染音频 PCM 数据的波形图。
- **设备交互控制**:
  - **降噪控制**: 支持远程调节设备的数字降噪 (DNR) 强度（-200dB 至 0dB）。
  - **文件管理**: 支持远程读取设备文件列表、下载文件内容以及删除设备上的录音。
  - **OTA 升级**: 集成了固件在线升级功能。

### 3. 环境要求
- Flutter 3.x 及以上版本
- Dart 2.17 及以上版本
- 建议使用 Android Studio 或 VSCode 开发
- **注意**: 必须使用支持蓝牙的真机进行调试。

### 4. 目录结构
- `lib/ble/`: 蓝牙协议、指令封装及消息分发逻辑。
- `lib/protocol/`: 自定义通信协议包封装与 AES 加密处理。
- `lib/view/`: UI 页面（首页、搜索页、助手控制页等）。
- `lib/theme/`: Aurora 极光主题配色定义。
- `lib/util/`: 音频解码 (Opus)、CRC校验、字节处理等工具类。
- `plugins/`: 包含 Realtek DFU 升级和自研 DNR 插件。

---
