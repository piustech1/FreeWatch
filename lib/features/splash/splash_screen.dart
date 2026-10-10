import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';

/// Modern Mobile Splash Screen:
/// - Pure OLED black background
/// - Centered full-text logo (assets/images/logo_full.png)
/// - Floating moving wave-like progressive bar
/// - White, bold, centered slogan without container or outline
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _waveController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _progressAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.95, curve: Curves.easeInOut),
    );

    _controller.forward();

    // Auto-navigate after animations complete: /home if logged in, /onboarding if not
    _navigationTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          context.go('/home');
        } else {
          context.go('/onboarding');
        }
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _waveController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Centered Full Text Logo & Wave-Like Progressive Bar ───────────
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(_scaleAnimation),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Full text logo
                      Image.asset(
                        'assets/images/logo_full.png',
                        width: 260,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 36),

                      // Floating wave-like progressive bar
                      AnimatedBuilder(
                        animation: Listenable.merge([_progressAnimation, _waveController]),
                        builder: (context, _) {
                          return _WaveProgressBar(
                            progress: _progressAnimation.value,
                            phase: _waveController.value * 2 * math.pi,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Clean White Centered Slogan (No container, no outline) ────────
          Positioned(
            left: 24,
            right: 24,
            bottom: 44,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'FreeWatch, free entertainment, free everywhere.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating wave-like progressive loading bar with oscillating sine wave and neon glow
class _WaveProgressBar extends StatelessWidget {
  final double progress;
  final double phase;

  const _WaveProgressBar({
    required this.progress,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 18,
      child: CustomPaint(
        painter: _WavePainter(
          progress: progress.clamp(0.0, 1.0),
          phase: phase,
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double phase;

  _WavePainter({
    required this.progress,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    const double amplitude = 4.0;
    const double waveLength = 48.0;

    // Background track (subtle dark groove)
    final trackPaint = Paint()
      ..color = const Color(0xFF14161F)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      trackPaint,
    );

    final double activeWidth = size.width * progress;
    if (activeWidth <= 0) return;

    // Glowing wave path
    final path = Path();
    bool first = true;

    for (double x = 0; x <= activeWidth; x += 1.5) {
      final double y = midY + math.sin((x / waveLength * 2 * math.pi) - phase) * amplitude;
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    // Glow shadow
    final glowPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.4)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    canvas.drawPath(path, glowPaint);

    // Gradient wave line
    final wavePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF00E676),
          Color(0xFF00B0FF),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, wavePaint);

    // Leading particle / head dot
    if (activeWidth > 2) {
      final double headY = midY + math.sin((activeWidth / waveLength * 2 * math.pi) - phase) * amplitude;
      final dotPaint = Paint()
        ..color = const Color(0xFF00E676)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(activeWidth, headY), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.phase != phase;
  }
}
