import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../home/providers/home_providers.dart';

/// 4-page Onboarding experience featuring:
/// - Full-bleed tilted dynamic moving TMDB poster wall (alternating rows drifting left/right)
/// - Bottom glassmorphism frosted blur effect
/// - Left-aligned typography and action controls
/// - Seamless progression from Page 1 Get Started -> Pages 2-4 -> Home
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _wallController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Continuous drifting animation for the tilted poster wall
    _wallController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  void _nextPage() {
    if (_currentIndex < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    context.go('/home');
  }

  @override
  void dispose() {
    _wallController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Collect posters from live TMDB providers with high-resolution fallbacks
    final trending = ref.watch(trendingMoviesProvider).valueOrNull ?? [];
    final popular = ref.watch(popularMoviesProvider).valueOrNull ?? [];

    final Set<String> liveUrls = {};
    for (final m in [...trending, ...popular]) {
      if (m.posterPath != null && m.posterPath!.isNotEmpty) {
        liveUrls.add('${ApiConstants.posterW500}${m.posterPath}');
      }
    }

    final allPosters = liveUrls.length >= 16
        ? liveUrls.toList()
        : [...liveUrls, ..._fallbackPosters];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Dynamic Tilted Moving Poster Wall (Entire Screen) ───────────
          Positioned.fill(
            child: _TiltedMovingPosterWall(
              animation: _wallController,
              posters: allPosters,
            ),
          ),

          // ── 2. Bottom Glassmorphic Blur Panel ─────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.52,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.65),
                        Colors.black.withOpacity(0.92),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.22, 0.65, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 3. PageView with Left-Aligned Content ─────────────────────────
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: [
              // Page 1: Disney+ Style Branding
              _OnboardingStep(
                showLogo: true,
                title: 'The greatest stories,\nall in one place.',
                subtitle:
                    'Unlimited streaming for movies, series & exclusive hits translated by top Ugandan VJs.',
                buttonText: 'Get Started',
                onButtonTap: _nextPage,
                controller: _pageController,
                isFirst: true,
                isLast: false,
              ),

              // Page 2: Experience & Quality
              _OnboardingStep(
                showLogo: false,
                title: 'Where stories come\nalive on screen.',
                subtitle:
                    'Watch your favorite blockbusters with rich localized audio, crystal clarity, and zero buffering.',
                buttonText: 'Next',
                onButtonTap: _nextPage,
                onSkip: _finishOnboarding,
                controller: _pageController,
                isFirst: false,
                isLast: false,
              ),

              // Page 3: Massive Library
              _OnboardingStep(
                showLogo: false,
                title: 'Stream the magic of\nevery genre.',
                subtitle:
                    'Explore thousands of movies, action thrillers, romantic dramas, and top trending TV series.',
                buttonText: 'Next',
                onButtonTap: _nextPage,
                onSkip: _finishOnboarding,
                controller: _pageController,
                isFirst: false,
                isLast: false,
              ),

              // Page 4: Ready to Stream
              _OnboardingStep(
                showLogo: false,
                title: 'Your favorite cinema,\nalways in reach.',
                subtitle:
                    'Join thousands enjoying free entertainment anywhere, anytime. Tap below to begin watching.',
                buttonText: 'Get Started',
                onButtonTap: _finishOnboarding,
                onSkip: _finishOnboarding,
                controller: _pageController,
                isFirst: false,
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const List<String> _fallbackPosters = [
    'https://image.tmdb.org/t/p/w500/A7EByudX0eOzlkQ2FIbogzyazm2.jpg',
    'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
    'https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
    'https://image.tmdb.org/t/p/w500/2cxhvwyEwRlysAmRH4iodkvo0z5.jpg',
    'https://image.tmdb.org/t/p/w500/m20yt7Ul7hJBLv0S8j7Hn6Zk2iV.jpg',
    'https://image.tmdb.org/t/p/w500/kSpsYjG80eL4qQ3R3n9k6rLqC9p.jpg',
    'https://image.tmdb.org/t/p/w500/aLVkiINNOgr1lYzZCrjWBsEV9um.jpg',
    'https://image.tmdb.org/t/p/w500/lrkudNqmG39w62M4t4o6kQ7gV0r.jpg',
    'https://image.tmdb.org/t/p/w500/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg',
    'https://image.tmdb.org/t/p/w500/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg',
    'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
    'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
    'https://image.tmdb.org/t/p/w500/fiVW06jE7z9YnO4trhaMEdclSiC.jpg',
    'https://image.tmdb.org/t/p/w500/7WsyChQLEftFiDOVTGkv3hFpyyt.jpg',
    'https://image.tmdb.org/t/p/w500/iuFNMS8U5cb6xfzi51Dbkovj7vM.jpg',
    'https://image.tmdb.org/t/p/w500/9Gtg2DzBhmYamXBS1hKAhiwbBKS.jpg',
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// TILTED DYNAMIC MOVING POSTER WALL
// ─────────────────────────────────────────────────────────────────────────────

class _TiltedMovingPosterWall extends StatelessWidget {
  final Animation<double> animation;
  final List<String> posters;

  const _TiltedMovingPosterWall({
    required this.animation,
    required this.posters,
  });

  @override
  Widget build(BuildContext context) {
    // 4 rows of posters distributed across the wall
    final int count = posters.length;
    final row0 = [for (int i = 0; i < 8; i++) posters[i % count]];
    final row1 = [for (int i = 0; i < 8; i++) posters[(i + 4) % count]];
    final row2 = [for (int i = 0; i < 8; i++) posters[(i + 8) % count]];
    final row3 = [for (int i = 0; i < 8; i++) posters[(i + 12) % count]];

    return Transform.scale(
      scale: 1.45, // Scale up to completely cover all corners when tilted
      child: Transform.rotate(
        angle: -11 * (math.pi / 180), // Tilted dynamic angle
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final double t = animation.value;
            // Loop smoothly across card width + spacing
            const double cardStep = 150.0;
            final double offset1 = (t * cardStep * 4) % (cardStep * 4);
            final double offset2 = (-t * cardStep * 4) % (cardStep * 4);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PosterRow(posters: row0, offset: offset1),
                const SizedBox(height: 12),
                _PosterRow(posters: row1, offset: offset2),
                const SizedBox(height: 12),
                _PosterRow(posters: row2, offset: offset1 - 60),
                const SizedBox(height: 12),
                _PosterRow(posters: row3, offset: offset2 + 60),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PosterRow extends StatelessWidget {
  final List<String> posters;
  final double offset;

  const _PosterRow({
    required this.posters,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: OverflowBox(
          maxWidth: double.infinity,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: posters.map((url) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 130,
                    height: 190,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: const Color(0xFF14161F)),
                      errorWidget: (_, __, ___) =>
                          Container(color: const Color(0xFF14161F)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONBOARDING STEP (LEFT-ALIGNED CONTENT & CONTROLS)
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingStep extends StatelessWidget {
  final bool showLogo;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onButtonTap;
  final VoidCallback? onSkip;
  final PageController controller;
  final bool isFirst;
  final bool isLast;

  const _OnboardingStep({
    required this.showLogo,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onButtonTap,
    this.onSkip,
    required this.controller,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional FW Initials Logo on Page 1
            if (showLogo) ...[
              Image.asset(
                'assets/images/logo_initials.png',
                height: 52,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 18),
            ],

            // Left-Aligned Title
            Text(
              title,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                height: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Left-Aligned Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                height: 1.45,
                shadows: const [
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 8,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Expanding Pill Indicator
            SmoothPageIndicator(
              controller: controller,
              count: 4,
              effect: const ExpandingDotsEffect(
                dotWidth: 6,
                dotHeight: 6,
                expansionFactor: 3.8,
                spacing: 6,
                activeDotColor: AppColors.accent,
                dotColor: Color(0xFF333846),
              ),
            ),

            const SizedBox(height: 26),

            // Action Buttons
            if (isFirst) ...[
              // Full-width Get Started Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onButtonTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    shadowColor: AppColors.accentGlow,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Two Button Row: Skip & Next/Get Started (Zero Outlines)
              Row(
                children: [
                  // Skip button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0x2EFFFFFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Next / Get Started button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: onButtonTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          shadowColor: AppColors.accentGlow,
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
