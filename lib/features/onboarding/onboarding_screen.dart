import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../auth/presentation/providers/user_avatar_provider.dart';
import '../auth/presentation/screens/choose_avatar_screen.dart';
import '../home/providers/home_providers.dart';

/// 2-Page Onboarding Experience:
/// - Screen 1: Infinite 4-row tilted sliding poster wall with brand tagline & "Get Started"
/// - Screen 2: Dynamic iOS-inspired glassmorphic Sign Up & Log In bottom form with smooth animation
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
  bool _obscureConfirmPassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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
    _confirmPasswordController.dispose();
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
        : screenHeight * 0.50;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Infinite Gapless 4-Row Tilted Moving Poster Wall ────────────
          Positioned.fill(
            child: _Infinite4RowPosterWall(
              animation: _wallController,
              posters: allPosters,
            ),
          ),

          // ── 2. Clean Dark Gradient Bottom Overlay (Zero Blur) ────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: blurHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.98),
                  ],
                  stops: const [0.0, 0.20, 0.60, 1.0],
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
  // PAGE 2: DYNAMIC IOS-INSPIRED SIGN UP / LOG IN FORM (ANIMATED TRANSITION)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPage2(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.06),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _isSignUp ? _buildSignUpContent() : _buildLogInContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpContent() {
    final currentAvatar = ref.watch(userAvatarProvider);

    return Column(
      key: const ValueKey('signUpContent'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with Disney Avatar Picker
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sign up to stream unlimited movies & series',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.70),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Avatar Circle with Edit Badge
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ChooseAvatarScreen(),
                  ),
                );
              },
              child: Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                        color: const Color(0xFF1E2130),
                        child: Image.asset(
                          currentAvatar.assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.black,
                        size: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 1. Full Name Field
        _buildGlassTextField(
          controller: _nameController,
          hint: 'Full Name',
          icon: IconlyBold.profile,
        ),
        const SizedBox(height: 9),

        // 2. Email Address Field
        _buildGlassTextField(
          controller: _emailController,
          hint: 'Email address',
          icon: IconlyBold.message,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 9),

        // 3. Password Field
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
        const SizedBox(height: 9),

        // 4. Confirm Password Field
        _buildGlassTextField(
          controller: _confirmPasswordController,
          hint: 'Confirm Password',
          icon: IconlyBold.lock,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white.withOpacity(0.6),
              size: 18,
            ),
            onPressed: () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
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
            child: const Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),

        const SizedBox(height: 11),

        // Single Switch Button (with guest skip option)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Single Switch Button to Log In
            GestureDetector(
              onTap: () => setState(() => _isSignUp = false),
              child: Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11.5,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Log In',
                      style: TextStyle(
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
    );
  }

  Widget _buildLogInContent() {
    return Column(
      key: const ValueKey('logInContent'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        const Text(
          'Welcome Back',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Log in to continue streaming',
          style: TextStyle(
            color: Colors.white.withOpacity(0.70),
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 14),

        // 1. Email Address Field
        _buildGlassTextField(
          controller: _emailController,
          hint: 'Email address',
          icon: IconlyBold.message,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),

        // 2. Password Field
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
            child: const Text(
              'Log In',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),

        const SizedBox(height: 11),

        // Single Switch Button (with guest skip option)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Single Switch Button to Sign Up
            GestureDetector(
              onTap: () => setState(() => _isSignUp = true),
              child: Text.rich(
                TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11.5,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Sign Up',
                      style: TextStyle(
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
      height: 45,
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
          contentPadding: const EdgeInsets.symmetric(vertical: 13.5),
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
// INFINITE GAPLESS 4-ROW TILTED MOVING POSTER MARQUEE
// ─────────────────────────────────────────────────────────────────────────────

class _Infinite4RowPosterWall extends StatelessWidget {
  final Animation<double> animation;
  final List<String> posters;

  const _Infinite4RowPosterWall({
    required this.animation,
    required this.posters,
  });

  @override
  Widget build(BuildContext context) {
    // Partition posters evenly across 4 distinct sets
    final int count = posters.length;
    final rowTop = [for (int i = 0; i < count; i++) posters[(i + 2) % count]];
    final row0 = [for (int i = 0; i < count; i++) posters[i % count]];
    final row1 = [for (int i = 0; i < count; i++) posters[(i + 5) % count]];
    final row2 = [for (int i = 0; i < count; i++) posters[(i + 9) % count]];

    return Transform.scale(
      scale: 1.55, // Scale up to completely cover all corners including top-left when tilted
      child: Transform.rotate(
        angle: -11 * (math.pi / 180),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final double progress = animation.value;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Row 0: Top row that completely covers the top-left corner gap
                _InfinitePosterMarquee(
                  posters: rowTop,
                  progress: progress,
                  direction: 1, // Moves RIGHT
                  phaseOffset: 0.15,
                ),
                const SizedBox(height: 12),

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
