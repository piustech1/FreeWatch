import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/movie.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import 'movie_card.dart';

/// A labelled horizontal scrollable row of movies with "See all" action
class MovieSection extends StatelessWidget {
  final String title;
  final List<Movie>? movies;
  final bool isLoading;
  final VoidCallback? onSeeAll;
  final void Function(Movie movie)? onMovieTap;
  final IconData? icon;
  final Color? iconColor;

  const MovieSection({
    super.key,
    required this.title,
    this.movies,
    this.isLoading = false,
    this.onSeeAll,
    this.onMovieTap,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = iconColor ?? AppColors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: effectiveColor.withOpacity(0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: effectiveColor.withOpacity(0.35),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: effectiveColor.withOpacity(0.20),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            size: 16,
                            color: effectiveColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onSeeAll,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.10),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Movie list ─────────────────────────────────────────────────────
        SizedBox(
          height: 232,
          child: isLoading
              ? const MovieRowShimmer()
              : (movies == null || movies!.isEmpty)
                  ? const _EmptyRow()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      physics: const BouncingScrollPhysics(),
                      itemCount: movies!.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) => MovieCard(
                        movie: movies![index],
                        onTap: () => onMovieTap?.call(movies![index]),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No movies available',
        style: TextStyle(color: AppColors.textHint),
      ),
    );
  }
}
