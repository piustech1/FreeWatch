import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/movie.dart';

/// Compact hero banner carousel matching the reference design layout:
/// reduced height, zero outlines, Watch Now / Download / VJ buttons, and 3D depth.
class HeroBanner extends StatefulWidget {
  final List<Movie> movies;
  final void Function(Movie movie)? onTap;
  final VoidCallback? onSeeAll;

  const HeroBanner({
    super.key,
    required this.movies,
    this.onTap,
    this.onSeeAll,
  });

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  late final PageController _controller;
  Timer? _timer;
  int _currentPage = 0;

  List<Movie> get _bannerMovies => widget.movies.take(6).toList();

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.85);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (_bannerMovies.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_currentPage + 1) % _bannerMovies.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerMovies.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // ── Compact Hero Carousel with 3D Depth & Zero Outlines ────────────
        SizedBox(
          height: 198,
          child: PageView.builder(
            controller: _controller,
            itemCount: _bannerMovies.length,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final movie = _bannerMovies[index];
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double page = _currentPage.toDouble();
                  if (_controller.position.haveDimensions &&
                      _controller.page != null) {
                    page = _controller.page!;
                  }
                  final double diff = (index - page);
                  final double absDiff = diff.abs().clamp(0.0, 1.0);

                  final double scale = 1.0 - (absDiff * 0.10);
                  final double opacity = 1.0 - (absDiff * 0.30);
                  final double translateY = absDiff * 4.0;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..translate(0.0, translateY, 0.0)
                      ..scale(scale, scale),
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: _HeroCardItem(
                        movie: movie,
                        onTap: () => widget.onTap?.call(movie),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // ── Elongated Pill Pagination Indicator ─────────────────────────────
        Center(
          child: SmoothPageIndicator(
            controller: _controller,
            count: _bannerMovies.length,
            effect: const ExpandingDotsEffect(
              dotWidth: 6,
              dotHeight: 6,
              activeDotColor: AppColors.accent,
              dotColor: Color(0xFF2C303B),
              expansionFactor: 3.8,
              spacing: 6,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCardItem extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;

  const _HeroCardItem({
    required this.movie,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backdropUrl = movie.backdropPath != null
        ? (movie.backdropPath!.startsWith('http')
            ? movie.backdropPath!
            : '${ApiConstants.backdropW780}${movie.backdropPath}')
        : null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            // STRICT NO OUTLINE MANDATE: zero border
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.65),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: const Color(0xFF14161F),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Backdrop image ───────────────────────────────────────
                  if (backdropUrl != null)
                    CachedNetworkImage(
                      imageUrl: backdropUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.surface),
                      errorWidget: (_, __, ___) => _FallbackHeroVisual(movie: movie),
                    )
                  else
                    _FallbackHeroVisual(movie: movie),

                  // ── Vignette overlays ─────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.15),
                          Colors.transparent,
                          Colors.black.withOpacity(0.92),
                        ],
                        stops: const [0.0, 0.35, 1.0],
                      ),
                    ),
                  ),

                  // ── Hero Content (Title, Meta & Action Buttons) ───────────
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          movie.title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 5),

                        // Metadata Row: Rating, Year, Duration, ULTRA HD badge
                        Row(
                          children: [
                            const Icon(
                              IconlyBold.star,
                              color: Color(0xFFFFB800),
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              movie.ratingDisplay,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '•',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              movie.year.isNotEmpty ? movie.year : '2024',
                              style: const TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '•',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '2h 10m',
                              style: TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Solid filled ULTRA HD badge with NO outline
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ULTRA HD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Action Buttons Row: WATCH NOW, DOWNLOAD, VJ
                        Row(
                          children: [
                            // 1. WATCH NOW (Primary electric green gradient)
                            Expanded(
                              flex: 5,
                              child: Container(
                                height: 34,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(17),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00E676),
                                      Color(0xFF00B0FF),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E676).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      IconlyBold.play,
                                      color: Color(0xFF000000),
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'WATCH NOW',
                                      style: TextStyle(
                                        color: Color(0xFF000000),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // 2. DOWNLOAD (Solid dark translucent fill, NO outline)
                            Expanded(
                              flex: 5,
                              child: Container(
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0x33FFFFFF),
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      IconlyBold.download,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'DOWNLOAD',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // 3. VJ Button (Solid dark translucent pill, NO outline)
                            Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0x2E00E676),
                                borderRadius: BorderRadius.circular(17),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.headset_mic_rounded,
                                    color: AppColors.accent,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'VJ',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }
}

class _FallbackHeroVisual extends StatelessWidget {
  final Movie movie;

  const _FallbackHeroVisual({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E202B),
            Color(0xFF10121A),
            Color(0xFF08090E),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.movie_creation_rounded,
          color: Colors.white.withOpacity(0.2),
          size: 60,
        ),
      ),
    );
  }
}
