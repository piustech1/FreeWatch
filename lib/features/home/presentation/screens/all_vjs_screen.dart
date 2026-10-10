import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/vj.dart';
import '../../../../shared/widgets/free_watch_top_app_bar.dart';
import '../../../movie_grid/presentation/screens/movie_grid_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../providers/home_providers.dart';
import '../../widgets/floating_nav_bar.dart';
import '../../widgets/vj_card.dart';

/// Fullscreen vertical presentation of all Available VJs in the application
/// with persistent FreeWatch top app bar and floating bottom navigation menu.
class AllVjsScreen extends ConsumerWidget {
  final List<Vj> vjs;

  const AllVjsScreen({
    super.key,
    required this.vjs,
  });

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
                // ── Top Header / App Bar (Persistent across the app) ─────────
                FreeWatchTopAppBar(
                  onSearchTap: () => navigateToBottomNavTab(context, ref, 1),
                  onNotificationTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  onProfileTap: () => navigateToBottomNavTab(context, ref, 4),
                ),

                // ── Subheader with Frosted Glass Back Button & VJ Count ───────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
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
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available VJs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Select a translator to view their translated movies',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC084FC).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFC084FC).withOpacity(0.30),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${vjs.length} VJs',
                          style: const TextStyle(
                            color: Color(0xFFC084FC),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  color: Colors.white10,
                  height: 1,
                  thickness: 0.8,
                ),

                // ── Vertical Presentation of VJ Cards ─────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    physics: const BouncingScrollPhysics(),
                    itemCount: vjs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final vj = vjs[index];
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return VjCard(
                            vj: vj,
                            index: index,
                            width: constraints.maxWidth,
                            height: 116,
                            onTap: () {
                              Navigator.of(context).push(
                                MovieGridScreen.routeForVj(vj: vj),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // ── Persistent Floating Bottom Navigation Pill ────────────────────
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
}
