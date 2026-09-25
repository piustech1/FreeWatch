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

  const MovieSection({
    super.key,
    required this.title,
    this.movies,
    this.isLoading = false,
    this.onSeeAll,
    this.onMovieTap,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: onSeeAll,
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

        // ── Movie list ─────────────────────────────────────────────────────
        SizedBox(
          height: 248,
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
