import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/shimmer_loading.dart';
import 'providers/home_providers.dart';
import 'widgets/hero_banner.dart';
import 'widgets/movie_section.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/filter_bottom_sheet.dart';
import 'widgets/vj_section.dart';
import 'widgets/vj_movies_sheet.dart';
import '../../data/mock/mock_movies.dart';
import '../../data/models/movie.dart';
import '../auth/presentation/screens/choose_avatar_screen.dart';

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
    final trendingAsync = ref.watch(trendingMoviesProvider);
    final latestToRewatchAsync = ref.watch(latestToRewatchProvider);
    final latestUploadsAsync = ref.watch(latestUploadsProvider);
    final seriesAsync = ref.watch(seriesProvider);
    final actionAsync = ref.watch(actionMoviesProvider);
    final sciFiAsync = ref.watch(sciFiMoviesProvider);
    final romanceAsync = ref.watch(romanceMoviesProvider);
    final horrorAsync = ref.watch(horrorMoviesProvider);
    final dramaAsync = ref.watch(dramaMoviesProvider);
    final animationAsync = ref.watch(animationMoviesProvider);
    final familyAsync = ref.watch(familyMoviesProvider);

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

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

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

                // ── "Available Vj's" Section (Directly Below Hero) ──────────
                SliverToBoxAdapter(
                  child: VjSection(
                    vjs: MockData.vjs,
                    onVjTap: (vj) {
                      VjMoviesSheet.show(
                        context,
                        vj: vj,
                        onMovieTap: (movie) {
                          // Handle movie tap
                        },
                      );
                    },
                    onSeeAll: () {
                      if (MockData.vjs.isNotEmpty) {
                        VjMoviesSheet.show(
                          context,
                          vj: MockData.vjs.first,
                        );
                      }
                    },
                  ),
                ),

                // ── "Latest to Rewatch" Section ───────────────────────────
                _buildMovieSection(context, 'Latest to Rewatch', latestToRewatchAsync),

                // ── "Latest Uploads" Section ──────────────────────────────
                _buildMovieSection(context, 'Latest Uploads', latestUploadsAsync),

                // ── "Series" Section ──────────────────────────────────────
                _buildMovieSection(context, 'Series', seriesAsync),

                // ── Category Sections ─────────────────────────────────────
                _buildMovieSection(context, 'Action', actionAsync),
                _buildMovieSection(context, 'Sci-Fi', sciFiAsync),
                _buildMovieSection(context, 'Romance', romanceAsync),
                _buildMovieSection(context, 'Horror', horrorAsync),
                _buildMovieSection(context, 'Drama', dramaAsync),
                _buildMovieSection(context, 'Animation', animationAsync),
                _buildMovieSection(context, 'Family', familyAsync),

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
                if (index == 3) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChooseAvatarScreen(),
                    ),
                  );
                  return;
                }
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

  Widget _buildMovieSection(
    BuildContext context,
    String title,
    AsyncValue<List<Movie>> asyncValue,
  ) {
    return SliverToBoxAdapter(
      child: asyncValue.when(
        data: (movies) {
          if (movies.isEmpty) return const SizedBox.shrink();
          return MovieSection(
            title: title,
            movies: movies,
            onMovieTap: (movie) {},
            onSeeAll: () {},
          );
        },
        loading: () => MovieSection(
          title: title,
          isLoading: true,
        ),
        error: (_, __) => const SizedBox.shrink(),
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
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 4),
      child: Row(
        children: [
          // Logo - enlarged length and height for bold prominence and clear visibility
          Image.asset(
            'assets/images/logo_full.png',
            height: 60,
            fit: BoxFit.contain,
          ),

          const Spacer(),

          // Search Button (solid glyph IconlyBold.search)
          IconButton(
            onPressed: onSearchTap,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: const Icon(
              IconlyBold.search,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          // Notification Button (solid glyph IconlyBold.notification)
          IconButton(
            onPressed: () {},
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: const Icon(
              IconlyBold.notification,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          // Cast Button (clean, borderless)
          IconButton(
            onPressed: () {},
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.cast_rounded,
              color: AppColors.textPrimary,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }
}
