import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/movie.dart';
import '../../../shared/widgets/shimmer_loading.dart';

/// Portrait movie poster card matching the design screenshot
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
    final posterUrl = movie.posterPath != null
        ? (movie.posterPath!.startsWith('http')
            ? movie.posterPath!
            : '${ApiConstants.posterW500}${movie.posterPath}')
        : null;

    final posterHeight = width * 1.48;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Poster ──────────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: width,
                height: posterHeight,
                child: posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => MovieCardShimmer(
                          width: width,
                          height: posterHeight,
                        ),
                        errorWidget: (_, __, ___) => _PlaceholderPoster(
                          width: width,
                          height: posterHeight,
                          title: movie.title,
                        ),
                      )
                    : _PlaceholderPoster(
                        width: width,
                        height: posterHeight,
                        title: movie.title,
                      ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Title ────────────────────────────────────────────────────────
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 3),

            // ── Year & Rating ────────────────────────────────────────────────
            Row(
              children: [
                if (movie.year.isNotEmpty) ...[
                  Text(
                    movie.year,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '•',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.star,
                  size: 14,
                ),
                const SizedBox(width: 2),
                Text(
                  movie.ratingDisplay,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
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
