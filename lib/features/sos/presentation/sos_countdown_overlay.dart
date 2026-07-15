import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shurokkha/core/localization/l10n/app_localizations.dart';

class SosCountdownOverlay extends StatefulWidget {
  final VoidCallback onTrigger;
  final VoidCallback onCancel;

  const SosCountdownOverlay({
    super.key,
    required this.onTrigger,
    required this.onCancel,
  });

  @override
  State<SosCountdownOverlay> createState() => _SosCountdownOverlayState();
}

class _SosCountdownOverlayState extends State<SosCountdownOverlay> with TickerProviderStateMixin {
  int _secondsRemaining = 3;
  Timer? _timer;

  late AnimationController _arcController;
  late AnimationController _pulseController;
  late AnimationController _textScaleController;
  late Animation<double> _textScaleAnimation;

  @override
  void initState() {
    super.initState();

    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _textScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _textScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(_textScaleController);

    _arcController.forward();
    _startCountdown();
  }

  void _startCountdown() {
    // Immediate haptic trigger on start
    HapticFeedback.heavyImpact();
    _textScaleController.forward(from: 0.0);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 1) {
        _timer?.cancel();
        widget.onTrigger();
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _secondsRemaining--;
        });
        _textScaleController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _arcController.dispose();
    _pulseController.dispose();
    _textScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background pulsing red vignette
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.red.withOpacity(0.15 * _pulseController.value),
                      Colors.black87,
                    ],
                  ),
                ),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular depletion arc around warning icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: AnimatedBuilder(
                        animation: _arcController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: CountdownArcPainter(
                              progress: 1.0 - _arcController.value,
                            ),
                          );
                        },
                      ),
                    ),
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 90,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Text countdown scale animation
                ScaleTransition(
                  scale: _textScaleAnimation,
                  child: Text(
                    l10n.countdownActive(_secondsRemaining),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your GPS location and audio recording will begin.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: widget.onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    l10n.cancelButton,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CountdownArcPainter extends CustomPainter {
  final double progress;

  CountdownArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 8.0;

    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start from top (-90 degrees or -pi/2 radians)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CountdownArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
