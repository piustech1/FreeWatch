import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import 'app_toast.dart';

/// Modal dialog presenting the FreeWatch TikTok Community Banner.
///
/// Displayed:
/// 1. Once per session upon launching the app (home screen).
/// 2. Prior to starting movie/episode playback.
/// 3. At 50% and 75% video progress as playback intermissions.
class TiktokPromoModal extends StatelessWidget {
  final VoidCallback? onDismiss;

  const TiktokPromoModal({
    super.key,
    this.onDismiss,
  });

  static bool _sessionShown = false;

  /// Shows the promo banner once per user session.
  static void showOncePerSession(BuildContext context) {
    if (_sessionShown) return;
    _sessionShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        show(context);
      }
    });
  }

  /// Displays the TikTok promo dialog.
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onDismiss,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => TiktokPromoModal(onDismiss: onDismiss),
    );
    onDismiss?.call();
  }

  Future<void> _openTiktok(BuildContext context) async {
    final uri = Uri.parse(ApiConstants.tiktokUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    final dialogWidth = (size.width * 0.88).clamp(280.0, 360.0);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: dialogWidth,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1117).withOpacity(0.92),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 4,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF00F2FE).withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Banner Image Container
                      GestureDetector(
                        onTap: () {
                          _openTiktok(context);
                        },
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
                              // Subtle bottom gradient vignette
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

                      // Action CTA Buttons Area
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Primary TikTok Community CTA Button
                            GestureDetector(
                              onTap: () {
                                _openTiktok(context);
                              },
                              child: Container(
                                width: double.infinity,
                                height: 46,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFE2C55), // TikTok Red
                                      Color(0xFFFF0050),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFE2C55).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.music_note_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Join FreeWatch on TikTok',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Dismiss / Continue Button
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: double.infinity,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withOpacity(0.06),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Continue Watching',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Floating Frosted Glass Close Button (Top Right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
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
}
