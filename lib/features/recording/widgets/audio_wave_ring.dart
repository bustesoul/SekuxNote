import 'dart:math' as math;

import 'package:flutter/material.dart';

class AudioWaveRing extends StatefulWidget {
  const AudioWaveRing({
    super.key,
    required this.level,
    this.paused = false,
    this.size = 136,
  });

  final double level;
  final bool paused;
  final double size;

  @override
  State<AudioWaveRing> createState() => _AudioWaveRingState();
}

class _AudioWaveRingState extends State<AudioWaveRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phase = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(AudioWaveRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final shouldAnimate = !widget.paused && widget.level > 0.01;
    if (shouldAnimate && !_phase.isAnimating) {
      _phase.repeat();
    } else if (!shouldAnimate && _phase.isAnimating) {
      _phase.stop();
    }
  }

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.paused
        ? Theme.of(context).colorScheme.outline
        : Theme.of(context).colorScheme.error;
    return Semantics(
      label: widget.paused ? '录音已暂停' : '实时录音音量',
      value: '${(widget.level.clamp(0, 1) * 100).round()}%',
      child: SizedBox.square(
        dimension: widget.size,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: widget.paused ? 0 : widget.level),
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          builder: (context, level, _) => Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                key: const Key('recording_audio_wave_ring'),
                size: Size.square(widget.size),
                painter: _AudioWaveRingPainter(
                  color: color,
                  level: level.clamp(0, 1),
                  phase: _phase,
                ),
              ),
              Container(
                width: widget.size * 0.42,
                height: widget.size * 0.42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.paused ? Icons.pause_rounded : Icons.mic_rounded,
                  size: widget.size * 0.24,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioWaveRingPainter extends CustomPainter {
  _AudioWaveRingPainter({
    required this.color,
    required this.level,
    required this.phase,
  }) : super(repaint: phase);

  static const _barCount = 56;

  final Color color;
  final double level;
  final Animation<double> phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final barWidth = math.max(3.0, size.shortestSide * 0.026);
    final baseRadius = size.shortestSide * 0.36;
    final maximumExtra = size.shortestSide * 0.12;
    final paint = Paint()..color = color;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (var index = 0; index < _barCount; index += 1) {
      final wave =
          0.5 + 0.5 * math.sin(index * 1.73 + phase.value * math.pi * 2);
      final barHeight = barWidth + level * maximumExtra * (0.3 + wave * 0.7);
      final rect = Rect.fromCenter(
        center: Offset(0, -baseRadius - barHeight / 2),
        width: barWidth,
        height: barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
        paint,
      );
      canvas.rotate(math.pi * 2 / _barCount);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AudioWaveRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.level != level;
}
