import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class SeekBar extends StatelessWidget {
  const SeekBar({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
    this.a,
    this.b,
    this.onWheel,
  });

  final double value;
  final double max;
  final ValueChanged<double> onChanged;
  final Duration? a;
  final Duration? b;
  final ValueChanged<double>? onWheel;

  @override
  Widget build(BuildContext context) {
    final safeMax = max <= 0 ? 1.0 : max;
    final markerA = a == null ? null : a!.inMilliseconds / safeMax;
    final markerB = b == null ? null : b!.inMilliseconds / safeMax;

    return Listener(
      onPointerSignal: (signal) {
        if (signal is PointerScrollEvent && onWheel != null) {
          onWheel!(signal.scrollDelta.dy < 0 ? 10 : -10);
        }
      },
      child: SizedBox(
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (markerA != null && markerB != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ABRangePainter(markerA, markerB),
                  ),
                ),
              ),
            SliderTheme(
              data: const SliderThemeData(
                trackHeight: 3,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: AppColors.accent,
                inactiveTrackColor: Color(0x66888888),
                thumbColor: AppColors.accent,
              ),
              child: Slider(
                value: value.clamp(0.0, safeMax).toDouble(),
                max: safeMax,
                onChanged: onChanged,
              ),
            ),
            if (markerA != null)
              _marker(markerA.clamp(0.0, 1.0).toDouble(), 'A'),
            if (markerB != null)
              _marker(markerB.clamp(0.0, 1.0).toDouble(), 'B'),
          ],
        ),
      ),
    );
  }

  Widget _marker(double fraction, String label) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment(fraction * 2 - 1, 0),
        child: Transform.translate(
          offset: const Offset(0, -7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 2, height: 12, color: AppColors.success),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ABRangePainter extends CustomPainter {
  const _ABRangePainter(this.a, this.b);

  final double a;
  final double b;

  @override
  void paint(Canvas canvas, Size size) {
    final start = (a.clamp(0.0, 1.0).toDouble() * size.width)
        .clamp(0.0, size.width)
        .toDouble();
    final end = (b.clamp(0.0, 1.0).toDouble() * size.width)
        .clamp(0.0, size.width)
        .toDouble();
    final paint = Paint()
      ..color = AppColors.success.withOpacity(0.75)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(start, size.height / 2),
      Offset(end, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ABRangePainter oldDelegate) =>
      oldDelegate.a != a || oldDelegate.b != b;
}
