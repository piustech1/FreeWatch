import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/movie.dart';
import '../../../../data/models/vj.dart';
import '../../../home/providers/home_providers.dart';
import '../../../home/widgets/floating_nav_bar.dart';
import '../../../movie_detail/presentation/screens/movie_detail_screen.dart';

/// 1:1 Cinematic 3-Column Movie Grid Screen matching reference design:
/// - Displays when a user clicks any VJ card (branded purple capsule with circular VJ photo & name)
/// - Displays when a user clicks "See All" on any movie section (title e.g. "Fresh Drops", "Drama")
/// - 3-column movie grid with top VJ badge pill, movie poster, and bottom star rating + release year
/// - Persistent floating bottom navigation bar connected to global tab switcher
class MovieGridScreen extends ConsumerWidget {
  final String title;
  final Vj? vj;
  final List<Movie> movies;

  const MovieGridScreen({
    super.key,
    required this.title,
    this.vj,
    required this.movies,
  });

  /// Factory constructor for opening movies translated by a specific VJ
  static MaterialPageRoute routeForVj({required Vj vj}) {
    final movies = MockData.getMoviesByVj(vj.id);
    return MaterialPageRoute(
      builder: (_) => MovieGridScreen(
        title: vj.name,
        vj: vj,
        movies: movies,
      ),
    );
  }

  /// Factory constructor for opening section movies (e.g. "Fresh Drops", "Drama")
  static MaterialPageRoute routeForCategory({
    required String title,
    required List<Movie> movies,
  }) {
    return MaterialPageRoute(
      builder: (_) => MovieGridScreen(
        title: title,
        vj: null,
        movies: movies,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNavIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // ── Top Header / App Bar ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // White circular back button matching reference design
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      // Center Title: Branded VJ purple capsule or bold section title
                      if (vj != null)
                        _buildBrandedVjCapsule(vj!)
                      else
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),

                      // Right spacer to keep center title symmetrically aligned
                      const SizedBox(width: 36),
                    ],
                  ),
                ),

                // ── 3-Column Movie Grid ───────────────────────────────────────
                Expanded(
                  child: movies.isEmpty
                      ? const Center(
                          child: Text(
                            'No movies found',
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        )
                      : GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.52,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: movies.length,
                          itemBuilder: (context, index) {
                            final movie = movies[index];
                            final vjName = vj?.name ??
                                _resolveVjNameForMovie(movie, index);
                            return _buildMovieCard(context, movie, vjName);
                          },
                        ),
                ),
              ],
            ),

            // ── Floating Bottom Navigation Pill ──────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingNavBar(
                selectedIndex: currentNavIndex,
                onItemSelected: (index) {
                  navigateToBottomNavTab(context, ref, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Branded Purple VJ Title Capsule ────────────────────────────────────────
  Widget _buildBrandedVjCapsule(Vj currentVj) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFA78BFA).withOpacity(0.40),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.20),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF221834),
                ),
                child: ClipOval(
                  child: currentVj.imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: currentVj.imageUrl,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          currentVj.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.record_voice_over_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currentVj.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 3-Column Movie Card with Top VJ Badge & Bottom Rating/Year ─────────────
  Widget _buildMovieCard(BuildContext context, Movie movie, String vjName) {
    final posterUrl = movie.posterPath != null && movie.posterPath!.isNotEmpty
        ? (movie.posterPath!.startsWith('http')
            ? movie.posterPath!
            : '${ApiConstants.posterW342}${movie.posterPath}')
        : null;

    final ratingDisplay =
        movie.voteAverage > 0 ? movie.voteAverage.toStringAsFixed(1) : '7.5';
    final releaseYear = movie.year.isNotEmpty ? movie.year : '2024';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MovieDetailScreen(movie: movie),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie Poster with rounded corners & top VJ pill
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF161922),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.38),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Poster image with shimmer loader
                    posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: posterUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Shimmer.fromColors(
                              baseColor: const Color(0xFF141722),
                              highlightColor: const Color(0xFF222838),
                              child: Container(color: const Color(0xFF141722)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF161922),
                              child: const Icon(Icons.movie_rounded,
                                  color: Colors.white24, size: 28),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF161922),
                            child: const Icon(Icons.movie_rounded,
                                color: Colors.white24, size: 28),
                          ),

                    // Top-Right Purple VJ Badge Card
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Builder(
                        builder: (context) {
                          final resolvedVj = MockData.vjs.firstWhere(
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
                                  width: 13,
                                  height: 13,
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
                                        resolvedVj.imageUrl,
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
                                const SizedBox(width: 3),
                                Text(
                                  resolvedVj.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Rating + Release Year row (e.g. ⭐ 7.9  2024)
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFB800),
                size: 15,
              ),
              const SizedBox(width: 3),
              Text(
                ratingDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                releaseYear,
                style: const TextStyle(
                  color: Color(0xFF8E929E),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _resolveVjNameForMovie(Movie movie, int index) {
    try {
      final found = MockData.vjs.firstWhere(
        (v) => v.translatedMovieIds.contains(movie.id),
      );
      return found.name;
    } catch (_) {
      const fallbackVjs = MockData.vjs;
      if (fallbackVjs.isNotEmpty) {
        return fallbackVjs[index % fallbackVjs.length].name;
      }
      return 'VJ Junior';
    }
  }
}
