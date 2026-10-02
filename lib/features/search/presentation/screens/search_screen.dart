import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/movie.dart';
import '../../../home/widgets/movie_card.dart';
import '../../../movie_detail/presentation/screens/movie_detail_screen.dart';

/// Dedicated full-screen Search screen
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Movies',
    'Series',
    'VJ Translated',
    'Action',
    'Sci-Fi',
    'Animation',
    'Horror',
    'Comedy',
  ];

  final List<String> _trendingTags = [
    'Deadpool & Wolverine',
    'VJ Junior Action',
    'Dune: Part Two',
    'Gladiator II',
    'Lilo & Stitch',
    'House of David',
    'Sci-Fi 2025',
    'VJ Emmy Drama',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allMovies = MockData.getAllMovies();

    // Filter results based on search query and category
    final results = allMovies.where((movie) {
      final matchesQuery = _query.isEmpty ||
          movie.title.toLowerCase().contains(_query.toLowerCase()) ||
          (movie.overview != null &&
              movie.overview!.toLowerCase().contains(_query.toLowerCase()));

      if (!matchesQuery) return false;

      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Movies') return true;
      if (_selectedCategory == 'Series') {
        return movie.id == 1125510 || movie.title.contains('House');
      }
      if (_selectedCategory == 'VJ Translated') {
        return MockData.vjs.any((v) => v.translatedMovieIds.contains(movie.id));
      }
      if (_selectedCategory == 'Action') return movie.genreIds.contains(28);
      if (_selectedCategory == 'Sci-Fi') return movie.genreIds.contains(878);
      if (_selectedCategory == 'Animation') return movie.genreIds.contains(16);
      if (_selectedCategory == 'Horror') return movie.genreIds.contains(27);
      if (_selectedCategory == 'Comedy') return movie.genreIds.contains(35);

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Search Input Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF141720),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _query.isNotEmpty
                        ? AppColors.accent.withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _query = val.trim()),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      IconlyBold.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.cancel_rounded,
                              color: AppColors.textHint,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    hintText: 'Search movies, series, or VJs...',
                    hintStyle: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),

            // ── Category Filter Chips ──────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : const Color(0xFF151821),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ── Main Content Area ──────────────────────────────────────────
            Expanded(
              child: _query.isEmpty && _selectedCategory == 'All'
                  ? _buildDefaultExploreView()
                  : _buildResultsView(results),
            ),
          ],
        ),
      ),
    );
  }

  // ── Default View (Trending tags + Categories + Top Searched) ───────────────
  Widget _buildDefaultExploreView() {
    final topPicks = MockData.getAllMovies().take(6).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Trending Searches
        const Text(
          'Trending Searches',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trendingTags.map((tag) {
            return GestureDetector(
              onTap: () {
                _searchController.text = tag;
                setState(() => _query = tag);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF161922),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.north_east_rounded,
                      color: AppColors.accent,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Top Searched Today
        const Text(
          'Top Searched Today',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.58,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
          ),
          itemCount: topPicks.length,
          itemBuilder: (context, i) {
            final movie = topPicks[i];
            return MovieCard(
              movie: movie,
              width: double.infinity,
              onTap: () => _openMovie(movie),
            );
          },
        ),
      ],
    );
  }

  // ── Results View ──────────────────────────────────────────────────────────
  Widget _buildResultsView(List<Movie> results) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF161922),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  IconlyLight.search,
                  color: AppColors.textHint,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Results Found',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We couldn\'t find any match for "$_query". Try checking the spelling or searching another title.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                    _selectedCategory = 'All';
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Reset Search',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
          child: Text(
            'Found ${results.length} ${results.length == 1 ? "title" : "titles"}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.58,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
            ),
            itemCount: results.length,
            itemBuilder: (context, i) {
              final movie = results[i];
              return MovieCard(
                movie: movie,
                width: double.infinity,
                onTap: () => _openMovie(movie),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openMovie(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(movie: movie),
      ),
    );
  }
}
