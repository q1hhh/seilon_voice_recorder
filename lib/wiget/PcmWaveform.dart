import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:math';

class PcmWaveform extends StatelessWidget {
  final Int16List pcm;
  final double height;
  final double width;
  final int samplesPerPixel;

  const PcmWaveform({
    required this.pcm,
    this.height = 100,
    this.width = double.infinity,
    this.samplesPerPixel = 200, // 你可以根据帧长度调节
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<double> waveform = _buildWaveform(pcm, samplesPerPixel);
    return CustomPaint(
      size: Size(width, height),
      painter: _WaveformPainter(waveform, height),
    );
  }

  List<double> _buildWaveform(Int16List pcm, int step) {
    final result = <double>[];
    for (int i = 0; i < pcm.length; i += step) {
      int end = min(i + step, pcm.length);
      double maxAmp = 0;
      for (int j = i; j < end; j++) {
        maxAmp = max(maxAmp, pcm[j].abs().toDouble());
      }
      result.add(maxAmp / 32768); // 归一化到 [0, 1]
    }
    return result;
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> waveform;
  final double height;

  _WaveformPainter(this.waveform, this.height);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 1;

    final centerY = height / 2;
    final widthPerSample = size.width / waveform.length;

    for (int i = 0; i < waveform.length; i++) {
      double x = i * widthPerSample;
      double amp = waveform[i] * centerY;
      canvas.drawLine(Offset(x, centerY - amp), Offset(x, centerY + amp), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
