import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/genre.dart';
import '../../shared/widgets/shimmer_loading.dart';
import 'providers/home_providers.dart';
import 'widgets/hero_banner.dart';
import 'widgets/movie_section.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/filter_bottom_sheet.dart';

/// Main Home Screen matching design screenshot
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final genresAsync = ref.watch(genresProvider);
    final selectedGenreId = ref.watch(selectedGenreProvider);
    final trendingAsync = ref.watch(trendingMoviesProvider);
    final popularAsync = ref.watch(popularMoviesProvider);
    final topRatedAsync = ref.watch(topRatedMoviesProvider);
    final nowPlayingAsync = ref.watch(nowPlayingMoviesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable Content ───────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Top Header / App Bar ─────────────────────────────────
                SliverToBoxAdapter(
                  child: _HomeAppBar(
                    onSearchTap: () => FilterBottomSheet.show(context),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Genre Filter Chips ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: genresAsync.when(
                    data: (genres) => _GenreFilterBar(
                      genres: genres,
                      selectedId: selectedGenreId,
                      onSelect: (id) =>
                          ref.read(selectedGenreProvider.notifier).state = id,
                    ),
                    loading: () => const SizedBox(height: 40),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Hero Banner Carousel ───────────────────────────────────
                SliverToBoxAdapter(
                  child: trendingAsync.when(
                    data: (movies) => HeroBanner(
                      movies: movies,
                      onTap: (movie) {
                        // Movie detail tap
                      },
                      onSeeAll: () {
                        // See all trending
                      },
                    ),
                    loading: () => const HeroBannerShimmer(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // ── "New" Section ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: nowPlayingAsync.when(
                    data: (movies) => MovieSection(
                      title: 'New',
                      movies: movies,
                      onMovieTap: (movie) {
                        // Navigate to detail
                      },
                      onSeeAll: () {},
                    ),
                    loading: () => const MovieSection(
                      title: 'New',
                      isLoading: true,
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // ── "Movies" Section ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: popularAsync.when(
                    data: (movies) => MovieSection(
                      title: 'Movies',
                      movies: movies,
                      onMovieTap: (movie) {},
                      onSeeAll: () {},
                    ),
                    loading: () => const MovieSection(
                      title: 'Movies',
                      isLoading: true,
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // ── "Top Rated" Section ────────────────────────────────────
                SliverToBoxAdapter(
                  child: topRatedAsync.when(
                    data: (movies) => MovieSection(
                      title: 'Top Rated',
                      movies: movies,
                      onMovieTap: (movie) {},
                      onSeeAll: () {},
                    ),
                    loading: () => const MovieSection(
                      title: 'Top Rated',
                      isLoading: true,
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // ── Space for Floating Nav Bar ────────────────────────────
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // ── Floating Bottom Navigation Pill ──────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavBar(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) {
                setState(() => _selectedNavIndex = index);
                if (index == 1) {
                  FilterBottomSheet.show(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── App Bar ──────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  final VoidCallback onSearchTap;

  const _HomeAppBar({required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          // Logo
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Free',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'Watch',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Search / Filter Button
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Notification Button
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Genre Filter Bar ─────────────────────────────────────────────────────────

class _GenreFilterBar extends StatelessWidget {
  final List<Genre> genres;
  final int? selectedId;
  final void Function(int? id) onSelect;

  const _GenreFilterBar({
    required this.genres,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        physics: const BouncingScrollPhysics(),
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = genres[index];
          final isSelected = genre.id == selectedId;

          return GestureDetector(
            onTap: () => onSelect(isSelected ? null : genre.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.chipSelected
                    : AppColors.chipUnselected,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Text(
                  genre.name,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.chipTextSelected
                        : AppColors.chipTextUnselected,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
