import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../features/home/providers/home_providers.dart';

/// Cinematic TV & Wide-Screen Navigation Sidebar (Netflix-style)
/// Provides intuitive D-Pad / Remote control focus traversal and large-screen layout
class TvNavigationSidebar extends ConsumerStatefulWidget {
  final Function(int) onTabSelected;

  const TvNavigationSidebar({
    super.key,
    required this.onTabSelected,
  });

  @override
  ConsumerState<TvNavigationSidebar> createState() => _TvNavigationSidebarState();
}

class _TvNavigationSidebarState extends ConsumerState<TvNavigationSidebar> {
  int _focusedIndex = -1;

  final List<_NavEntry> _entries = const [
    _NavEntry(icon: Icons.home_rounded, label: 'Home'),
    _NavEntry(icon: Icons.search_rounded, label: 'Search'),
    _NavEntry(icon: Icons.favorite_rounded, label: 'Favorites'),
    _NavEntry(icon: Icons.download_rounded, label: 'Downloads'),
    _NavEntry(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13).withOpacity(0.95),
        border: const Border(
          right: BorderSide(color: Color(0x1FFFFFFF), width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App Brand Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'FreeWatch',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Navigation Items ──────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final isSelected = currentIndex == index;
                  final isFocused = _focusedIndex == index;

                  return FocusableActionDetector(
                    onFocusChange: (hasNavFocus) {
                      setState(() {
                        _focusedIndex = hasNavFocus ? index : -1;
                      });
                    },
                    child: InkWell(
                      onTap: () {
                        ref.read(bottomNavIndexProvider.notifier).state = index;
                        widget.onTabSelected(index);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isFocused
                              ? AppColors.primary.withOpacity(0.25)
                              : (isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFocused
                                ? AppColors.primary
                                : (isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent),
                            width: isFocused ? 2.0 : 1.0,
                          ),
                          boxShadow: isFocused
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              entry.icon,
                              size: 22,
                              color: isFocused || isSelected
                                  ? (isFocused ? Colors.white : AppColors.primary)
                                  : Colors.white60,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              entry.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected || isFocused ? FontWeight.w700 : FontWeight.w500,
                                color: isFocused || isSelected ? Colors.white : Colors.white70,
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

            // ── TV Mode Indicator ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.tv_rounded, size: 14, color: Colors.white38),
                    SizedBox(width: 6),
                    Text(
                      'Android TV Mode',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavEntry {
  final IconData icon;
  final String label;
  const _NavEntry({required this.icon, required this.label});
}
