import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_toast.dart';
import '../auth/presentation/providers/user_avatar_provider.dart';
import '../auth/presentation/providers/auth_providers.dart';
import '../auth/presentation/screens/choose_avatar_screen.dart';
import '../profile/presentation/providers/user_profile_provider.dart';

/// 2-Page Onboarding Experience:
/// - Ambient looping background movie video with seamless cinematic dark gradient overlay
/// - Screen 1: Brand tagline & "Get Started"
/// - Screen 2: Centered dynamic iOS-inspired glassmorphic Sign Up & Log In form with formal English
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  VideoPlayerController? _bgVideoController;

  // Screen 2 Auth form states
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;
  bool _isLoopingSeek = false;
  bool _isLoadingAuth = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
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

  Future<void> _handleSubmitAuth() async {
    if (_isLoadingAuth) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      AppToast.show(context, 'Please enter your email address', isSuccess: false);
      return;
    }
    if (password.isEmpty) {
      AppToast.show(context, 'Please enter your password', isSuccess: false);
      return;
    }

    if (_isSignUp) {
      final confirmPassword = _confirmPasswordController.text;
      if (password.length < 6) {
        AppToast.show(context, 'Password must be at least 6 characters', isSuccess: false);
        return;
      }
      if (password != confirmPassword) {
        AppToast.show(context, 'Passwords do not match', isSuccess: false);
        return;
      }

      final name = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'FreeWatch Member';
      final currentAvatar = ref.read(userAvatarProvider);

      setState(() => _isLoadingAuth = true);

      try {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.signUpWithEmail(
          email: email,
          password: password,
          name: name,
          avatarAsset: currentAvatar.assetPath,
        );

        if (!mounted) return;
        await ref.read(userProfileProvider.notifier).updateName(name);

        if (!mounted) return;
        AppToast.show(
          context,
          'Account created successfully! Welcome to FreeWatch',
          isSuccess: true,
        );
        context.go('/home');
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoadingAuth = false);
        AppToast.show(context, formatAuthErrorMessage(e), isSuccess: false);
      }
    } else {
      setState(() => _isLoadingAuth = true);

      try {
        final authRepo = ref.read(authRepositoryProvider);
        final cred = await authRepo.signInWithEmail(
          email: email,
          password: password,
        );

        if (!mounted) return;
        final user = cred.user;
        if (user != null) {
          final profile = await authRepo.getUserProfile(user.uid);
          final displayName = profile?['name'] as String? ?? user.displayName;
          if (displayName != null && displayName.isNotEmpty) {
            await ref.read(userProfileProvider.notifier).updateName(displayName);
          }
        }

        if (!mounted) return;
        AppToast.show(context, 'Welcome back to FreeWatch!', isSuccess: true);
        context.go('/home');
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoadingAuth = false);
        AppToast.show(context, formatAuthErrorMessage(e), isSuccess: false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _bgVideoController?.removeListener(_handleVideoLoop);
    _bgVideoController?.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Looping Muted Background Movie Video ──
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
                : const ColoredBox(color: AppColors.background),
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
                AppToast.show(
                  context,
                  'Password reset link sent to your email.',
                  isSuccess: true,
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
          onTap: _handleSubmitAuth,
          child: Center(
            child: _isLoadingAuth
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
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
}
