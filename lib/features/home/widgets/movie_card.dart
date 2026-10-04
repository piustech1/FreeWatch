import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/mock/mock_movies.dart';
import '../../../data/models/movie.dart';
import '../../../data/models/vj.dart';
import '../../../shared/widgets/shimmer_loading.dart';

/// Portrait movie poster card with 20px rounded corners, top-right VJ pill,
/// and modern movie title, star rating, and release year underneath.
class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final double width;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.width = 130,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (width.isFinite && width > 0)
            ? width
            : (constraints.maxWidth.isFinite ? constraints.maxWidth : 130.0);
        final posterHeight = cardWidth * 1.38;

        final posterUrl = movie.posterPath != null
            ? (movie.posterPath!.startsWith('http')
                ? movie.posterPath!
                : '${ApiConstants.posterW500}${movie.posterPath}')
            : null;

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: cardWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 1. Poster with 20px Corner Radius & Top-Right VJ Pill ──
                SizedBox(
                  width: cardWidth,
                  height: posterHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        posterUrl != null
                            ? CachedNetworkImage(
                                imageUrl: posterUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => MovieCardShimmer(
                                  width: cardWidth,
                                  height: posterHeight,
                                ),
                                errorWidget: (_, __, ___) => _PlaceholderPoster(
                                  width: cardWidth,
                                  height: posterHeight,
                                  title: movie.title,
                                ),
                              )
                            : _PlaceholderPoster(
                                width: cardWidth,
                                height: posterHeight,
                                title: movie.title,
                              ),

                        // Top-Right Purple VJ Badge Pill
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _buildVjBadge(movie),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                // ── 2. Movie Title ──────────────────────────────────────────
                Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),

                const SizedBox(height: 3),

                // ── 3. Modern Star Rating & Release Year Row ────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB800),
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      movie.ratingDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '•',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      movie.year.isNotEmpty ? movie.year : '2024',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.60),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVjBadge(Movie movie) {
    final Vj vj = MockData.vjs.firstWhere(
      (v) => v.translatedMovieIds.contains(movie.id),
      orElse: () => MockData.vjs[(movie.id.abs()) % MockData.vjs.length],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFA78BFA).withOpacity(0.50),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]),
                child: Image.asset(
                  vj.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.mic,
                    size: 9,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3.5),
          Text(
            vj.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderPoster extends StatelessWidget {
  final double width;
  final double height;
  final String title;

  const _PlaceholderPoster({
    required this.width,
    required this.height,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceLight,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
