import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/vj.dart';

/// Mechanical puzzle-piece cutout for the main solid gradient block.
/// Shifted to ensure the left portrait/face is fully revealed and not cut off.
class VjMainClipper extends CustomClipper<Path> {
  const VjMainClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    // Polygon giving left face ample room:
    path.moveTo(w * 0.48, 0);
    path.lineTo(w, 0);
    path.lineTo(w, h);
    path.lineTo(w * 0.52, h);
    path.lineTo(w * 0.52, h * 0.70);
    path.lineTo(w * 0.35, h * 0.30);
    path.lineTo(w * 0.48, h * 0.30);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Accent shape shifted left by 2% to create the uniform vibrant slice.
class VjAccentClipper extends CustomClipper<Path> {
  const VjAccentClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.46, 0);
    path.lineTo(w, 0);
    path.lineTo(w, h);
    path.lineTo(w * 0.50, h);
    path.lineTo(w * 0.50, h * 0.70);
    path.lineTo(w * 0.33, h * 0.30);
    path.lineTo(w * 0.46, h * 0.30);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Palette configurations matching the interlocking panoramic HTML design
class VjCardTheme {
  final Color accentColor;
  final Color gradientStart;
  final Color gradientEnd;
  final Color subtitleColor;
  final Color shadowColor;

  const VjCardTheme({
    required this.accentColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.subtitleColor,
    required this.shadowColor,
  });

  // VJ Junior (Pink / Deep Purple)
  static const pinkPurple = VjCardTheme(
    accentColor: Color(0xFFEC4899),
    gradientStart: Color(0xFF581C87),
    gradientEnd: Color(0xFF3B0764),
    subtitleColor: Color(0xFFD8B4FE),
    shadowColor: Color(0x66581C87),
  );

  // VJ Emmy (Sky Blue / Deep Navy)
  static const skyNavy = VjCardTheme(
    accentColor: Color(0xFF0EA5E9),
    gradientStart: Color(0xFF1E3A8A),
    gradientEnd: Color(0xFF0F172A),
    subtitleColor: Color(0xFF93C5FD),
    shadowColor: Color(0x661E3A8A),
  );

  // VJ Jingo (Amber / Deep Rust)
  static const amberRust = VjCardTheme(
    accentColor: Color(0xFFF59E0B),
    gradientStart: Color(0xFF9A3412),
    gradientEnd: Color(0xFF431407),
    subtitleColor: Color(0xFFFDBA74),
    shadowColor: Color(0x669A3412),
  );

  // VJ Ice P (Emerald / Forest Green)
  static const emeraldForest = VjCardTheme(
    accentColor: Color(0xFF10B981),
    gradientStart: Color(0xFF065F46),
    gradientEnd: Color(0xFF022C22),
    subtitleColor: Color(0xFF6EE7B7),
    shadowColor: Color(0x66065F46),
  );

  // VJ Uncle T (Violet / Deep Indigo)
  static const violetDeep = VjCardTheme(
    accentColor: Color(0xFF8B5CF6),
    gradientStart: Color(0xFF4C1D95),
    gradientEnd: Color(0xFF2E1065),
    subtitleColor: Color(0xFFC4B5FD),
    shadowColor: Color(0x664C1D95),
  );

  // VJ Heavy Q (Rose / Dark Wine)
  static const roseWine = VjCardTheme(
    accentColor: Color(0xFFF43F5E),
    gradientStart: Color(0xFF881337),
    gradientEnd: Color(0xFF4C0519),
    subtitleColor: Color(0xFFFDA4AF),
    shadowColor: Color(0x66881337),
  );

  static const List<VjCardTheme> palette = [
    pinkPurple,
    skyNavy,
    amberRust,
    emeraldForest,
    violetDeep,
    roseWine,
  ];

  static VjCardTheme resolve(Vj vj, [int? index]) {
    final lower = vj.name.toLowerCase();
    if (lower.contains('junior')) return pinkPurple;
    if (lower.contains('emmy')) return skyNavy;
    if (lower.contains('jingo')) return amberRust;
    if (lower.contains('ice')) return emeraldForest;
    if (lower.contains('uncle')) return violetDeep;
    if (lower.contains('heavy')) return roseWine;

    if (index != null && index >= 0) {
      return palette[index % palette.length];
    }
    return palette[vj.name.hashCode.abs() % palette.length];
  }
}

/// Compact Available VJ interlocking card with left-aligned face visibility.
class VjCard extends StatefulWidget {
  final Vj vj;
  final VoidCallback? onTap;
  final int? index;
  final double width;
  final double height;

  const VjCard({
    super.key,
    required this.vj,
    this.onTap,
    this.index,
    this.width = 235,
    this.height = 105,
  });

  @override
  State<VjCard> createState() => _VjCardState();
}

class _VjCardState extends State<VjCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = VjCardTheme.resolve(widget.vj, widget.index);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeInOut,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF111111),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor,
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: -3,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.50),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── 1. Base Layer: Grayscale Portrait Anchored to Left ──────
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: widget.width * 0.54,
                  child: _buildVjImage(),
                ),

                // ── 2. Dark Feathered Gradient on Left edge ─────────────────
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: widget.width * 0.35,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.50),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── 3. Vibrant Accent Slice (ClipPath shifted 2% left) ──────
                Positioned.fill(
                  child: ClipPath(
                    clipper: const VjAccentClipper(),
                    child: Container(
                      color: theme.accentColor,
                    ),
                  ),
                ),

                // ── 4. Main Solid Text Block (Deep Gradient on ClipPath) ────
                Positioned.fill(
                  child: ClipPath(
                    clipper: const VjMainClipper(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.gradientStart,
                            theme.gradientEnd,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 5. Typography Container (Anchored to Right 52%) ──────────
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: widget.width * 0.52,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14, left: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.vj.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16.5,
                            letterSpacing: -0.3,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.vj.movieCount} movies',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: theme.subtitleColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                            letterSpacing: 0.1,
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
      ),
    );
  }

  Widget _buildVjImage() {
    final bool isNetwork = widget.vj.imageUrl.startsWith('http');
    final Widget rawImage = isNetwork
        ? CachedNetworkImage(
            imageUrl: widget.vj.imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft, // Left aligned so face is clearly visible
            placeholder: (_, __) => Container(
              color: const Color(0xFF14161E),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
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
            widget.vj.imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft, // Left aligned so face is clearly visible
            errorBuilder: (_, __, ___) => _fallbackPlaceholder(),
          );

    // Apply high-contrast black & white grayscale matrix
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      0.95, 0,
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
          size: 24,
        ),
      ),
    );
  }
}
