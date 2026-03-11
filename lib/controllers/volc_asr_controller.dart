import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:Recording_pen/util/view_log_util.dart';

class VolcAsrController extends GetxController {
  WebSocket? _ws;
  bool _ready = false;
  bool _connecting = false;
  final Queue<Uint8List> _pendingFrames = Queue<Uint8List>();
  String? _url; // 火山引擎 ASR WebSocket 地址（含必要 query）
  Map<String, String>? _headers; // 鉴权 Header（如 Authorization 等）
  // 凭据（不硬编码，外部注入）
  String? appId;
  String? token;
  String? accessKey;

  // 结果回调（双向流式模式）
  void Function(String message)? onPartialResult;
  void Function(String message)? onFinalResult;
  void Function(dynamic error)? onError;

  // 可选：会话状态
  final RxBool sessionStarted = false.obs;

  void configure({required String url, Map<String, String>? headers}) {
    _url = url;
    _headers = headers;
  }

  void setCredentials(
      {required String appId, required String token, String? key}) {
    this.appId = appId;
    this.token = token;
    this.accessKey = key;
  }

  Future<void> _ensureConnection() async {
    if (_ready || _connecting) return;
    if (_url == null || _url!.isEmpty) {
      ViewLogUtil.error("未配置ASR WebSocket URL，请调用 VolcAsrController.configure");
      return;
    }
    _connecting = true;
    try {
      // 合并鉴权头：优先使用外部 headers，其次注入 Authorization/X-Appid
      final Map<String, String> headersToUse = {};
      if (_headers != null) {
        headersToUse.addAll(_headers!);
      }
      if (token != null && (headersToUse["Authorization"] == null)) {
        headersToUse["Authorization"] = "Bearer $token";
      }
      if (appId != null && (headersToUse["X-Appid"] == null)) {
        headersToUse["X-Appid"] = appId!;
      }
      _ws = await WebSocket.connect(_url!, headers: headersToUse);
      _ready = true;
      _connecting = false;

      _ws!.listen((msg) {
        if (msg is String) {
          // 文本消息：尝试解析为JSON，区分中间/最终结果
          try {
            final data = jsonDecode(msg);
            final type = data["type"] ?? data["result_type"];
            final text = data["text"] ?? data["result"] ?? msg;
            if (type == "interim" || type == "partial") {
              onPartialResult?.call(text);
            } else if (type == "final" || type == "result") {
              onFinalResult?.call(text);
            } else {
              // 未标注类型，作为普通信息
              ViewLogUtil.info("ASR消息: $msg");
              onPartialResult?.call(text);
            }
          } catch (_) {
            // 非JSON或解析失败，直接回调
            ViewLogUtil.info("ASR消息(非JSON): $msg");
            onPartialResult?.call(msg);
          }
        } else if (msg is Uint8List) {
          // 二进制返回：视实际协议处理
          ViewLogUtil.info("ASR返回二进制长度: ${msg.length}");
        }
      }, onError: (e) {
        ViewLogUtil.error("ASR WebSocket错误: $e");
        onError?.call(e);
        _ready = false;
      }, onDone: () {
        ViewLogUtil.warn("ASR WebSocket关闭");
        _ready = false;
      });

      // 连接成功后发送缓存帧
      while (_pendingFrames.isNotEmpty && _ready) {
        final frame = _pendingFrames.removeFirst();
        _ws!.add(frame);
      }
    } catch (e) {
      _connecting = false;
      ViewLogUtil.error("连接ASR失败: $e");
    }
  }

  // 会话开始（如需发送特定开始包，请在此实现）
  Future<void> startSession() async {
    await _ensureConnection();
    if (_ws == null) {
      ViewLogUtil.error("ASR连接未就绪，无法发送开始帧");
      return;
    }
    // 发送开始控制帧（文本JSON），按照需求：channels=2，language=中文（zh），返回中间结果
    final startMsg = {
      "type": "start",
      "audio_format": {"codec": "opus", "sample_rate": 16000, "channels": 2},
      "language": "zh",
      "enable_interim_result": true,
      // 双向流式模式标记（若火山文档有官方字段名，请替换为对应字段）
      "stream_mode": "duplex"
    };
    // 注入会话鉴权/标识（按需）
    if (appId != null) {
      startMsg["app_id"] = appId!;
    }
    // 若 v2 要求在开始帧携带 token，可开启以下注入
    if (token != null) {
      startMsg["token"] = token!;
    }
    try {
      _ws!.add(jsonEncode(startMsg));
      sessionStarted.value = true;
    } catch (e) {
      ViewLogUtil.error("发送开始帧失败: $e");
    }
  }

  // 会话结束（如需发送结束包，请在此实现）
  Future<void> finishSession() async {
    // 发送结束控制帧（文本JSON），在双向流式模式下不立即关闭连接，等待服务端返回最终结果
    try {
      if (_ws != null) {
        final finishMsg = {"type": "finish"};
        _ws!.add(jsonEncode(finishMsg));
      }
    } catch (e) {
      ViewLogUtil.error("发送结束帧失败: $e");
    } finally {
      sessionStarted.value = false;
      // 如需立即断开，请调用 close()；默认保持连接由业务决定何时关闭
    }
  }

  // 发送 Opus 二进制帧
  Future<void> sendOpusFrame(Uint8List opusData) async {
    if (!_ready) {
      _pendingFrames.add(opusData);
      await _ensureConnection();
      return;
    }
    try {
      // 若协议需要额外封装（添加头/标识/序号），请在此处构造后再发送
      _ws!.add(opusData);
    } catch (e) {
      ViewLogUtil.error("发送失败，缓存重试: $e");
      _ready = false;
      _pendingFrames.add(opusData);
      await _ensureConnection();
    }
  }

  Future<void> close() async {
    try {
      await _ws?.close();
    } catch (_) {}
    _ready = false;
    _connecting = false;
  }

  @override
  void onClose() {
    close();
    super.onClose();
  }
}
