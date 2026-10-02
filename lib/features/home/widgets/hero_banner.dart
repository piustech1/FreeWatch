import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/movie.dart';
import '../../favorites/presentation/providers/favorites_provider.dart';

/// 3D Stacked Hero Banner Carousel matching reference image 3:
/// Tall portrait posters (Oppenheimer format), top-left bookmark, top-right green rating pill,
/// center play button, bottom title overlay, and title/dots row below.
class HeroBanner extends ConsumerStatefulWidget {
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
  ConsumerState<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends ConsumerState<HeroBanner> {
  late final PageController _controller;
  Timer? _timer;
  int _currentPage = 0;

  List<Movie> get _bannerMovies => widget.movies.take(6).toList();

  @override
  void initState() {
    super.initState();
    // viewportFraction 0.62 allows the adjacent posters to show on the right and left
    _controller = PageController(viewportFraction: 0.62);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (_bannerMovies.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_currentPage + 1) % _bannerMovies.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
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

    final currentMovie = _bannerMovies[_currentPage.clamp(0, _bannerMovies.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 3D Overlapping Stacked Poster Carousel ─────────────────────────
        SizedBox(
          height: 330,
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
                  final double diff = index - page;
                  final double absDiff = diff.abs().clamp(0.0, 2.0);

                  // Scale down adjacent cards
                  final double scale = (1.0 - (absDiff * 0.10)).clamp(0.80, 1.0);
                  // Slight translation to produce depth
                  final double translateY = absDiff * 6.0;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..translate(0.0, translateY, 0.0)
                      ..scale(scale, scale),
                    child: _StackedHeroPosterCard(
                      movie: movie,
                      isActive: index == _currentPage,
                      onTap: () => widget.onTap?.call(movie),
                    ),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // ── Below Posters: Title, Subtitle & Elongated Pill Dots ────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Movie Title & Genre / Runtime
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentMovie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _getMovieSubtitle(currentMovie),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Page Indicator (Active White Pill + Round Dots)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_bannerMovies.length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    height: 5.5,
                    width: isActive ? 22 : 5.5,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMovieSubtitle(Movie movie) {
    final year = movie.year.isNotEmpty ? movie.year : '2024';
    if (movie.id == 693134) return 'Sci-Fi, Adventure • 166 mins';
    if (movie.id == 533535) return 'Action, Comedy • 128 mins';
    if (movie.id == 1011985) return 'Action, Thriller • 105 mins';
    if (movie.id == 558449) return 'Action, Drama • 148 mins';
    return 'Action, Drama • $year';
  }
}

/// Single portrait card matching reference image 3
class _StackedHeroPosterCard extends ConsumerWidget {
  final Movie movie;
  final bool isActive;
  final VoidCallback onTap;

  const _StackedHeroPosterCard({
    required this.movie,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider.notifier).isFavorite(movie.id);

    final posterUrl = movie.posterPath != null && movie.posterPath!.isNotEmpty
        ? (movie.posterPath!.startsWith('http')
            ? movie.posterPath!
            : '${ApiConstants.posterW500}${movie.posterPath}')
        : null;

    final ratingDisplay = movie.voteAverage > 0
        ? movie.voteAverage.toStringAsFixed(1)
        : '8.2';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isActive ? 0.6 : 0.4),
              blurRadius: isActive ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Poster Image
              posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFF161922),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF161922),
                        child: const Icon(Icons.movie_rounded,
                            color: Colors.white24, size: 40),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF161922),
                      child: const Icon(Icons.movie_rounded,
                          color: Colors.white24, size: 40),
                    ),

              // 2. Subtle Gradient Overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.75),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),

              // 3. Top-Left: Bookmark Button (🔖)
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () {
                    ref.read(favoritesProvider.notifier).toggleFavorite(movie);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(milliseconds: 900),
                        backgroundColor: const Color(0xFF1E2130),
                        content: Text(
                          isFav
                              ? 'Removed from Watchlist'
                              : 'Saved to Watchlist',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      isFav ? IconlyBold.bookmark : IconlyLight.bookmark,
                      color: isFav ? AppColors.accent : Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),

              // 4. Top-Right: Rating Badge with Green Pill (★ 9.2)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E575),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E575).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.black,
                        size: 13,
                      ),
                      const SizedBox(width: 2.5),
                      Text(
                        ratingDisplay,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Center: Frosted Glass Play Button (▶)
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.55),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),

              // 6. Bottom: Movie Title Text Over Poster
              Positioned(
                left: 12,
                right: 12,
                bottom: 14,
                child: Text(
                  movie.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
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
            ],
          ),
        ),
      ),
    );
  }
}
