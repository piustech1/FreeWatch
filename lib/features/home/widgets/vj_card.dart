import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/vj.dart';

/// Horizontally scrolling rectangular card featuring a full background image
/// with a bottom-corner gradient forming a triangular shape to display the VJ's name.
class VjCard extends StatelessWidget {
  final Vj vj;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const VjCard({
    super.key,
    required this.vj,
    this.onTap,
    this.width = 180,
    this.height = 105,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.65),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. Full Background Image (Black & White Filtered) ────────
              _buildVjImage(),

              // ── 2. Subtle Overall Ambient Dark Vignette ───────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                    ],
                  ),
                ),
              ),

              // ── 3. Bottom-Corner Triangular Gradient Overlay ──────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _TriangularGradientPainter(),
                ),
              ),

              // ── 4. Top-Left "VJ" Badge ─────────────────────────────────────
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'TRANSLATED',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 5. Bottom-Right Triangular Content (Outstanding VJ Name) ───
              Positioned(
                right: 10,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Outstanding Stylized VJ Name
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFF00E676),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: Text(
                        vj.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.9,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Specialty / Count Tag
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.headset_mic_rounded,
                          color: AppColors.accent,
                          size: 11,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${vj.movieCount} Movies',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildVjImage() {
    final bool isNetwork = vj.imageUrl.startsWith('http');
    final Widget rawImage = isNetwork
        ? CachedNetworkImage(
            imageUrl: vj.imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: const Color(0xFF14161E),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
              ),
            ),
            errorWidget: (_, __, ___) => _fallbackPlaceholder(),
          )
        : Image.asset(
            vj.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackPlaceholder(),
          );

    // Apply high-contrast black & white grayscale matrix as requested by user
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      1, 0,
      ]),
      child: rawImage,
    );
  }

  Widget _fallbackPlaceholder() {
    return Container(
      color: const Color(0xFF14161E),
      child: const Center(
        child: Icon(
          Icons.movie_creation_rounded,
          color: AppColors.textHint,
          size: 28,
        ),
      ),
    );
  }
}

/// Custom painter that draws a seamless triangular bottom-corner gradient section
/// without any harsh outline or border, allowing the VJ name to be crisply legible.
class _TriangularGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ── Triangular Path for bottom-right corner ──
    final path = Path();
    path.moveTo(size.width * 0.15, size.height); // Start on bottom edge
    path.lineTo(size.width, size.height); // Bottom-right corner
    path.lineTo(size.width, 0); // Top-right corner
    path.close();

    // Soft feathered gradient fill inside the triangle with zero border
    const gradient = LinearGradient(
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
      colors: [
        Color(0xFF000000),
        Color(0xFA000000),
        Color(0xD9000000),
        Color(0x00000000),
      ],
      stops: [0.0, 0.45, 0.75, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
