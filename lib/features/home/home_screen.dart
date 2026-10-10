import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/shimmer_loading.dart';
import '../../shared/widgets/free_watch_top_app_bar.dart';
import 'providers/home_providers.dart';
import 'widgets/hero_banner.dart';
import 'widgets/movie_section.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/vj_section.dart';
import '../../data/mock/mock_movies.dart';
import '../../data/models/movie.dart';
import '../movie_detail/presentation/screens/movie_detail_screen.dart';
import '../movie_grid/presentation/screens/movie_grid_screen.dart';
import 'presentation/screens/all_vjs_screen.dart';
import '../search/presentation/screens/search_screen.dart';
import '../favorites/presentation/screens/favorites_screen.dart';
import '../downloads/presentation/screens/downloads_screen.dart';
import '../profile/presentation/screens/profile_screen.dart';
import '../notifications/presentation/screens/notifications_screen.dart';

/// Main Application Shell & Home Screen with persistent top bar across all tabs
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _openMovieDetail(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(movie: movie),
      ),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedNavIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // ── Top Header / App Bar (Fixed across all tabs) ──────────────────
                FreeWatchTopAppBar(
                  onSearchTap: () => navigateToBottomNavTab(context, ref, 1),
                  onNotificationTap: _openNotifications,
                  onProfileTap: () => navigateToBottomNavTab(context, ref, 4),
                ),

                // ── Tab View ──────────────────────────────────────────
                Expanded(
                  child: IndexedStack(
                    index: selectedNavIndex,
                    children: [
                      // Tab 0: Home Feed
                      _buildHomeFeed(context),

                      // Tab 1: Dedicated Search Screen
                      const SearchScreen(),

                      // Tab 2: Dedicated Favorites / Watchlist Screen
                      FavoritesScreen(
                        onExploreTap: () => navigateToBottomNavTab(context, ref, 0),
                      ),

                      // Tab 3: Dedicated Downloads Screen
                      const DownloadsScreen(),

                      // Tab 4: Dedicated Profile Screen
                      const ProfileScreen(),
                    ],
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
                selectedIndex: selectedNavIndex,
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

  // ── Tab 0: Home Feed ───────────────────────────────────────────────────────
  Widget _buildHomeFeed(BuildContext context) {
    final trendingAsync = ref.watch(trendingMoviesProvider);
    final latestUploadsAsync = ref.watch(latestUploadsProvider);
    final seriesAsync = ref.watch(seriesProvider);
    final actionAsync = ref.watch(actionMoviesProvider);
    final sciFiAsync = ref.watch(sciFiMoviesProvider);
    final romanceAsync = ref.watch(romanceMoviesProvider);
    final horrorAsync = ref.watch(horrorMoviesProvider);
    final dramaAsync = ref.watch(dramaMoviesProvider);
    final animationAsync = ref.watch(animationMoviesProvider);
    final familyAsync = ref.watch(familyMoviesProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 6)),

        // ── Hero Banner Carousel ───────────────────────────────────
        SliverToBoxAdapter(
          child: trendingAsync.when(
            data: (movies) => HeroBanner(
              movies: movies,
              onTap: _openMovieDetail,
              onSeeAll: () {
                Navigator.of(context).push(
                  MovieGridScreen.routeForCategory(
                    title: 'Trending',
                    movies: movies,
                  ),
                );
              },
            ),
            loading: () => const HeroBannerShimmer(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // ── "Available Vj's" Section (Directly Below Hero) ──────────
        SliverToBoxAdapter(
          child: VjSection(
            vjs: MockData.vjs,
            onVjTap: (vj) {
              Navigator.of(context).push(
                MovieGridScreen.routeForVj(vj: vj),
              );
            },
            onSeeAll: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AllVjsScreen(vjs: MockData.vjs),
                ),
              );
            },
          ),
        ),

        // ── Standard Section Titles with iOS Icons ──────────────────
        _buildMovieSection(
          context,
          title: 'Latest on FreeWatch',
          asyncValue: latestUploadsAsync,
          icon: Icons.auto_awesome_rounded,
          iconColor: const Color(0xFF38BDF8),
        ),

        _buildMovieSection(
          context,
          title: 'Series',
          asyncValue: seriesAsync,
          icon: Icons.tv_rounded,
          iconColor: const Color(0xFFE50914),
        ),

        _buildMovieSection(
          context,
          title: 'Action',
          asyncValue: actionAsync,
          icon: Icons.local_fire_department_rounded,
          iconColor: const Color(0xFFF97316),
        ),

        _buildMovieSection(
          context,
          title: 'Sci-Fi',
          asyncValue: sciFiAsync,
          icon: Icons.rocket_launch_rounded,
          iconColor: const Color(0xFFA855F7),
        ),

        _buildMovieSection(
          context,
          title: 'Romance',
          asyncValue: romanceAsync,
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFEC4899),
        ),

        _buildMovieSection(
          context,
          title: 'Horror',
          asyncValue: horrorAsync,
          icon: Icons.nightlight_round,
          iconColor: const Color(0xFFEF4444),
        ),

        _buildMovieSection(
          context,
          title: 'Drama',
          asyncValue: dramaAsync,
          icon: Icons.theater_comedy_rounded,
          iconColor: const Color(0xFFF59E0B),
        ),

        _buildMovieSection(
          context,
          title: 'Animation',
          asyncValue: animationAsync,
          icon: Icons.animation_rounded,
          iconColor: const Color(0xFF10B981),
        ),

        _buildMovieSection(
          context,
          title: 'Family',
          asyncValue: familyAsync,
          icon: Icons.family_restroom_rounded,
          iconColor: const Color(0xFF06B6D4),
        ),

        // ── Space for Floating Nav Bar ────────────────────────────
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildMovieSection(
    BuildContext context, {
    required String title,
    required AsyncValue<List<Movie>> asyncValue,
    IconData? icon,
    Color? iconColor,
  }) {
    return SliverToBoxAdapter(
      child: asyncValue.when(
        data: (movies) {
          if (movies.isEmpty) return const SizedBox.shrink();
          return MovieSection(
            title: title,
            movies: movies,
            icon: icon,
            iconColor: iconColor,
            onMovieTap: _openMovieDetail,
            onSeeAll: () {
              Navigator.of(context).push(
                MovieGridScreen.routeForCategory(
                  title: title,
                  movies: movies,
                  icon: icon,
                  iconColor: iconColor,
                ),
              );
            },
          );
        },
        loading: () => MovieSection(
          title: title,
          isLoading: true,
          icon: icon,
          iconColor: iconColor,
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
