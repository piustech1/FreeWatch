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
import '../providers/search_providers.dart';

/// 3-Page Series Search Flow matching Reference Image 1:
/// - Screen 1: Categories Landing with folder-tab cards
/// - Screen 2: Search Results / Category Page with sliders filter and grid/list toggle
/// - Screen 3: Expandable Filters Screen with Type radio and accordion sections
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  // Step in the 3-page flow: 1 = Categories, 2 = Results, 3 = Filters
  int _searchStep = 1;

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Adventure';
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _searchController.clear();
    _searchQuery = '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter selections
  String _selectedType = 'Movies';
  String _selectedGenre = 'Adventure';
  String _selectedYear = 'All';
  String _selectedRating = 'All';
  String _selectedQuality = 'All';
  String _selectedSort = 'Popularity';

  // Accordion expansion states for Filters page
  bool _typeExpanded = true;
  bool _genreExpanded = false;
  bool _yearExpanded = false;
  bool _countryExpanded = false;
  bool _ratingExpanded = false;
  bool _qualityExpanded = false;
  bool _sortExpanded = false;

  final List<Map<String, dynamic>> _folderCategories = [
    {
      'title': 'Movies',
      'poster': 'https://image.tmdb.org/t/p/w500/wjOHjWCUE0YzDiEzKv8AfqHj3ir.jpg', // Babylon
      'query': 'Movies',
    },
    {
      'title': 'TV shows',
      'poster': 'https://image.tmdb.org/t/p/w500/lxWSGo8D6MbFbQmM9tqhbaG80TP.jpg', // Lockwood & Co
      'query': 'TV shows',
    },
    {
      'title': 'Music Video',
      'poster': 'https://image.tmdb.org/t/p/w500/ccRSixnjEcYM9FiQXACecJkQ6kL.jpg', // Tate McRae
      'query': 'Music Video',
    },
    {
      'title': 'Gaming',
      'poster': 'https://image.tmdb.org/t/p/w500/3O2UgEszp1CVbL8p9XnKkFDkbk3.jpg', // Assassin's Creed
      'query': 'Gaming',
    },
    {
      'title': 'Anime',
      'poster': 'https://image.tmdb.org/t/p/w500/vIeu8WysZrQgmE2OMtE9q6W5n3D.jpg', // Suzume
      'query': 'Anime',
    },
    {
      'title': 'Action',
      'poster': 'https://image.tmdb.org/t/p/w500/bjiS5ipwxb9JFy3XRRN4OAilSeX.jpg', // Top Gun: Maverick
      'query': 'Action',
    },
    {
      'title': 'Sci-Fi',
      'poster': 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg', // Interstellar
      'query': 'Sci-Fi',
    },
    {
      'title': 'Comedy',
      'poster': 'https://image.tmdb.org/t/p/w500/iuFNMS8U5cb6xfzi51Dbkovj7vM.jpg', // Barbie
      'query': 'Comedy',
    },
  ];

  final List<String> _quickPillGenres = [
    'Action',
    'Documentary',
    'Sci-Fi',
    'Drama',
    'Comedy',
    'Adventure',
    'Animation',
    'Horror',
    'Romance',
    'Fantasy',
    'Crime',
    'Thriller',
    'Family',
  ];

  void _openCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.text = category;
      _searchQuery = category;
      _searchStep = 2;
    });
  }

  void _openMovieDetails(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(movie: movie),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _buildCurrentStepView(),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_searchStep) {
      case 1:
        return _buildCategoriesLandingPage();
      case 2:
        return _buildSearchResultsPage();
      case 3:
        return _buildFiltersPage();
      default:
        return _buildCategoriesLandingPage();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 1: CATEGORIES LANDING (Reference Image 1, Left Screen)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCategoriesLandingPage() {
    return Stack(
      children: [
        // Warm fiery/amber ambient glow illuminating the search bar and top header
        Positioned(
          top: -40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6F00).withOpacity(0.35),
                    const Color(0xFFFF8F00).withOpacity(0.18),
                    const Color(0xFFFFB300).withOpacity(0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.75, 1.0],
                ),
              ),
            ),
          ),
        ),

        ListView(
          key: const ValueKey('CategoriesLandingPage'),
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          children: [
            // ── Top Glassmorphic Search Bar ─────────────────────────────────
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchStep = 2;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E222D).withOpacity(0.65),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Icon(
                          Icons.search_rounded,
                          color: Colors.white.withOpacity(0.65),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Categories Header & Subtitle (Centered) ─────────────────────
            const Text(
              'Categories',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 25,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Watch Unlimited Movies, Music Video,\nTV shows, Gaming and More.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 24),

            // ── 2-Column Grid of Custom Folder-Tab Cards ────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 22,
                childAspectRatio: 0.68,
              ),
              itemCount: _folderCategories.length,
              itemBuilder: (context, i) {
                final cat = _folderCategories[i];
                return _buildFolderCard(
                  title: cat['title'] as String,
                  posterUrl: cat['poster'] as String,
                  onTap: () => _openCategory(cat['query'] as String),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Custom folder card with realistic physical folder tabs matching reference
  Widget _buildFolderCard({
    required String title,
    required String posterUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Back tab tier 2 (top-most ridge, slightly narrower)
                    Positioned(
                      top: 0,
                      left: cardWidth * 0.16,
                      right: cardWidth * 0.16,
                      height: 14,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D212C),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.08),
                              width: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Back tab tier 1 (main folder back tab)
                    Positioned(
                      top: 5,
                      left: 10,
                      right: 10,
                      height: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF282C38),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.16),
                              width: 0.9,
                            ),
                            left: BorderSide(
                              color: Colors.white.withOpacity(0.08),
                              width: 0.8,
                            ),
                            right: BorderSide(
                              color: Colors.white.withOpacity(0.08),
                              width: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Front Poster Card
                    Positioned.fill(
                      top: 13,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.55),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: posterUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Shimmer.fromColors(
                              baseColor: const Color(0xFF181B24),
                              highlightColor: const Color(0xFF262C3A),
                              child: Container(color: const Color(0xFF181B24)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF181B24),
                              child: const Icon(
                                Icons.movie_rounded,
                                color: Colors.white24,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 9),

              // Category Label (Left-aligned under card matching reference)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 2: SEARCH RESULTS & CATEGORY (Reference Image 2 Match)
  // ═══════════════════════════════════════════════════════════════════════════
  String get _formattedCategoryTitle {
    final cat = _selectedCategory.trim();
    if (_searchQuery.isNotEmpty &&
        _searchQuery.toLowerCase() != cat.toLowerCase()) {
      return 'Results for "$_searchQuery"';
    }
    final lower = cat.toLowerCase();
    if (lower == 'movies' || lower == 'popular') return 'Popular movies';
    if (lower.contains('show') || lower.contains('tv')) return 'TV shows';
    if (lower.contains('video') || lower.contains('music')) return 'Music videos';
    if (lower.endsWith('movies')) return cat;
    return '$cat movies';
  }

  Widget _buildSearchResultsPage() {
    final searchParam = SearchCategoryParam(
      category: _selectedCategory,
      query: _searchQuery,
    );
    final moviesAsync = ref.watch(categoryOrSearchMoviesProvider(searchParam));

    return Column(
      key: const ValueKey('SearchResultsPage'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Glassmorphic Search Bar with Back Button ───────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // Back Button returning to Step 1 (Categories)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchStep = 1;
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 0.8,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // iOS Frosted Glass Search Capsule
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E222D).withOpacity(0.65),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.trim();
                                });
                              },
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              cursorColor: AppColors.accent,
                              decoration: InputDecoration(
                                hintText: 'Search $_selectedCategory...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.40),
                                  fontSize: 14.5,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white.withOpacity(0.70),
                                  size: 20,
                                ),
                              ),
                            ),
                          Icon(
                            Icons.search_rounded,
                            color: Colors.white.withOpacity(0.65),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Horizontal Category / Genre Filter Pills Row ────────────────────
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: _quickPillGenres.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final genre = _quickPillGenres[i];
              final isSelected =
                  _selectedCategory.toLowerCase() == genre.toLowerCase();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = genre;
                    _searchController.text = genre;
                    _searchQuery = genre;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2E3344)
                            : const Color(0xFF161922).withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withOpacity(0.30)
                              : Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          genre,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // ── Section Header with Sliders Filter & Arrangement Toggle ────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formattedCategoryTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              Row(
                children: [
                  // Sliders Filter Icon (Opens Screen 3: Filters)
                  IconButton(
                    onPressed: () => setState(() => _searchStep = 3),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Arrangement Button (4-Squares Grid / List View Toggle)
                  IconButton(
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isGridView
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Results Content: Clean Backdrop List View or 3-Column Grid ─────
        Expanded(
          child: moviesAsync.when(
            data: (results) {
              if (results.isEmpty) {
                return _buildEmptyResults();
              }
              return _isGridView
                  ? _buildGridView(results)
                  : _buildListView(results);
            },
            loading: () => _isGridView
                ? _buildGridLoadingSkeleton()
                : _buildListLoadingSkeleton(),
            error: (_, __) => _buildEmptyResults(),
          ),
        ),
      ],
    );
  }

  /// Clean Landscape Backdrop Movie List matching Reference Image 2
  Widget _buildListView(List<Movie> results) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final movie = results[i];
        final backdropUrl = movie.backdropPath != null &&
                movie.backdropPath!.isNotEmpty
            ? '${ApiConstants.backdropW780}${movie.backdropPath}'
            : (movie.posterPath != null && movie.posterPath!.isNotEmpty
                ? '${ApiConstants.posterW500}${movie.posterPath}'
                : null);

        final rating = movie.voteAverage > 0
            ? movie.voteAverage.toStringAsFixed(1)
            : '6.2';

        final releaseYear = movie.year.isNotEmpty ? movie.year : '2023';

        return GestureDetector(
          onTap: () => _openMovieDetails(movie),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              // Rounded Backdrop Thumbnail (128x76)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 128,
                  height: 76,
                  child: backdropUrl != null
                      ? CachedNetworkImage(
                          imageUrl: backdropUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: const Color(0xFF161922),
                            highlightColor: const Color(0xFF262C3A),
                            child: Container(color: const Color(0xFF161922)),
                          ),
                          errorWidget: (_, __, ___) => Container(
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
                ),
              ),

              const SizedBox(width: 14),

              // Info: Year, Title, Star Rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      releaseYear,
                      style: const TextStyle(
                        color: Color(0xFF8E929E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB800),
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3-dots Menu Button
              IconButton(
                onPressed: () => _openMovieDetails(movie),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 3-Column Movie Grid matching MovieGridScreen (Arrangement Mode)
  Widget _buildGridView(List<Movie> results) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.52,
        crossAxisSpacing: 10,
        mainAxisSpacing: 16,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final movie = results[index];
        final posterUrl = movie.posterPath != null && movie.posterPath!.isNotEmpty
            ? (movie.posterPath!.startsWith('http')
                ? movie.posterPath!
                : '${ApiConstants.posterW342}${movie.posterPath}')
            : null;

        final ratingDisplay =
            movie.voteAverage > 0 ? movie.voteAverage.toStringAsFixed(1) : '7.5';
        final releaseYear = movie.year.isNotEmpty ? movie.year : '2024';

        return GestureDetector(
          onTap: () => _openMovieDetails(movie),
          behavior: HitTestBehavior.opaque,
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
                              final vj = MockData.vjs.firstWhere(
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
                                    const SizedBox(width: 3),
                                    Text(
                                      vj.name,
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

              // Rating + Release Year row
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
      },
    );
  }

  Widget _buildListLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFF141722),
        highlightColor: const Color(0xFF222838),
        child: Row(
          children: [
            Container(
              width: 128,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 140,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 50,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridLoadingSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.52,
        crossAxisSpacing: 10,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFF141722),
        highlightColor: const Color(0xFF222838),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              color: Colors.white.withOpacity(0.4), size: 48),
          const SizedBox(height: 12),
          const Text(
            'No movies found',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Try searching for another genre or title',
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 3: FILTERS SCREEN (Reference Image 1, Right Screen)
  // ═══════════════════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 3: FILTERS SCREEN (Reference media_1791064801369.png 1:1 Match)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFiltersPage() {
    return Column(
      key: const ValueKey('FiltersPage'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Left Small Close '✕' Icon ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => setState(() => _searchStep = 2),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Bold 'Filters' Title on its own row ───────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Text(
            'Filters',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),

        // ── Expandable Filter Accordion Cards ──────────────────────────────
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: [
              // 1. Type Section (Expanded Radio Options in 2x2 grid)
              _buildAccordionCard(
                title: 'Type',
                isExpanded: _typeExpanded,
                onToggle: () => setState(() => _typeExpanded = !_typeExpanded),
                content: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildRadioOption('Movies')),
                        Expanded(child: _buildRadioOption('Music videos')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _buildRadioOption('TV shows')),
                        Expanded(child: _buildRadioOption('Gaming')),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 2. Genre / Gener Section (Real TMDB Genres)
              _buildAccordionCard(
                title: 'Genre',
                isExpanded: _genreExpanded,
                onToggle: () => setState(() => _genreExpanded = !_genreExpanded),
                content: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickPillGenres.map((g) {
                    final isSel = _selectedGenre == g;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedGenre = g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF8B5CF6) : const Color(0xFF2B2D36),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          g,
                          style: TextStyle(
                            color: isSel ? Colors.white : Colors.white70,
                            fontSize: 12.5,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              // 3. Year Section
              _buildAccordionCard(
                title: 'Year',
                isExpanded: _yearExpanded,
                onToggle: () => setState(() => _yearExpanded = !_yearExpanded),
                content: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['2025', '2024', '2023', '2022', '2020-2021', 'All'].map((y) {
                    final isSel = _selectedYear == y;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedYear = y),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF8B5CF6) : const Color(0xFF2B2D36),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          y,
                          style: TextStyle(
                            color: isSel ? Colors.white : Colors.white70,
                            fontSize: 12.5,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              // 4. Country Section
              _buildAccordionCard(
                title: 'Country',
                isExpanded: _countryExpanded,
                onToggle: () => setState(() => _countryExpanded = !_countryExpanded),
                content: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['United States', 'Uganda', 'United Kingdom', 'South Korea', 'All'].map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B2D36),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              // 5. Rating Section
              _buildAccordionCard(
                title: 'Rating',
                isExpanded: _ratingExpanded,
                onToggle: () => setState(() => _ratingExpanded = !_ratingExpanded),
                content: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['★ 8.0+', '★ 7.0+', '★ 6.0+', 'All'].map((r) {
                    final isSel = _selectedRating == r;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRating = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF8B5CF6) : const Color(0xFF2B2D36),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          r,
                          style: TextStyle(
                            color: isSel ? Colors.white : Colors.white70,
                            fontSize: 12.5,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              // 6. Quality Section
              _buildAccordionCard(
                title: 'Quality',
                isExpanded: _qualityExpanded,
                onToggle: () => setState(() => _qualityExpanded = !_qualityExpanded),
                content: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['4K Ultra HD', '1080p Full HD', '720p HD', 'All'].map((q) {
                    final isSel = _selectedQuality == q;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedQuality = q),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF8B5CF6) : const Color(0xFF2B2D36),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          q,
                          style: TextStyle(
                            color: isSel ? Colors.white : Colors.white70,
                            fontSize: 12.5,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              // 7. Most Relevance Section
              _buildAccordionCard(
                title: 'Most relevance',
                isExpanded: _sortExpanded,
                onToggle: () => setState(() => _sortExpanded = !_sortExpanded),
                content: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Popularity', 'Latest Release', 'Top Rated'].map((s) {
                    final isSel = _selectedSort == s;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSort = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF8B5CF6) : const Color(0xFF2B2D36),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: isSel ? Colors.white : Colors.white70,
                            fontSize: 12.5,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),

        // ── Floating White Done Pill Button (Comfortably padded above nav bar) ─
        Padding(
          padding: const EdgeInsets.only(bottom: 96, top: 8),
          child: Center(
            child: SizedBox(
              width: 144,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = _selectedGenre;
                    _searchController.text = _selectedGenre;
                    _searchQuery = _selectedGenre;
                    _searchStep = 2;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccordionCard({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Theme(
            data: ThemeData(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(
                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: Colors.white60,
                size: 22,
              ),
              onTap: onToggle,
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label) {
    final isSelected = _selectedType == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = label),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF8B5CF6) : Colors.white30,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B5CF6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
