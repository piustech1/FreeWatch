import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/movie.dart';
import '../../../home/widgets/movie_card.dart';
import '../../../movie_detail/presentation/screens/movie_detail_screen.dart';

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
      'poster': 'https://image.tmdb.org/t/p/w500/A7EByudX0eOzlkQ2FIbogzyazm2.jpg',
      'fallback': 'assets/images/logo_initials.png',
      'query': 'Movies',
    },
    {
      'title': 'TV shows',
      'poster': 'https://image.tmdb.org/t/p/w500/kSpsYjG80eL4qQ3R3n9k6rLqC9p.jpg',
      'fallback': 'assets/images/logo_initials.png',
      'query': 'TV shows',
    },
    {
      'title': 'Music videos',
      'poster': 'https://image.tmdb.org/t/p/w500/m20yt7Ul7hJBLv0S8j7Hn6Zk2iV.jpg',
      'fallback': 'assets/images/logo_initials.png',
      'query': 'Music videos',
    },
    {
      'title': 'Gaming',
      'poster': 'https://image.tmdb.org/t/p/w500/lrkudNqmG39w62M4t4o6kQ7gV0r.jpg',
      'fallback': 'assets/images/logo_initials.png',
      'query': 'Gaming',
    },
    {
      'title': 'Adventure',
      'poster': 'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
      'fallback': 'assets/images/logo_initials.png',
      'query': 'Adventure',
    },
    {
      'title': 'Action',
      'poster': 'https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
      'fallback': 'assets/images/logo_initials.png',
      'query': 'Action',
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
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        // Subtle ambient fiery glow at the top matching Image 1
        Positioned(
          top: -30,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 180,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF5722).withOpacity(0.28),
                    const Color(0xFFFF9800).withOpacity(0.12),
                    Colors.transparent,
                  ],
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
            // ── Top Search Input Bar ────────────────────────────────────────────
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchStep = 2;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141720),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 14.5,
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

            const SizedBox(height: 20),

            // ── Categories Header & Subtitle ────────────────────────────────────
            const Text(
              'Categories',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Watch Unlimited Movies, Music Video,\nTV shows, Gaming and More.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

        // ── 2-Column Grid of Custom Folder-Tab Cards ────────────────────────
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 18,
            childAspectRatio: 0.88,
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

  /// Custom folder card with tab outline matching Image 1
  Widget _buildFolderCard({
    required String title,
    required String posterUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Folder Tab Container
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Top Tab Header
                Positioned(
                  top: -6,
                  left: 14,
                  child: Container(
                    width: 60,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF232733),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),

                // Main Folder Body
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161922),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: const Color(0xFF1E2130)),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF1E2130),
                        child: const Icon(Icons.movie_rounded, color: Colors.white24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Category Label
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 2: SEARCH RESULTS & CATEGORY (Reference Image 1, Middle Screen)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSearchResultsPage() {
    final allMovies = MockData.getAllMovies();

    // Filter by query and category
    final results = allMovies.where((m) {
      if (_searchQuery.isNotEmpty &&
          _searchQuery.toLowerCase() != _selectedCategory.toLowerCase()) {
        final matches = m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (m.overview != null &&
                m.overview!.toLowerCase().contains(_searchQuery.toLowerCase()));
        if (!matches) return false;
      }

      if (_selectedCategory == 'Movies') return true;
      if (_selectedCategory == 'TV shows') {
        return m.id == 1125510 || m.title.contains('House');
      }
      if (_selectedCategory == 'Action') return m.genreIds.contains(28);
      if (_selectedCategory == 'Sci-Fi') return m.genreIds.contains(878);
      if (_selectedCategory == 'Animation') return m.genreIds.contains(16);
      if (_selectedCategory == 'Horror') return m.genreIds.contains(27);
      if (_selectedCategory == 'Comedy') return m.genreIds.contains(35);
      if (_selectedCategory == 'Adventure') {
        return m.genreIds.contains(12) || m.genreIds.contains(28);
      }

      return true;
    }).toList();

    return Column(
      key: const ValueKey('SearchResultsPage'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Search Input Header with Back & Search Icon ────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _searchStep = 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141720),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: AppColors.accent,
                          decoration: InputDecoration(
                            hintText: 'Search $_selectedCategory...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.search_rounded,
                        color: Colors.white.withOpacity(0.65),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Horizontal Pill Filter Tags Row ─────────────────────────────────
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: _quickPillGenres.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final genre = _quickPillGenres[i];
              final isSelected = _selectedCategory.toLowerCase() == genre.toLowerCase();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = genre;
                    _searchController.text = genre;
                    _searchQuery = genre;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2C303E) : const Color(0xFF141720),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.8)
                          : Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    genre,
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // ── Section Header with Sliders Filter & Grid Toggle ───────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_selectedCategory movies',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              Row(
                children: [
                  // Sliders Filter Icon (Navigates to Screen 3: Filters)
                  IconButton(
                    onPressed: () => setState(() => _searchStep = 3),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Grid / List View Toggle Icon
                  IconButton(
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Results Content: Horizontal Movie Tiles or Grid ────────────────
        Expanded(
          child: results.isEmpty
              ? _buildEmptyResults()
              : _isGridView
                  ? _buildGridView(results)
                  : _buildListView(results),
        ),
      ],
    );
  }

  /// Horizontal wide movie cards matching Image 1 Screen 2
  Widget _buildListView(List<Movie> results) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final movie = results[i];
        final posterUrl = movie.backdropPath != null && movie.backdropPath!.isNotEmpty
            ? '${ApiConstants.backdropW780}${movie.backdropPath}'
            : (movie.posterPath != null
                ? '${ApiConstants.posterW500}${movie.posterPath}'
                : null);

        final rating = movie.voteAverage > 0
            ? movie.voteAverage.toStringAsFixed(1)
            : '6.2';

        return GestureDetector(
          onTap: () => _openMovieDetails(movie),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10131A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Rounded Poster Thumbnail (88x58)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 88,
                    height: 58,
                    child: posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: posterUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: const Color(0xFF1C202C)),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF1C202C),
                              child: const Icon(Icons.movie_rounded, color: Colors.white24),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF1C202C),
                            child: const Icon(Icons.movie_rounded, color: Colors.white24),
                          ),
                  ),
                ),

                const SizedBox(width: 12),

                // Info: Year, Title, Star Rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.year.isNotEmpty ? movie.year : '2023',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB800),
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Grid view representation
  Widget _buildGridView(List<Movie> results) {
    return GridView.builder(
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
          onTap: () => _openMovieDetails(movie),
        );
      },
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, color: Colors.white.withOpacity(0.4), size: 48),
          const SizedBox(height: 12),
          const Text(
            'No movies found',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Try searching for another genre or title',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 3: FILTERS SCREEN (Reference Image 1, Right Screen)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFiltersPage() {
    return Column(
      key: const ValueKey('FiltersPage'),
      children: [
        // ── Top Header: Close 'X' and 'Filters' Title ──────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _searchStep = 2),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Filters',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),

        // ── Expandable Filter Accordion List ────────────────────────────────
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            children: [
              // 1. Type Section (Expanded Radio Options)
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildRadioOption('TV shows')),
                        Expanded(child: _buildRadioOption('Gaming')),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. Genre Section
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.accent : const Color(0xFF1E2130),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          g,
                          style: TextStyle(
                            color: isSel ? Colors.black : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.accent : const Color(0xFF1E2130),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          y,
                          style: TextStyle(
                            color: isSel ? Colors.black : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // 4. Country Section
              _buildAccordionCard(
                title: 'Country',
                isExpanded: _countryExpanded,
                onToggle: () => setState(() => _countryExpanded = !_countryExpanded),
                content: const Text(
                  'United States • Uganda • United Kingdom • South Korea',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),

              const SizedBox(height: 12),

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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.accent : const Color(0xFF1E2130),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          r,
                          style: TextStyle(
                            color: isSel ? Colors.black : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.accent : const Color(0xFF1E2130),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          q,
                          style: TextStyle(
                            color: isSel ? Colors.black : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.accent : const Color(0xFF1E2130),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: isSel ? Colors.black : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom Pill Button: "Done" ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 8, 30, 24),
          child: SizedBox(
            width: 140,
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
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
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
        color: const Color(0xFF131620),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: Colors.white54,
              size: 22,
            ),
            onTap: onToggle,
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.accent : Colors.white38,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
