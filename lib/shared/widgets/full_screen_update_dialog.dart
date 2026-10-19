import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/app_update_service.dart';

/// Full-Screen, Non-Dismissible Update Screen matching reference design:
/// - Deep FreeWatch purple/indigo space gradient background with ambient radial glow
/// - Sleek custom-painted rocket illustration launching upwards with glowing thruster flames and exhaust clouds
/// - Clear headline "New Update is Available" & clean feature highlights
/// - Neon purple "UPDATE NOW!" capsule button redirecting directly to https://freewatchug.online
/// - Strict PopScope(canPop: false) to block back navigation until app is updated
class FullScreenUpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const FullScreenUpdateDialog({
    super.key,
    required this.updateInfo,
  });

  /// Static helper to display this full-screen update dialog modally
  static Future<void> show(BuildContext context, AppUpdateInfo info) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      pageBuilder: (_, __, ___) => FullScreenUpdateDialog(updateInfo: info),
    );
  }

  Future<void> _launchStore(BuildContext context) async {
    final urlStr = updateInfo.storeUrl.isNotEmpty
        ? updateInfo.storeUrl
        : AppUpdateService.defaultStoreListingUrl;
    try {
      final uri = Uri.parse(urlStr);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(Uri.parse(urlStr));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayVersion = updateInfo.version.isNotEmpty
        ? (updateInfo.version.startsWith('v')
            ? updateInfo.version
            : 'v${updateInfo.version}')
        : 'v${AppUpdateService.defaultVersionName}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0618),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background Ambient Glows & Stars ─────────────────────────────
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED).withOpacity(0.18),
                ),
              ),
            ),
            Positioned(
              top: 180,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9333EA).withOpacity(0.14),
                ),
              ),
            ),
            CustomPaint(
              painter: _StarfieldPainter(),
              size: Size.infinite,
            ),

            // ── Main Content ────────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 1),

                    // ── Sleek Rocket Launch Graphic (Vector + Custom Paint) ──
                    SizedBox(
                      height: 260,
                      width: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Radial violet glow backdrop behind rocket
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.35),
                                  blurRadius: 70,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          // Custom Painted Space Rocket
                          CustomPaint(
                            size: const Size(220, 220),
                            painter: _RocketLaunchPainter(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Version Badge Pill ───────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFA78BFA).withOpacity(0.35),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        displayVersion,
                        style: const TextStyle(
                          color: Color(0xFFC4B5FD),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Headline: "New Update is Available" ──────────────────
                    const Text(
                      'New Update is Available',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Subtitle ─────────────────────────────────────────────
                    Text(
                      'A new version is released, please update to get new features and performance enhancements.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Feature Highlights Box ──────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildBulletItem(
                                icon: Icons.bolt_rounded,
                                title: 'Instant Streaming & Deep Catalogs',
                                desc: 'Faster playback with high-speed BunnyCDN and Pearlpix servers.',
                              ),
                              const SizedBox(height: 10),
                              _buildBulletItem(
                                icon: Icons.category_rounded,
                                title: 'Rich Categorization',
                                desc: 'Drama, Animation, Family & regional genres deeply populated.',
                              ),
                              const SizedBox(height: 10),
                              _buildBulletItem(
                                icon: Icons.cloud_download_rounded,
                                title: 'Persistent Offline Storage',
                                desc: 'Save your favorite movies and series seamlessly.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // ── Glowing "UPDATE NOW!" Capsule Button ─────────────────
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.45),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () => _launchStore(context),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.rocket_launch_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'UPDATE NOW!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Store listing info note
                    Text(
                      'Official release available at freewatchug.online',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.40),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.20),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: const Color(0xFFA78BFA),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.60),
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter rendering a vibrant 2D vector rocket launching upward with
/// glowing flames, booster fins, and exhaust smoke clouds matching reference art.
class _RocketLaunchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. Smoke clouds at the bottom
    final smokePaint = Paint()
      ..color = const Color(0xFFA78BFA).withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 38, cy + 68), 24, smokePaint);
    canvas.drawCircle(Offset(cx + 38, cy + 68), 24, smokePaint);
    canvas.drawCircle(Offset(cx - 18, cy + 76), 28, smokePaint);
    canvas.drawCircle(Offset(cx + 18, cy + 76), 28, smokePaint);
    canvas.drawCircle(Offset(cx, cy + 82), 22, smokePaint);

    final innerSmokePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 12, cy + 70), 16, innerSmokePaint);
    canvas.drawCircle(Offset(cx + 12, cy + 70), 16, innerSmokePaint);

    // 2. Exhaust Flames (Layered outer orange / yellow / bright white)
    final outerFlamePath = Path()
      ..moveTo(cx - 18, cy + 40)
      ..quadraticBezierTo(cx - 24, cy + 65, cx, cy + 88)
      ..quadraticBezierTo(cx + 24, cy + 65, cx + 18, cy + 40)
      ..close();
    final outerFlamePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF8A00), Color(0xFFFF3D00)],
      ).createShader(Rect.fromLTWH(cx - 24, cy + 40, 48, 48));
    canvas.drawPath(outerFlamePath, outerFlamePaint);

    final innerFlamePath = Path()
      ..moveTo(cx - 10, cy + 40)
      ..quadraticBezierTo(cx - 14, cy + 55, cx, cy + 72)
      ..quadraticBezierTo(cx + 14, cy + 55, cx + 10, cy + 40)
      ..close();
    final innerFlamePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFFFD54F)],
      ).createShader(Rect.fromLTWH(cx - 14, cy + 40, 28, 32));
    canvas.drawPath(innerFlamePath, innerFlamePaint);

    // 3. Rocket Body & Fins
    // Left Fin
    final leftFinPath = Path()
      ..moveTo(cx - 28, cy + 20)
      ..lineTo(cx - 52, cy + 44)
      ..lineTo(cx - 26, cy + 40)
      ..close();
    final finPaint = Paint()
      ..color = const Color(0xFF6D28D9)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftFinPath, finPaint);

    // Right Fin
    final rightFinPath = Path()
      ..moveTo(cx + 28, cy + 20)
      ..lineTo(cx + 52, cy + 44)
      ..lineTo(cx + 26, cy + 40)
      ..close();
    canvas.drawPath(rightFinPath, finPaint);

    // Rocket Nozzle Base
    final nozzlePath = Path()
      ..moveTo(cx - 16, cy + 34)
      ..lineTo(cx - 20, cy + 42)
      ..lineTo(cx + 20, cy + 42)
      ..lineTo(cx + 16, cy + 34)
      ..close();
    final nozzlePaint = Paint()..color = const Color(0xFF4C1D95);
    canvas.drawPath(nozzlePath, nozzlePaint);

    // Rocket Main Fuselage (Tapered oval shape)
    final bodyPath = Path()
      ..moveTo(cx, cy - 72) // Nose tip
      ..cubicTo(cx + 36, cy - 25, cx + 34, cy + 28, cx + 24, cy + 36)
      ..lineTo(cx - 24, cy + 36)
      ..cubicTo(cx - 34, cy + 28, cx - 36, cy - 25, cx, cy - 72)
      ..close();

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFEDE9FE), Colors.white, Color(0xFFDDD6FE)],
      ).createShader(Rect.fromLTWH(cx - 36, cy - 72, 72, 108));
    canvas.drawPath(bodyPath, bodyPaint);

    // Nose Cone (Red/Purple tip)
    final nosePath = Path()
      ..moveTo(cx, cy - 72)
      ..cubicTo(cx + 18, cy - 48, cx + 22, cy - 36, cx + 24, cy - 28)
      ..lineTo(cx - 24, cy - 28)
      ..cubicTo(cx - 22, cy - 36, cx - 18, cy - 48, cx, cy - 72)
      ..close();
    final nosePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      ).createShader(Rect.fromLTWH(cx - 24, cy - 72, 48, 44));
    canvas.drawPath(nosePath, nosePaint);

    // Cockpit Porthole Window
    final windowOuterPaint = Paint()..color = const Color(0xFF7C3AED);
    canvas.drawCircle(Offset(cx, cy - 4), 16, windowOuterPaint);

    final windowInnerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
      ).createShader(Rect.fromLTWH(cx - 12, cy - 16, 24, 24));
    canvas.drawCircle(Offset(cx, cy - 4), 12, windowInnerPaint);

    // Window Glare Reflection
    final glarePaint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 4, cy - 8), 3.5, glarePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Starfield backdrop painter for ambient galactic feel
class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white.withOpacity(0.45);
    final glowStarPaint = Paint()..color = const Color(0xFFA78BFA).withOpacity(0.65);

    // Deterministic star coordinates
    final stars = [
      Offset(size.width * 0.12, size.height * 0.15),
      Offset(size.width * 0.82, size.height * 0.12),
      Offset(size.width * 0.25, size.height * 0.28),
      Offset(size.width * 0.88, size.height * 0.32),
      Offset(size.width * 0.08, size.height * 0.45),
      Offset(size.width * 0.92, size.height * 0.58),
      Offset(size.width * 0.18, size.height * 0.72),
      Offset(size.width * 0.84, size.height * 0.80),
      Offset(size.width * 0.45, size.height * 0.08),
      Offset(size.width * 0.65, size.height * 0.22),
    ];

    for (int i = 0; i < stars.length; i++) {
      final s = stars[i];
      if (i % 2 == 0) {
        canvas.drawCircle(s, 1.8, starPaint);
      } else {
        canvas.drawCircle(s, 2.4, glowStarPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
