import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/mock/mock_movies.dart';
import '../../../data/models/movie.dart';
import '../../../data/models/vj.dart';
import '../../../shared/widgets/shimmer_loading.dart';

/// Portrait movie poster card with small top-right purple VJ card and no bottom text
class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final double width;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.width = 135,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (width.isFinite && width > 0)
            ? width
            : (constraints.maxWidth.isFinite ? constraints.maxWidth : 135.0);
        final posterHeight = cardWidth * 1.48;

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
            height: posterHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Poster Image ───────────────────────────────────────────
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

                  // ── Top-Right Purple VJ Badge ──────────────────────────────
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _buildVjBadge(movie),
                  ),
                ],
              ),
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
                    size: 10,
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
              letterSpacing: 0.2,
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
  final String? title;

  const _PlaceholderPoster({
    required this.width,
    required this.height,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF252836),
            Color(0xFF161822),
          ],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.movie_filter_rounded,
            color: AppColors.textHint,
            size: 32,
          ),
          if (title != null) ...[
            const SizedBox(height: 8),
            Text(
              title!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
