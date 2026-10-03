import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/vj.dart';

/// Horizontally scrolling rectangular card featuring a full background image
/// prioritized at the top (topCenter alignment), a thin elegant bottom gradient,
/// and pure white VJ name typography with zero outlines.
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
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. Full Background Image (Top Prioritized & Black/White) ──
              _buildVjImage(),

              // ── 2. Thin Feathered Bottom Gradient Matching UI ─────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: height * 0.58,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.92),
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              // ── 3. Bottom Inline Purple Translucent Card (Name • Count) ───
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.55),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFA78BFA).withOpacity(0.40),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          vj.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '•',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${vj.movieCount} movies',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
            alignment: Alignment.topCenter, // Prioritize top part of VJ image
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
            alignment: Alignment.topCenter, // Prioritize top part of VJ image
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
