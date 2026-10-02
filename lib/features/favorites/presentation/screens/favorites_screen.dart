import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/movie.dart';
import '../../../home/widgets/movie_card.dart';
import '../../../movie_detail/presentation/screens/movie_detail_screen.dart';
import '../providers/favorites_provider.dart';

/// Dedicated full-screen Favorites / Watchlist screen
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
  String _selectedFilter = 'All';
  String _sortBy = 'Recent';

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);

    // Apply category filter
    var filtered = favorites.where((m) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Movies') return true;
      if (_selectedFilter == 'Series') {
        return m.id == 1125510 || m.title.contains('House');
      }
      if (_selectedFilter == 'VJ Translated') {
        return MockData.vjs.any((v) => v.translatedMovieIds.contains(m.id));
      }
      return true;
    }).toList();

    // Apply sorting
    if (_sortBy == 'Rating') {
      filtered.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    } else if (_sortBy == 'Title') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'My Watchlist',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${favorites.length}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Sort Menu
                  PopupMenuButton<String>(
                    onSelected: (val) => setState(() => _sortBy = val),
                    color: const Color(0xFF181C26),
                    icon: const Icon(
                      IconlyLight.filter,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'Recent',
                        child: Text('Recently Added',
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                      const PopupMenuItem(
                        value: 'Rating',
                        child: Text('Top Rated',
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                      const PopupMenuItem(
                        value: 'Title',
                        child: Text('Alphabetical (A-Z)',
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Filter Chips ────────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                children: ['All', 'Movies', 'Series', 'VJ Translated'].map((f) {
                  final isSelected = _selectedFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : const Color(0xFF151821),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // ── Main Content Area ──────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(context)
                  : _buildFavoritesGrid(filtered),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF151821),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: const Icon(
                IconlyLight.heart,
                color: AppColors.textHint,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your Watchlist is Empty',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the heart icon on any movie or series to save it here for instant streaming anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.onExploreTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Explore Movies',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grid of Saved Titles ──────────────────────────────────────────────────
  Widget _buildFavoritesGrid(List<Movie> movies) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemCount: movies.length,
      itemBuilder: (context, i) {
        final movie = movies[i];
        return Stack(
          children: [
            MovieCard(
              movie: movie,
              width: double.infinity,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MovieDetailScreen(movie: movie),
                  ),
                );
              },
            ),
            // Quick Remove Button
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () {
                  ref
                      .read(favoritesProvider.notifier)
                      .removeFavorite(movie.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 900),
                      backgroundColor: const Color(0xFF1E2130),
                      content: Text('Removed ${movie.title} from Watchlist',
                          style: const TextStyle(color: Colors.white)),
                    ),
                  );
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white24,
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
