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
import '../../shared/widgets/tiktok_promo_modal.dart';
import '../../shared/widgets/tv_navigation_sidebar.dart';
import '../../core/services/device_type_service.dart';
import 'widgets/app_update_banner.dart';
import 'widgets/tv_hero_billboard.dart';

/// Main Application Shell & Home Screen with persistent top bar across all tabs
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _tvScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    TiktokPromoModal.showOncePerSession(context);
  }

  @override
  void dispose() {
    _tvScrollController.dispose();
    super.dispose();
  }

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

  int _resolveTvStackIndex(String target) {
    switch (target) {
      case 'search':
        return 1;
      case 'available-vjs':
        return 2;
      case 'categories':
        return 3;
      case 'favorites':
        return 4;
      case 'downloads':
        return 5;
      case 'profile':
        return 6;
      case 'notifications':
        return 7;
      case 'home':
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedNavIndex = ref.watch(bottomNavIndexProvider);
    final currentTvNav = ref.watch(tvNavTargetProvider);
    final isWideOrTv = MediaQuery.sizeOf(context).width >= 720 || DeviceTypeService().isTv;
    final vjsAsync = ref.watch(vjsWithCountsProvider);
    final currentVjs = vjsAsync.valueOrNull ?? MockData.vjs;

    final Widget tabContent = IndexedStack(
      index: isWideOrTv ? _resolveTvStackIndex(currentTvNav) : selectedNavIndex,
      children: [
        // Tab 0: Home Feed
        _buildHomeFeed(context, isWideOrTv: isWideOrTv),

        // Tab 1: Dedicated Search Screen
        const SearchScreen(),

        // Tab 2: All Available VJs Screen (Widescreen & TV)
        AllVjsScreen(vjs: currentVjs),

        // Tab 3: Categories Overview Screen
        const MovieGridScreen(
          title: 'Categories',
          movies: [],
          icon: Icons.grid_view_rounded,
          iconColor: Color(0xFF00E676),
        ),

        // Tab 4: Dedicated Favorites / Watchlist Screen
        FavoritesScreen(
          onExploreTap: () {
            if (isWideOrTv) {
              ref.read(tvNavTargetProvider.notifier).state = 'home';
            } else {
              navigateToBottomNavTab(context, ref, 0);
            }
          },
        ),

        // Tab 5: Dedicated Downloads Screen
        const DownloadsScreen(),

        // Tab 6: Dedicated Profile & Settings Screen
        const ProfileScreen(),

        // Tab 7: Dedicated Notifications Screen
        const NotificationsScreen(),
      ],
    );

    if (isWideOrTv) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            TvNavigationSidebar(
              currentNav: currentTvNav,
              onNavigate: (target) {
                ref.read(tvNavTargetProvider.notifier).state = target;
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  tabContent,
                  const Positioned(
                    top: 14,
                    right: 24,
                    child: AppUpdateBanner(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

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

                // ── Dynamic Release Update Banner ──────────────────────────────
                const AppUpdateBanner(),

                // ── Tab View ──────────────────────────────────────────
                Expanded(child: tabContent),
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
  Widget _buildHomeFeed(BuildContext context, {bool isWideOrTv = false}) {
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
    final vjsAsync = ref.watch(vjsWithCountsProvider);
    final currentVjs = vjsAsync.valueOrNull ?? MockData.vjs;

    return CustomScrollView(
      controller: isWideOrTv ? _tvScrollController : null,
      physics: isWideOrTv ? const ClampingScrollPhysics() : const BouncingScrollPhysics(),
      cacheExtent: isWideOrTv ? 1200 : 280,
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: isWideOrTv ? 0 : 6)),

        // ── Hero Banner (Phone: 4-Poster Stacked Deck | TV: 16:9 Cinematic Billboard) ──
        SliverToBoxAdapter(
          child: trendingAsync.when(
            data: (movies) => isWideOrTv
                ? TvHeroBillboard(
                    movies: movies,
                    onPlay: _openMovieDetail,
                    onDetails: _openMovieDetail,
                  )
                : HeroBanner(
                    movies: movies,
                    onTap: _openMovieDetail,
                    onSeeAll: () {
                      Navigator.of(context).push(
                        MovieGridScreen.routeForCategory(
                          title: 'Trending',
                          movies: const [],
                        ),
                      );
                    },
                  ),
            loading: () => isWideOrTv
                ? const SizedBox(
                    height: 380,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  )
                : const HeroBannerShimmer(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // ── "Available Vj's" Section (Directly Below Hero with Real Counts) ──────────
        SliverToBoxAdapter(
          child: VjSection(
            vjs: currentVjs,
            onVjTap: (vj) {
              Navigator.of(context).push(
                MovieGridScreen.routeForVj(vj: vj),
              );
            },
            onSeeAll: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AllVjsScreen(vjs: currentVjs),
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
                  movies: const [],
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
