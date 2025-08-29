import 'package:flutter/material.dart';
import 'dart:math' as math;

class UpgradeDialog extends StatefulWidget {
  final double progress; // 进度值 0.0 - 1.0
  final String statusText; // 主要状态文字
  final String detailText; // 详细描述文字
  final bool isComplete; // 是否完成
  final bool canClose; // 是否可以关闭
  final VoidCallback? onClose; // 关闭回调
  final Color? primaryColor; // 主色调
  final Color? backgroundColor; // 背景颜色

  const UpgradeDialog({
    super.key,
    required this.progress,
    required this.statusText,
    this.detailText = "",
    this.isComplete = false,
    this.canClose = true,
    this.onClose,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  _UpgradeDialogState createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends State<UpgradeDialog>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    // 只有在升级中才启动动画
    if (!widget.isComplete) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(UpgradeDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 根据完成状态控制动画
    if (widget.isComplete && !oldWidget.isComplete) {
      _rotationController.stop();
      _pulseController.stop();
      _shimmerController.stop();
    } else if (!widget.isComplete && oldWidget.isComplete) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Color get _primaryColor => widget.primaryColor ?? Colors.cyan;
  Color get _backgroundColor => widget.backgroundColor ?? Color(0xFF1a1a2e);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => widget.canClose,
      child: Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundColor,
                  _backgroundColor.withBlue((_backgroundColor.blue * 1.2).clamp(0, 255).round()),
                  _backgroundColor.withBlue((_backgroundColor.blue * 1.5).clamp(0, 255).round()),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // 粒子背景效果
                  if (!widget.isComplete)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: ParticlesPainter(_shimmerController),
                          );
                        },
                      ),
                    ),

                  // 主要内容
                  Container(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 顶部装饰线
                        Container(
                          height: 4,
                          width: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.isComplete
                                  ? [Colors.green, Colors.teal, Colors.green]
                                  : [_primaryColor, Colors.blue, Colors.purple],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: 24),

                        // 标题区域
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: widget.isComplete
                                        ? [Colors.green, Colors.teal]
                                        : [_primaryColor, Colors.blue],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  widget.isComplete ? Icons.check_circle : Icons.rocket_launch,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.isComplete ? "升级完成" : "系统升级",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 32),

                        // 中央进度区域
                        Container(
                          width: 120,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 外圆环动画
                              if (!widget.isComplete)
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 120 + (_pulseController.value * 20),
                                      height: 120 + (_pulseController.value * 20),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _primaryColor.withOpacity(0.3 - _pulseController.value * 0.3),
                                          width: 2,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              // 进度圆环
                              CustomPaint(
                                size: const Size(100, 100),
                                painter: CircularProgressPainter(
                                  progress: widget.progress,
                                  isComplete: widget.isComplete,
                                  primaryColor: _primaryColor,
                                ),
                              ),

                              // 中心图标
                              if (!widget.isComplete)
                                AnimatedBuilder(
                                  animation: _rotationController,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _rotationController.value * 2 * math.pi,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [_primaryColor, Colors.blue, Colors.purple],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.sync,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Colors.green, Colors.teal],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 进度百分比
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: widget.isComplete
                                ? [Colors.green, Colors.teal, Colors.green]
                                : [_primaryColor, Colors.blue, Colors.purple],
                          ).createShader(bounds),
                          child: Text(
                            "${(widget.progress).toInt()}%",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 状态文字
                        widget.isComplete
                            ? Text(
                          widget.statusText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        )
                            : ShimmerText(
                          text: widget.statusText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          controller: _shimmerController,
                        ),

                        if (widget.detailText.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            widget.detailText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 32),

                        // 关闭按钮
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: widget.canClose ? () {
                              if (widget.onClose != null) {
                                widget.onClose!();
                              } else {
                                Navigator.of(context).pop();
                              }
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: widget.canClose
                                    ? LinearGradient(
                                  colors: widget.isComplete
                                      ? [Colors.green, Colors.teal]
                                      : [_primaryColor, Colors.blue, Colors.purple],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                                    : LinearGradient(colors: [Colors.grey[600]!, Colors.grey[700]!]),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: widget.canClose ? [
                                  BoxShadow(
                                    color: (widget.isComplete ? Colors.green : _primaryColor).withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 0,
                                    offset: Offset(0, 5),
                                  ),
                                ] : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                widget.canClose
                                    ? (widget.isComplete ? "完成升级" : "取消升级")
                                    : "升级进行中...",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 自定义进度圆环画笔
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isComplete;
  final Color primaryColor;

  CircularProgressPainter({
    required this.progress,
    required this.isComplete,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // 背景圆环
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // 进度圆环
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: isComplete
            ? [Colors.green, Colors.teal, Colors.green]
            : [primaryColor, Colors.blue, Colors.purple, primaryColor],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // 进度端点光点
    if (progress > 0 && progress < 1) {
      final angle = -math.pi / 2 + sweepAngle;
      final dotX = center.dx + radius * math.cos(angle);
      final dotY = center.dy + radius * math.sin(angle);

      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dotX, dotY), 4, dotPaint);

      // 光晕效果
      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dotX, dotY), 8, glowPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// 闪烁动画文字组件
class ShimmerText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final AnimationController controller;

  ShimmerText({
    required this.text,
    required this.style,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white.withOpacity(0.5),
                Colors.white,
                Colors.cyan,
                Colors.white,
                Colors.white.withOpacity(0.5),
              ],
              stops: [
                0.0,
                0.3 + controller.value * 0.4,
                0.5 + controller.value * 0.4,
                0.7 + controller.value * 0.4,
                1.0,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds);
          },
          child: Text(
            text,
            style: style.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

// 粒子效果背景
class ParticlesPainter extends CustomPainter {
  final Animation<double> animation;

  ParticlesPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = (i * 37 + animation.value * 100) % size.width;
      final y = (i * 23 + animation.value * 50) % size.height;
      final radius = (1 + (i % 3)).toDouble();
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// 使用示例
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '静态升级弹窗',
      theme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _currentProgress = 0.0;
  String _currentStatus = "准备升级...";
  String _currentDetail = "正在初始化升级程序";
  bool _isComplete = false;
  bool _canClose = false;

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return UpgradeDialog(
              progress: _currentProgress,
              statusText: _currentStatus,
              detailText: _currentDetail,
              isComplete: _isComplete,
              canClose: _canClose,
              primaryColor: Colors.cyan,
              onClose: () {
                Navigator.of(context).pop();
                // 重置状态
                setState(() {
                  _currentProgress = 0.0;
                  _currentStatus = "准备升级...";
                  _currentDetail = "正在初始化升级程序";
                  _isComplete = false;
                  _canClose = false;
                });
              },
            );
          },
        );
      },
    );
  }

  void _simulateUpgrade() {
    // 这里演示如何更新弹窗状态
    _showUpgradeDialog();

    // 模拟升级过程（实际使用时删除这部分）
    _runSimulation();
  }

  void _runSimulation() async {
    List<Map<String, String>> steps = [
      {"status": "连接服务器", "detail": "正在验证更新权限"},
      {"status": "下载更新包", "detail": "获取最新版本数据"},
      {"status": "验证文件", "detail": "检查更新包完整性"},
      {"status": "准备安装", "detail": "备份当前配置"},
      {"status": "应用更新", "detail": "正在更新系统组件"},
      {"status": "优化系统", "detail": "清理缓存并优化性能"},
      {"status": "升级完成", "detail": "系统已成功更新到最新版本"}
    ];

    for (int i = 0; i <= 100; i += 2) {
      await Future.delayed(Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _currentProgress = i / 100;
          int stepIndex = (i / 100 * (steps.length - 1)).floor();
          _currentStatus = steps[stepIndex]["status"]!;
          _currentDetail = steps[stepIndex]["detail"]!;

          if (i >= 100) {
            _isComplete = true;
            _canClose = true;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0a0a0a),
      appBar: AppBar(
        title: Text('静态升级弹窗示例'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a0a0a),
              Color(0xFF1a1a2e),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 示例按钮
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.cyan, Colors.blue, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _simulateUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '开始系统升级',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // 手动控制按钮组
              Text(
                "手动控制示例：",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 16),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildControlButton("25%", 0.25, "下载中", "正在下载更新包"),
                  _buildControlButton("50%", 0.5, "安装中", "正在安装系统更新"),
                  _buildControlButton("75%", 0.75, "配置中", "正在优化系统配置"),
                  _buildControlButton("完成", 1.0, "升级完成", "系统已更新到最新版本"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(String label, double progress, String status, String detail) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentProgress = progress;
          _currentStatus = status;
          _currentDetail = detail;
          _isComplete = progress >= 1.0;
          _canClose = progress >= 1.0;
        });
        _showUpgradeDialog();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }
}

void main() {
  runApp(MyApp());
}