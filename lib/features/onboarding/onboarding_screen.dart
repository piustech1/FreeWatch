import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../home/providers/home_providers.dart';

/// 2-Page Onboarding Experience:
/// - Screen 1: Infinite 3-row tilted sliding poster wall with brand tagline & "Get Started"
/// - Screen 2: Dynamic iOS-inspired glassmorphic Sign Up & Log In bottom form over sliding posters
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _wallController;
  int _currentPage = 0;

  // Screen 2 Auth form states
  bool _isSignUp = true;
  bool _obscurePassword = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Continuous infinite drifting animation for tilted poster marquee
    _wallController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat();
  }

  void _goToAuthPage() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _finishAuth() {
    context.go('/home');
  }

  @override
  void dispose() {
    _wallController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Collect posters from TMDB with fallback
    final trending = ref.watch(trendingMoviesProvider).valueOrNull ?? [];
    final popular = ref.watch(popularMoviesProvider).valueOrNull ?? [];

    final Set<String> liveUrls = {};
    for (final m in [...trending, ...popular]) {
      if (m.posterPath != null && m.posterPath!.isNotEmpty) {
        liveUrls.add('${ApiConstants.posterW500}${m.posterPath}');
      }
    }

    final allPosters = liveUrls.length >= 15
        ? liveUrls.toList()
        : [...liveUrls, ..._fallbackPosters];

    final screenHeight = MediaQuery.of(context).size.height;
    final blurHeight = _currentPage == 0
        ? screenHeight * 0.40
        : screenHeight * 0.46;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Infinite Gapless 3-Row Tilted Moving Poster Wall ────────────
          Positioned.fill(
            child: _Infinite3RowPosterWall(
              animation: _wallController,
              posters: allPosters,
            ),
          ),

          // ── 2. Subtle Glassmorphism Frosted Blur Panel (Lower Height) ─────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: blurHeight,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.50),
                        Colors.black.withOpacity(0.82),
                        Colors.black.withOpacity(0.96),
                      ],
                      stops: const [0.0, 0.20, 0.60, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 3. PageView (Page 1: Brand Intro, Page 2: Dynamic Auth) ────────
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              // ── PAGE 1: Brand Tagline & Get Started ───────────────────────
              _buildPage1(context),

              // ── PAGE 2: Dynamic iOS-Style Sign Up / Log In Form ───────────
              _buildPage2(context),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 1: BRAND INTRO
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPage1(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left-Aligned FW Initials Logo
            Image.asset(
              'assets/images/logo_initials.png',
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 14),

            // Left-Aligned Title
            const Text(
              'The greatest stories,\nall in one place.',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
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

            const SizedBox(height: 8),

            // Left-Aligned Subtitle
            Text(
              'Unlimited streaming for movies, series & exclusive hits translated by top Ugandan VJs.',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.45,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 8,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2-Dot Page Indicator
            SmoothPageIndicator(
              controller: _pageController,
              count: 2,
              effect: const ExpandingDotsEffect(
                dotWidth: 6,
                dotHeight: 6,
                expansionFactor: 3.5,
                spacing: 6,
                activeDotColor: AppColors.accent,
                dotColor: Color(0xFF383D4A),
              ),
            ),

            const SizedBox(height: 20),

            // Primary "Get Started" Button (Advances to Auth)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _goToAuthPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  shadowColor: AppColors.accentGlow,
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 2: DYNAMIC IOS-INSPIRED SIGN UP / LOG IN FORM
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPage2(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Glassmorphic Card Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Form Header & Switch Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSignUp ? 'Create Account' : 'Welcome Back',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isSignUp
                                ? 'Sign up to stream unlimited movies'
                                : 'Log in to continue streaming',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.70),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      // Small Segmented Pill
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            _buildPillTab('Sign Up', _isSignUp, () {
                              setState(() => _isSignUp = true);
                            }),
                            _buildPillTab('Log In', !_isSignUp, () {
                              setState(() => _isSignUp = false);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Full Name Field (Sign Up only)
                  if (_isSignUp) ...[
                    _buildGlassTextField(
                      controller: _nameController,
                      hint: 'Full Name',
                      icon: IconlyBold.profile,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Email Address Field
                  _buildGlassTextField(
                    controller: _emailController,
                    hint: 'Email address',
                    icon: IconlyBold.message,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 10),

                  // Password Field
                  _buildGlassTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: IconlyBold.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withOpacity(0.6),
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Primary Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _finishAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        shadowColor: AppColors.accentGlow,
                      ),
                      child: Text(
                        _isSignUp ? 'Sign Up' : 'Log In',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Bottom Switch & Guest Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Toggle Link
                      GestureDetector(
                        onTap: () => setState(() => _isSignUp = !_isSignUp),
                        child: Text.rich(
                          TextSpan(
                            text: _isSignUp
                                ? 'Already have an account? '
                                : "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11.5,
                            ),
                            children: [
                              TextSpan(
                                text: _isSignUp ? 'Log In' : 'Sign Up',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Continue as Guest link
                      GestureDetector(
                        onTap: _finishAuth,
                        child: Text(
                          'Skip >',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTab(String title, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.black : Colors.white.withOpacity(0.7),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: Icon(
            icon,
            color: AppColors.accent.withOpacity(0.9),
            size: 17,
          ),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.40),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
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
// INFINITE GAPLESS 3-ROW TILTED MOVING POSTER MARQUEE
// ─────────────────────────────────────────────────────────────────────────────

class _Infinite3RowPosterWall extends StatelessWidget {
  final Animation<double> animation;
  final List<String> posters;

  const _Infinite3RowPosterWall({
    required this.animation,
    required this.posters,
  });

  @override
  Widget build(BuildContext context) {
    // Partition posters evenly across 3 distinct sets
    final int count = posters.length;
    final row0 = [for (int i = 0; i < count; i++) posters[i % count]];
    final row1 = [for (int i = 0; i < count; i++) posters[(i + 4) % count]];
    final row2 = [for (int i = 0; i < count; i++) posters[(i + 8) % count]];

    return Transform.scale(
      scale: 1.45,
      child: Transform.rotate(
        angle: -11 * (math.pi / 180),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final double progress = animation.value;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Row 1: Moves LEFT continuously
                _InfinitePosterMarquee(
                  posters: row0,
                  progress: progress,
                  direction: -1,
                ),
                const SizedBox(height: 12),

                // Row 2: Moves RIGHT continuously
                _InfinitePosterMarquee(
                  posters: row1,
                  progress: progress,
                  direction: 1,
                ),
                const SizedBox(height: 12),

                // Row 3: Moves LEFT continuously
                _InfinitePosterMarquee(
                  posters: row2,
                  progress: progress,
                  direction: -1,
                  phaseOffset: 0.35,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfinitePosterMarquee extends StatelessWidget {
  final List<String> posters;
  final double progress;
  final int direction; // -1 for left, 1 for right
  final double phaseOffset;

  const _InfinitePosterMarquee({
    required this.posters,
    required this.progress,
    required this.direction,
    this.phaseOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 125.0;
    const double cardMargin = 10.0;
    const double itemStep = cardWidth + cardMargin;
    final double cycleWidth = posters.length * itemStep;

    // Seamless gapless translation modulo cycleWidth
    final double effectiveProgress = (progress + phaseOffset) % 1.0;
    final double dx = direction < 0
        ? - (effectiveProgress * cycleWidth)
        : - cycleWidth + (effectiveProgress * cycleWidth);

    // Quadruple posters list so it spans thousands of pixels with no edge cutoffs
    final seamlessList = [
      ...posters,
      ...posters,
      ...posters,
      ...posters,
    ];

    return SizedBox(
      height: 185,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          maxWidth: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: seamlessList.map((url) {
              return Padding(
                padding: const EdgeInsets.only(right: cardMargin),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: cardWidth,
                    height: 185,
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
