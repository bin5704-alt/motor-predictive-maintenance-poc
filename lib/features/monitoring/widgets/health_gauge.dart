import 'dart:math';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class HealthGauge extends StatefulWidget {
  final double score; // 0 to 100
  final bool animate;

  const HealthGauge({super.key, required this.score, this.animate = true});

  @override
  State<HealthGauge> createState() => _HealthGaugeState();
}

class _HealthGaugeState extends State<HealthGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _setupAnimation();
    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(HealthGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _setupAnimation();
      _controller.forward(from: 0);
    }
  }

  void _setupAnimation() {
    _animation = Tween<double>(
      begin: 0,
      end: widget.score,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(250, 150), // Semi-circle aspect
          painter: _GaugePainter(score: _animation.value, context: context),
          child: SizedBox(
            width: 250,
            height: 150,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _animation.value.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Health Score',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final BuildContext context;

  _GaugePainter({required this.score, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = min(size.width / 2, size.height) - 10;
    final strokeWidth = 20.0;

    // Background Arc (Grey)
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // Start at 180 deg
      pi, // Sweep 180 deg
      false,
      bgPaint,
    );

    // Color Logic
    Color gaugeColor;
    if (score >= 80) {
      gaugeColor = AppTheme.statusGreen;
    } else if (score >= 40) {
      gaugeColor = AppTheme.statusAmber;
    } else {
      gaugeColor = AppTheme.statusRed;
    }

    // Active Arc
    final activePaint = Paint()
      ..color = gaugeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        colors: [gaugeColor.withValues(alpha: 0.5), gaugeColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Calculate active sweep angle based on score (0-100 maps to 0-PI)
    final sweepAngle = (score / 100) * pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      sweepAngle,
      false,
      activePaint,
    );

    // Needle
    // ... Simplified: Just the arc is cleaner for modern UI, but let's add a small indicator or 'glow' at the tip if we want.
    // For now, simple Arc + Text in center is very "Stripe/Tesla".
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
