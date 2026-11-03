import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/device_type_service.dart';
import 'app_toast.dart';

/// Modal dialog presenting the FreeWatch TikTok Community Banner.
/// Replicates AppLaunchBannerModal.tsx with widescreen TV layout & D-Pad remote control.
class TiktokPromoModal extends StatefulWidget {
  final VoidCallback? onDismiss;

  const TiktokPromoModal({
    super.key,
    this.onDismiss,
  });

  static const String _prefHasClickedJoin = 'has_clicked_join_community_v1';
  static bool _sessionShown = false;
  static DateTime? _lastModalShownTime;
  static const Duration minIntervalBetweenModals = Duration(minutes: 6);

  static Future<bool> hasJoinedCommunity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefHasClickedJoin) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markCommunityJoined() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefHasClickedJoin, true);
    } catch (_) {}
  }

  static void showOncePerSession(BuildContext context) {
    if (_sessionShown) return;
    _sessionShown = true;
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        if (!context.mounted) return;
        if (await hasJoinedCommunity()) return;
        if (!context.mounted) return;
        show(context);
      } catch (_) {}
    });
  }

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onDismiss,
    bool force = false,
  }) async {
    try {
      if (await hasJoinedCommunity()) {
        onDismiss?.call();
        return;
      }
      if (!force && _lastModalShownTime != null) {
        final elapsed = DateTime.now().difference(_lastModalShownTime!);
        if (elapsed < minIntervalBetweenModals) {
          onDismiss?.call();
          return;
        }
      }
      _lastModalShownTime = DateTime.now();

      if (!context.mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.80),
        builder: (ctx) => TiktokPromoModal(onDismiss: onDismiss),
      );
      onDismiss?.call();
    } catch (_) {
      onDismiss?.call();
    }
  }

  @override
  State<TiktokPromoModal> createState() => _TiktokPromoModalState();
}

class _TiktokPromoModalState extends State<TiktokPromoModal> {
  int _focusedButtonIndex = 0; // 0 = Join, 1 = Continue

  Future<void> _openTiktok(BuildContext context) async {
    await TiktokPromoModal.markCommunityJoined();
    final uri = Uri.parse(ApiConstants.tiktokUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.show(
          context,
          'Could not open TikTok. Visit @freewatch manually!',
          isSuccess: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideOrTv = size.width >= 720 || DeviceTypeService().isTv;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: isWideOrTv ? 580 : (size.width * 0.88).clamp(280.0, 360.0),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1117).withOpacity(0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 40,
                  spreadRadius: 6,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: const Color(0xFFFE2C55).withOpacity(0.20),
                  blurRadius: 30,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  isWideOrTv ? _buildLandscapeLayout(context) : _buildPortraitLayout(context),

                  // Floating Top-Right Close Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: FocusableActionDetector(
                      actions: {
                        ActivateIntent: CallbackAction<ActivateIntent>(
                          onInvoke: (_) => Navigator.of(context).pop(),
                        ),
                      },
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Landscape Layout (1:1 clone of AppLaunchBannerModal.tsx for TV & PC)
  Widget _buildLandscapeLayout(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Artwork banner with vignette
          GestureDetector(
            onTap: () => _openTiktok(context),
            child: SizedBox(
              width: 240,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/tiktok_promo_banner.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF161822),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.video_library_rounded,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Color(0xFF0F1117),
                          ],
                          stops: [0.0, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Content Details & TV Focusable Action Buttons
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Join FreeWatch on TikTok',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get instant updates on the newest Luganda dubbed blockbusters & daily movie releases.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Column(
                    children: [
                      // Primary Button: Join TikTok Community
                      _buildJoinButton(context, isLandscape: true),
                      const SizedBox(height: 10),
                      // Secondary Button: Continue to FreeWatch
                      _buildContinueButton(context, isLandscape: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Portrait Layout (Clean Mobile Layout)
  Widget _buildPortraitLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _openTiktok(context),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/tiktok_promo_banner.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF161822),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.video_library_rounded,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0F1117).withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildJoinButton(context, isLandscape: false),
              const SizedBox(height: 8),
              _buildContinueButton(context, isLandscape: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJoinButton(BuildContext context, {required bool isLandscape}) {
    final isFocused = _focusedButtonIndex == 0;

    return FocusableActionDetector(
      autofocus: true,
      onFocusChange: (f) => setState(() => _focusedButtonIndex = f ? 0 : -1),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => _openTiktok(context),
        ),
      },
      child: InkWell(
        onTap: () => _openTiktok(context),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedScale(
          scale: isFocused ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFFFE2C55), Color(0xFFFF0050), Color(0xFFE50914)],
              ),
              border: Border.all(
                color: isFocused ? Colors.white : Colors.transparent,
                width: isFocused ? 2.5 : 0.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFE2C55).withOpacity(isFocused ? 0.7 : 0.4),
                  blurRadius: isFocused ? 18 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note_rounded, color: Colors.white, size: 19),
                SizedBox(width: 8),
                Text(
                  'Join TikTok Community',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, {required bool isLandscape}) {
    final isFocused = _focusedButtonIndex == 1;

    return FocusableActionDetector(
      onFocusChange: (f) => setState(() => _focusedButtonIndex = f ? 1 : -1),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => Navigator.of(context).pop(),
        ),
      },
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedScale(
          scale: isFocused ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isFocused ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.06),
              border: Border.all(
                color: isFocused ? Colors.white : Colors.transparent,
                width: isFocused ? 2.0 : 0.0,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'Continue to FreeWatch',
              style: TextStyle(
                color: isFocused ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
