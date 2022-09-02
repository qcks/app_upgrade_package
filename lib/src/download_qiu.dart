import 'package:flutter/material.dart';

class WaterContainerWidget extends StatefulWidget {
  final double size;
  final WaveContainerShape shape;
  final Color color;
  final double borderRadius;
  final double borderWidth;
  final double waterLevel;
  final int animateDuration;

  const WaterContainerWidget(
      {Key? key,
      this.animateDuration = 800,
      this.shape = WaveContainerShape.Circle,
      required this.size,
      required this.color,
      this.borderRadius = 0,
      this.borderWidth = 3,
      required this.waterLevel})
      : super(key: key);

  @override
  _WaterContainerWidgetState createState() => _WaterContainerWidgetState();
}

class _WaterContainerWidgetState extends State<WaterContainerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animateDuration),
    )..repeat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _WavePainter(
          size: widget.size,
          shape: widget.shape,
          color: widget.color,
          borderRadius: widget.borderRadius,
          borderWidth: widget.borderWidth,
          progress: _controller,
          waterLevel: widget.waterLevel,
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  var painter = Paint()
    ..color = Colors.blue
    ..strokeWidth = 2
    ..style = PaintingStyle.fill;
  var borderPainter = Paint()
    ..color = Colors.orange
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  final double size;
  final Color color;
  final WaveContainerShape shape;
  final double borderRadius;
  final double borderWidth;
  final double waterLevel;
  final Animation<double> progress;

  _WavePainter({
    required this.size,
    required this.shape,
    required this.color,
    required this.borderRadius,
    this.borderWidth = 0,
    required this.waterLevel,
    required this.progress,
  }) : super(repaint: progress);

  void _drawWave(Canvas canvas, double sigleWaveSize, Color color) {
    var _wavePath = Path();
    _wavePath.quadraticBezierTo(
        sigleWaveSize / 2, -sigleWaveSize / 8, sigleWaveSize, 0);
    _wavePath.relativeQuadraticBezierTo(
        sigleWaveSize / 2, sigleWaveSize / 8, sigleWaveSize, 0);
    _wavePath.relativeQuadraticBezierTo(
        sigleWaveSize / 2, -sigleWaveSize / 8, sigleWaveSize, 0);
    _wavePath.relativeQuadraticBezierTo(
        sigleWaveSize / 2, sigleWaveSize / 8, sigleWaveSize, 0);
    // path.moveTo(this.size, 0);
    _wavePath.relativeLineTo(0, this.size);
    _wavePath.relativeLineTo(-2 * this.size, 0);
    _wavePath.relativeLineTo(0, -this.size);
    _wavePath.close();
    canvas.drawPath(_wavePath, painter..color = color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // CoordinatePainter()..paint(canvas, size);
    // canvas.translate(-size.width / 2, 0);
    canvas.translate(0, size.width / 2);

    final double sigleWaveSize = this.size / 2;

    // Draw & Clip Rect
    var _cutPath = Path();
    if (this.shape == WaveContainerShape.Rect) {
      var rect = Rect.fromLTRB(
        0,
        -this.size / 2,
        this.size,
        this.size / 2,
      );
      _cutPath.addRRect(
        RRect.fromRectXY(
          rect,
          this.borderRadius,
          this.borderRadius,
        ),
      );
    }
    if (this.shape == WaveContainerShape.Circle) {
      _cutPath.addOval(
        Rect.fromLTRB(
          0,
          -this.size / 2,
          this.size,
          this.size / 2,
        ),
      );
    }
    canvas.drawPath(
      _cutPath,
      borderPainter
        ..color = this.color
        ..strokeWidth = borderWidth,
    );
    canvas.clipPath(_cutPath);

    // Draw Wave
    // 移动原点到波浪图形的开始位置
    // dx 要额外向左移动一个 widget size
    // dy 移动到波浪底部，然后减掉水位高度从而实现向上移动
    canvas.translate(-this.size, this.size / 2 - this.size * waterLevel);

    // Draw Wave behind
    canvas.save();
    if (progress.value > 0.5) {
      canvas.translate(this.size * (progress.value - 0.5) * 2, 0);
    } else {
      canvas.translate(this.size * progress.value * 2, 0);
    }
    _drawWave(canvas, sigleWaveSize, this.color.withAlpha(100));
    canvas.restore();

    // Draw Wave frontend
    canvas.save();
    canvas.translate(this.size * progress.value, 0);
    _drawWave(canvas, sigleWaveSize, this.color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) {
    return true;
  }
}

enum WaveContainerShape { Circle, Rect }
