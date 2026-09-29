import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_colors.dart';

/// 4-page Onboarding experience matching user reference designs:
/// - Page 1: Disney+ style vertical 3-strip poster layout with FW initial logo
/// - Pages 2-4: Staggered movie poster grid with Skip & Next/Get Started buttons
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  void _nextPage() {
    if (_currentIndex < 3) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _controller,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: [
          // ── Page 1: Disney+ Style ─────────────────────────────────────────
          _DisneyStylePage(
            onGetStarted: _nextPage,
          ),

          // ── Page 2: "Where stories come alive on screen" ─────────────────
          _GridOnboardingPage(
            title: 'Where stories come\nalive on screen',
            subtitle:
                'Watch your favorite movies, series, and exclusive content anytime, all in one app.',
            controller: _controller,
            isLast: false,
            onSkip: _finishOnboarding,
            onNext: _nextPage,
            offsetIndex: 0,
          ),

          // ── Page 3: "Stream the magic of every story" ────────────────────
          _GridOnboardingPage(
            title: 'Stream the magic of\nevery story',
            subtitle:
                'Enjoy a huge library of movies, series, and exclusive content—all in one convenient place.',
            controller: _controller,
            isLast: false,
            onSkip: _finishOnboarding,
            onNext: _nextPage,
            offsetIndex: 1,
          ),

          // ── Page 4: "Your favorite stories, always within reach" ──────────
          _GridOnboardingPage(
            title: 'Your favorite stories,\nalways within reach',
            subtitle:
                'Discover endless movies, series, and exclusive content—all at your fingertips.',
            controller: _controller,
            isLast: true,
            onSkip: _finishOnboarding,
            onNext: _finishOnboarding,
            offsetIndex: 2,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 1: DISNEY+ STYLE VERTICAL 3-STRIP LAYOUT
// ─────────────────────────────────────────────────────────────────────────────

class _DisneyStylePage extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _DisneyStylePage({required this.onGetStarted});

  // Posters for the 3 vertical strips
  static const _col1 = [
    'https://image.tmdb.org/t/p/w500/A7EByudX0eOzlkQ2FIbogzyazm2.jpg',
    'https://image.tmdb.org/t/p/w500/m20yt7Ul7hJBLv0S8j7Hn6Zk2iV.jpg',
  ];
  static const _col2 = [
    'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
    'https://image.tmdb.org/t/p/w500/kSpsYjG80eL4qQ3R3n9k6rLqC9p.jpg',
  ];
  static const _col3 = [
    'https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
    'https://image.tmdb.org/t/p/w500/2cxhvwyEwRlysAmRH4iodkvo0z5.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // ── Top 3 Vertical Strips ──────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height * 0.65,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: _PosterStrip(urls: _col1, topOffset: 0)),
                SizedBox(width: 8),
                Expanded(child: _PosterStrip(urls: _col2, topOffset: -24)),
                SizedBox(width: 8),
                Expanded(child: _PosterStrip(urls: _col3, topOffset: 12)),
              ],
            ),
          ),
        ),

        // ── Smooth Pitch-Black Gradient Fade ───────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: height * 0.58,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xD9000000),
                  AppColors.background,
                  AppColors.background,
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // ── Brand, Tagline & Bottom "Get Started" Button ───────────────────
        Positioned(
          left: 24,
          right: 24,
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // FW Initial Logo
              Image.asset(
                'assets/images/logo_initials.png',
                height: 56,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 16),

              // Disney-style Headline Tagline
              const Text(
                'The greatest stories,\nall in one place.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Unlimited streaming for movies, series & exclusive hits.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 28),

              // Full-width Get Started Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF000000),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    shadowColor: AppColors.accentGlow,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PosterStrip extends StatelessWidget {
  final List<String> urls;
  final double topOffset;

  const _PosterStrip({required this.urls, required this.topOffset});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: Transform.translate(
          offset: Offset(0, topOffset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: urls.map((url) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 0.65,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.surfaceLight),
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
// PAGES 2, 3, 4: STAGGERED MOVIE POSTER GRID LAYOUT
// ─────────────────────────────────────────────────────────────────────────────

class _GridOnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final PageController controller;
  final bool isLast;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final int offsetIndex;

  const _GridOnboardingPage({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.isLast,
    required this.onSkip,
    required this.onNext,
    required this.offsetIndex,
  });

  static const _postersPool = [
    [
      'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
      'https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
      'https://image.tmdb.org/t/p/w500/A7EByudX0eOzlkQ2FIbogzyazm2.jpg',
    ],
    [
      'https://image.tmdb.org/t/p/w500/2cxhvwyEwRlysAmRH4iodkvo0z5.jpg',
      'https://image.tmdb.org/t/p/w500/m20yt7Ul7hJBLv0S8j7Hn6Zk2iV.jpg',
      'https://image.tmdb.org/t/p/w500/kSpsYjG80eL4qQ3R3n9k6rLqC9p.jpg',
    ],
    [
      'https://image.tmdb.org/t/p/w500/aLVkiINNOgr1lYzZCrjWBsEV9um.jpg',
      'https://image.tmdb.org/t/p/w500/lrkudNqmG39w62M4t4o6kQ7gV0r.jpg',
      'https://image.tmdb.org/t/p/w500/A7EByudX0eOzlkQ2FIbogzyazm2.jpg',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final posters = _postersPool[offsetIndex % _postersPool.length];

    return Stack(
      children: [
        // ── Upper Staggered Poster Cards Grid ──────────────────────────────
        Positioned(
          top: 24,
          left: 16,
          right: 16,
          height: height * 0.52,
          child: Row(
            children: [
              Expanded(
                child: _GridColumn(
                  url1: posters[0],
                  url2: posters[1],
                  translateY: -16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GridColumn(
                  url1: posters[1],
                  url2: posters[2],
                  translateY: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GridColumn(
                  url1: posters[2],
                  url2: posters[0],
                  translateY: -10,
                ),
              ),
            ],
          ),
        ),

        // ── Bottom Pitch Black Gradient Overlay ─────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: height * 0.55,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xE6000000),
                  AppColors.background,
                  AppColors.background,
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),
        ),

        // ── Text, 4-Dot Indicator, and Action Buttons ──────────────────────
        Positioned(
          left: 24,
          right: 24,
          bottom: 36,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.45,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 4-Dot Page Indicator
              SmoothPageIndicator(
                controller: controller,
                count: 4,
                effect: const ExpandingDotsEffect(
                  dotWidth: 7,
                  dotHeight: 7,
                  expansionFactor: 3.5,
                  spacing: 6,
                  activeDotColor: AppColors.accent,
                  dotColor: Color(0xFF232733),
                ),
              ),

              const SizedBox(height: 28),

              // Two Buttons Row: Skip & Next / Get Started
              Row(
                children: [
                  // Skip button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: onSkip,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.14),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: const Color(0xFF000000),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          shadowColor: AppColors.accentGlow,
                        ),
                        child: Text(
                          isLast ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GridColumn extends StatelessWidget {
  final String url1;
  final String url2;
  final double translateY;

  const _GridColumn({
    required this.url1,
    required this.url2,
    required this.translateY,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: Transform.translate(
          offset: Offset(0, translateY),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PosterTile(url: url1),
              const SizedBox(height: 10),
              _PosterTile(url: url2),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterTile extends StatelessWidget {
  final String url;

  const _PosterTile({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 0.7,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: AppColors.surfaceLight),
          errorWidget: (_, __, ___) => Container(color: AppColors.surfaceLight),
        ),
      ),
    );
  }
}
