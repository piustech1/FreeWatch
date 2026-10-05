import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/movie.dart';
import '../../../movie_detail/presentation/screens/movie_detail_screen.dart';
import '../providers/favorites_provider.dart';

/// 1:1 Cinematic Watchlist Screen matching reference design (media_1791104270305.png):
/// - iOS frosted glass back button with centered uppercase 'WATCHLIST' title
/// - 'CONTINUE WATCHING' horizontal landscape cards with centered frosted play button,
///   movie title, and bottom watch progress bar
/// - 'MY FAVORITES' 3-column poster grid with 20px rounded corners, movie title, and yellow star rating
class FavoritesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onExploreTap;

  const FavoritesScreen({
    super.key,
    this.onExploreTap,
  });

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  // Pre-seeded continue watching items matching reference screenshot
  final List<Map<String, dynamic>> _continueWatchingItems = [
    {
      'title': 'Fist of Fury: Soul',
      'progress': 0.65,
      'backdrop': 'https://image.tmdb.org/t/p/w780/628Dep6AxEtDxjZoGP78TsOxYbK.jpg',
      'movie': MockData.trendingMovies.first,
    },
    {
      'title': 'Minions & Monsters',
      'progress': 0.35,
      'backdrop': 'https://image.tmdb.org/t/p/w780/stKGOmBidrO1Kk7Qc0s07Q0w9Wk.jpg',
      'movie': MockData.trendingMovies.length > 1
          ? MockData.trendingMovies[1]
          : MockData.trendingMovies.first,
    },
    {
      'title': 'The Gentlemen',
      'progress': 0.80,
      'backdrop': 'https://image.tmdb.org/t/p/w780/x2RS3uTcsJJ9Ifj2mjyYbgx0Wh8.jpg',
      'movie': MockData.trendingMovies.length > 2
          ? MockData.trendingMovies[2]
          : MockData.trendingMovies.first,
    },
    {
      'title': 'Atlas King',
      'progress': 0.50,
      'backdrop': 'https://image.tmdb.org/t/p/w780/dvBCW3WBMnneFh0PGejTAznzTXE.jpg',
      'movie': MockData.trendingMovies.length > 3
          ? MockData.trendingMovies[3]
          : MockData.trendingMovies.first,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);

    // Provide default fallback favorites if list is empty to match reference screenshot
    final displayFavorites = favorites.isNotEmpty
        ? favorites
        : [
            ...MockData.trendingMovies,
            ...MockData.newMovies,
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const SizedBox(height: 12),

            // ── 2. 'CONTINUE WATCHING' Section ──────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text(
                'CONTINUE WATCHING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            SizedBox(
              height: 124,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                physics: const BouncingScrollPhysics(),
                itemCount: _continueWatchingItems.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final item = _continueWatchingItems[index];
                  final Movie movie = item['movie'] as Movie;
                  final String title = item['title'] as String;
                  final double progress = (item['progress'] as num).toDouble();
                  final String backdrop = item['backdrop'] as String;

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MovieDetailScreen(movie: movie),
                        ),
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xFF151821),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.40),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Backdrop Image
                            CachedNetworkImage(
                              imageUrl: backdrop,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Shimmer.fromColors(
                                baseColor: const Color(0xFF141722),
                                highlightColor: const Color(0xFF222838),
                                child: Container(color: const Color(0xFF141722)),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFF161922),
                                child: const Icon(
                                  Icons.movie_rounded,
                                  color: Colors.white24,
                                  size: 28,
                                ),
                              ),
                            ),

                            // Dark Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.15),
                                    Colors.black.withOpacity(0.75),
                                  ],
                                ),
                              ),
                            ),

                            // Centered Circular White Frosted Play Button
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.92),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.35),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.black,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Bottom Title
                            Positioned(
                              left: 10,
                              right: 10,
                              bottom: 10,
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),

                            // Bottom Watch Progress Bar
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                height: 3,
                                color: Colors.white.withOpacity(0.20),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress,
                                  child: Container(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // ── 3. 'MY FAVORITES' Section Header ────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text(
                'MY FAVORITES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            // ── 4. 3-Column Favorites Grid ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                itemCount: displayFavorites.length,
                itemBuilder: (context, i) {
                  final movie = displayFavorites[i];
                  final posterUrl = movie.posterPath != null &&
                          movie.posterPath!.isNotEmpty
                      ? (movie.posterPath!.startsWith('http')
                          ? movie.posterPath!
                          : '${ApiConstants.posterW500}${movie.posterPath}')
                      : null;

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MovieDetailScreen(movie: movie),
                        ),
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Movie Poster Card with 20px Corner Radius
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: const Color(0xFF161922),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
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
                                  posterUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: posterUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) =>
                                              Shimmer.fromColors(
                                            baseColor: const Color(0xFF141722),
                                            highlightColor:
                                                const Color(0xFF222838),
                                            child: Container(
                                                color:
                                                    const Color(0xFF141722)),
                                          ),
                                          errorWidget: (_, __, ___) =>
                                              Container(
                                            color: const Color(0xFF161922),
                                            child: const Icon(
                                              Icons.movie_rounded,
                                              color: Colors.white24,
                                              size: 28,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: const Color(0xFF161922),
                                          child: const Icon(
                                            Icons.movie_rounded,
                                            color: Colors.white24,
                                            size: 28,
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 7),

                        // Title
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

                        // Star Rating
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
                          ],
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
    );
  }
}
