import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../auth/presentation/providers/user_avatar_provider.dart';
import '../auth/presentation/screens/choose_avatar_screen.dart';
import '../home/providers/home_providers.dart';

/// 2-Page Onboarding Experience:
/// - Ambient looping background movie video with seamless cinematic dark gradient overlay
/// - Screen 1: Brand tagline & "Get Started"
/// - Screen 2: Centered dynamic iOS-inspired glassmorphic Sign Up & Log In form with formal English
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _wallController;
  VideoPlayerController? _bgVideoController;

  // Screen 2 Auth form states
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;
  bool _isLoopingSeek = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    // Continuous drifting animation as fallback
    _wallController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat();

    _initBackgroundVideo();
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initBackgroundVideo() async {
    String selectedAsset = 'assets/videos/onboarding_bg.mp4';
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final videoAssets = manifest
          .listAssets()
          .where((p) => p.startsWith('assets/videos/') && p.endsWith('.mp4'))
          .toList();
      // Prioritize user-added custom videos over default onboarding_bg.mp4
      final customVideo = videoAssets.firstWhere(
        (p) => !p.contains('onboarding_bg.mp4'),
        orElse: () => '',
      );
      if (customVideo.isNotEmpty) {
        selectedAsset = customVideo;
      } else if (videoAssets.isNotEmpty) {
        selectedAsset = videoAssets.first;
      }
    } catch (_) {
      // Fallback to default asset
    }

    try {
      final controller = VideoPlayerController.asset(selectedAsset);
      _bgVideoController = controller;
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      await controller.setVolume(0.0);
      const loopStart = Duration(seconds: 42);
      final startOffset = controller.value.duration > loopStart ? loopStart : Duration.zero;
      if (startOffset > Duration.zero) {
        await controller.seekTo(startOffset);
      }
      controller.addListener(_handleVideoLoop);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _handleVideoLoop() {
    final controller = _bgVideoController;
    if (controller == null || !controller.value.isInitialized || _isLoopingSeek) return;
    final val = controller.value;
    const loopStart = Duration(seconds: 42);
    final startOffset = val.duration > loopStart ? loopStart : Duration.zero;

    // When nearing or reaching the end of the video, seamlessly loop back to 42s
    if (val.position >= val.duration - const Duration(milliseconds: 350) ||
        (!val.isPlaying && val.position >= val.duration - const Duration(seconds: 1))) {
      _isLoopingSeek = true;
      controller.seekTo(startOffset).then((_) {
        if (mounted && _bgVideoController == controller) {
          controller.play();
          _isLoopingSeek = false;
        }
      }).catchError((_) {
        _isLoopingSeek = false;
      });
    }
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
    _passwordController.removeListener(_onPasswordChanged);
    _bgVideoController?.removeListener(_handleVideoLoop);
    _bgVideoController?.dispose();
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

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Looping Muted Background Movie Video (With Poster Wall Fallback) ──
          Positioned.fill(
            child: _bgVideoController != null && _bgVideoController!.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _bgVideoController!.value.size.width,
                      height: _bgVideoController!.value.size.height,
                      child: VideoPlayer(_bgVideoController!),
                    ),
                  )
                : _Infinite4RowPosterWall(
                    animation: _wallController,
                    posters: allPosters,
                  ),
          ),

          // ── 2. Cinematic Dark Ambient Gradient Overlay ────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.68),
                    Colors.black.withOpacity(0.42),
                    Colors.black.withOpacity(0.78),
                    Colors.black.withOpacity(0.96),
                  ],
                  stops: const [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
          ),

          // ── 3. PageView (Page 1: Brand Intro, Page 2: Centered Dynamic Auth) ──
          PageView(
            controller: _pageController,
            children: [
              // ── PAGE 1: Brand Tagline & Get Started ───────────────────────
              _buildPage1(context),

              // ── PAGE 2: Centered Dynamic iOS-Style Sign Up / Log In Form ──
              _buildPage2(context),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 1: BRAND INTRO (Spacious, elegant, responsive layout)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPage1(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Logo & direct Log In shortcut
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/logo_initials.png',
                            height: 44,
                            fit: BoxFit.contain,
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _isSignUp = false);
                              _goToAuthPage();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                'Log In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),
                      const SizedBox(height: 28),

                      // Left-Aligned Title with generous typography & breathing room
                      const Text(
                        'The greatest stories,\nall in one place.',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          height: 1.18,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 16,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Left-Aligned Subtitle with comfortable line spacing
                      Text(
                        'Unlimited streaming for movies, series & exclusive hits translated by top Ugandan VJs.',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.45,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // 2-Dot Page Indicator
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: 2,
                        effect: const ExpandingDotsEffect(
                          dotWidth: 7,
                          dotHeight: 7,
                          expansionFactor: 3.5,
                          spacing: 7,
                          activeDotColor: AppColors.accent,
                          dotColor: Color(0xFF383D4A),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Primary "Get Started" Button (Advances to Auth)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _goToAuthPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.black,
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
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 2: CENTERED DYNAMIC IOS-INSPIRED SIGN UP / LOG IN FORM
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPage2(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              bottomInset > 0 ? bottomInset + 16 : 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - (bottomInset > 0 ? bottomInset + 16 : 36),
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand Icon (matching reference Image 3)
                      Image.asset(
                        'assets/images/logo_initials.png',
                        height: 52,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 14),

                      // Title: Welcome Back / Create Account
                      Text(
                        _isSignUp ? 'Create Account' : 'Welcome Back',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Floating Liquid Glassmorphic Auth Card (0% grey, 0% outline, pure white liquid glass)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: _isSignUp
                                  ? _buildSignUpContent()
                                  : _buildLogInContent(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Switch between Log In & Sign Up
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _isSignUp
                                  ? 'Already have an account? '
                                  : "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _isSignUp = !_isSignUp),
                              child: Text(
                                _isSignUp ? 'Log In' : 'Create Account',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Guest Skip Option
                      Center(
                        child: GestureDetector(
                          onTap: _finishAuth,
                          child: Text(
                            'Explore as Guest >',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.50),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogInContent() {
    return Column(
      key: const ValueKey('logInContent'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Email Field
        _buildGlassTextField(
          controller: _emailController,
          hint: 'Email Address',
          icon: IconlyLight.message,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),

        // 2. Password Field
        _buildGlassTextField(
          controller: _passwordController,
          hint: 'Password',
          icon: IconlyLight.lock,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white.withOpacity(0.6),
              size: 19,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
        ),

        const SizedBox(height: 16),

        // Remember me + Forgot Password (Wrap guarantees zero overflow with large fonts & small screens)
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          children: [
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: _rememberMe
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.35),
                        width: 1.4,
                      ),
                      color: _rememberMe
                          ? AppColors.primary
                          : Colors.transparent,
                    ),
                    child: _rememberMe
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 13,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset link sent to your email.'),
                    backgroundColor: Color(0xFF1E212D),
                  ),
                );
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Solid FreeWatch Red LOG IN Button
        _buildSolidSubmitButton('LOG IN'),
      ],
    );
  }

  Widget _buildSignUpContent() {
    final currentAvatar = ref.watch(userAvatarProvider);

    return Column(
      key: const ValueKey('signUpContent'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar row (only during sign up)
        Row(
          children: [
            Expanded(
              child: Text(
                'Choose Your Avatar',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 8,
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
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 1. Full Name Field
        _buildGlassTextField(
          controller: _nameController,
          hint: 'Full Name',
          icon: IconlyLight.profile,
        ),
        const SizedBox(height: 14),

        // 2. Email Address Field
        _buildGlassTextField(
          controller: _emailController,
          hint: 'Email Address',
          icon: IconlyLight.message,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),

        // 3. Password Field
        _buildGlassTextField(
          controller: _passwordController,
          hint: 'Password',
          icon: IconlyLight.lock,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white.withOpacity(0.6),
              size: 19,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
        ),
        _buildPasswordStrengthIndicator(),
        const SizedBox(height: 14),

        // 4. Confirm Password Field
        _buildGlassTextField(
          controller: _confirmPasswordController,
          hint: 'Confirm Password',
          icon: IconlyLight.lock,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white.withOpacity(0.6),
              size: 19,
            ),
            onPressed: () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            },
          ),
        ),

        const SizedBox(height: 22),

        // Solid FreeWatch Red SIGN UP Button
        _buildSolidSubmitButton('SIGN UP'),
      ],
    );
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[a-z]')) && password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength;
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = _calculatePasswordStrength(password);
    String label = 'Weak';
    Color strengthColor = AppColors.primary;
    if (strength == 2) {
      label = 'Fair';
      strengthColor = const Color(0xFFFFB800);
    } else if (strength == 3) {
      label = 'Good';
      strengthColor = const Color(0xFF4CAF50);
    } else if (strength >= 4) {
      label = 'Strong';
      strengthColor = const Color(0xFF00E676);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (index) {
              final isFilled = index < strength;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isFilled ? strengthColor : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password strength: $label',
                style: TextStyle(
                  color: strengthColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                strength < 4 ? 'Use 8+ chars, upper, number & symbol' : 'Strong password',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSolidSubmitButton(String text) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.40),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: _finishAuth,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: Icon(
                  icon,
                  color: Colors.white.withOpacity(0.85),
                  size: 19,
                ),
                suffixIcon: suffixIcon,
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.40),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth > 0 ? constraints.maxWidth : 400.0;
        return OverflowBox(
          minWidth: screenW,
          maxWidth: screenW,
          minHeight: 0,
          maxHeight: 1400,
          child: Transform.scale(
            scale: 1.55, // Scale up to completely cover all corners including top-left when tilted
            child: Transform.rotate(
              angle: -11 * (math.pi / 180),
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final double progress = animation.value;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
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
                        phaseOffset: 0.25,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
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
