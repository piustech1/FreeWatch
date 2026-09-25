import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/movie.dart';

/// Auto-scrolling hero banner matching the design screenshot
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

  List<Movie> get _bannerMovies => widget.movies.take(5).toList();

  @override
  void initState() {
    super.initState();
    _controller = PageController();
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
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
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
        // ── Banner Carousel ────────────────────────────────────────────────
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            itemCount: _bannerMovies.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final movie = _bannerMovies[index];
              return _HeroCardItem(
                movie: movie,
                onTap: () => widget.onTap?.call(movie),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // ── Pagination Dots & "See all" Row ───────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SmoothPageIndicator(
                controller: _controller,
                count: _bannerMovies.length,
                effect: const ExpandingDotsEffect(
                  dotWidth: 6,
                  dotHeight: 6,
                  activeDotColor: AppColors.textPrimary,
                  dotColor: Color(0xFF323644),
                  expansionFactor: 3.5,
                  spacing: 6,
                ),
              ),
              GestureDetector(
                onTap: widget.onSeeAll,
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCardItem extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;

  const _HeroCardItem({required this.movie, this.onTap});

  @override
  Widget build(BuildContext context) {
    final backdropUrl = movie.backdropPath != null
        ? (movie.backdropPath!.startsWith('http')
            ? movie.backdropPath!
            : '${ApiConstants.backdropW780}${movie.backdropPath}')
        : null;

    final isBeekeeper = movie.title.toLowerCase().contains('beekeeper');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            color: const Color(0xFF1E1F26),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Backdrop image ─────────────────────────────────────────
                if (backdropUrl != null)
                  CachedNetworkImage(
                    imageUrl: backdropUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.surface),
                    errorWidget: (_, __, ___) => _FallbackHeroVisual(movie: movie),
                  )
                else
                  _FallbackHeroVisual(movie: movie),

                // ── Vignette / Gradient overlays ───────────────────────────
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),

                // ── Hero Title Overlay ──────────────────────────────────────
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isBeekeeper
                              ? const Color(0xFFFFC72C)
                              : AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      if (movie.overview != null && movie.overview!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          movie.overview!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
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
            Color(0xFFE5A00D),
            Color(0xFF5A3906),
            Color(0xFF1B1405),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.movie_creation_rounded,
          color: Colors.white.withOpacity(0.25),
          size: 72,
        ),
      ),
    );
  }
}
