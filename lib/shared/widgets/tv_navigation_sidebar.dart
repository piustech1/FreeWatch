import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/user_avatar_provider.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';

/// 1:1 Mirror of DesktopNavRail.tsx for Android TV & Widescreen
/// Provides persistent glassmorphic navigation rail with D-Pad remote focus,
/// vibrant FreeWatch neon green active glow, and seamless key navigation.
class TvNavigationSidebar extends ConsumerStatefulWidget {
  final String currentNav;
  final ValueChanged<String> onNavigate;

  const TvNavigationSidebar({
    super.key,
    required this.currentNav,
    required this.onNavigate,
  });

  @override
  ConsumerState<TvNavigationSidebar> createState() => _TvNavigationSidebarState();
}

class _TvNavigationSidebarState extends ConsumerState<TvNavigationSidebar> {
  String? _focusedItem;

  @override
  Widget build(BuildContext context) {
    final avatar = ref.watch(userAvatarProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Container(
      width: 78,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF090A0F).withOpacity(0.96),
        border: const Border(
          right: BorderSide(color: Color(0x1AFFFFFF), width: 1.0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const SizedBox(height: 14),

            // ── 1. Top Section: User Avatar & Notification Bell ──────
            // A. User Avatar with Gold Gradient Ring & Online Dot
            _TvRailButton(
              id: 'avatar',
              tooltip: 'Profile & Account',
              isFocused: _focusedItem == 'avatar',
              onFocusChange: (f) => setState(() => _focusedItem = f ? 'avatar' : null),
              onTap: () => widget.onNavigate('profile'),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(2.2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFFDE047), Color(0xFFF59E0B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: avatar.assetPath.isNotEmpty
                          ? Image.asset(avatar.assetPath, fit: BoxFit.cover)
                          : const Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                  ),
                  // Online Green Status Dot
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x8800E676), blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // B. Notification Bell with Counter Badge
            _TvRailButton(
              id: 'notifications',
              tooltip: 'Notifications',
              isFocused: _focusedItem == 'notifications',
              isSelected: widget.currentNav == 'notifications',
              onFocusChange: (f) => setState(() => _focusedItem = f ? 'notifications' : null),
              onTap: () => widget.onNavigate('notifications'),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    widget.currentNav == 'notifications'
                        ? Icons.notifications_rounded
                        : Icons.notifications_none_rounded,
                    size: 22,
                    color: widget.currentNav == 'notifications'
                        ? Colors.black
                        : (_focusedItem == 'notifications' ? Colors.white : Colors.white70),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE50914),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Container(
              width: 38,
              height: 1,
              color: Colors.white.withOpacity(0.08),
            ),
            const SizedBox(height: 16),

            // ── 2. Middle Core TV & PC Action Icons ──────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Search
                    _buildNavItem(
                      id: 'search',
                      icon: Icons.search_rounded,
                      tooltip: 'Search Movies & Series',
                    ),
                    const SizedBox(height: 12),

                    // Home
                    _buildNavItem(
                      id: 'home',
                      icon: Icons.home_rounded,
                      tooltip: 'Home',
                    ),
                    const SizedBox(height: 12),

                    // Available VJs
                    _buildNavItem(
                      id: 'available-vjs',
                      icon: Icons.people_alt_rounded,
                      tooltip: 'Available VJs (Translators)',
                      label: 'VJs',
                    ),
                    const SizedBox(height: 12),

                    // Categories / Browse
                    _buildNavItem(
                      id: 'categories',
                      icon: Icons.grid_view_rounded,
                      tooltip: 'Explore Categories',
                    ),
                    const SizedBox(height: 12),

                    // Favorites
                    _buildNavItem(
                      id: 'favorites',
                      icon: Icons.favorite_rounded,
                      tooltip: 'Favorites',
                    ),
                    const SizedBox(height: 12),

                    // Downloads
                    _buildNavItem(
                      id: 'downloads',
                      icon: Icons.download_rounded,
                      tooltip: 'Downloaded Movies',
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. Bottom Section: Settings Gear ─────────────────────
            _buildNavItem(
              id: 'profile',
              icon: Icons.settings_rounded,
              tooltip: 'Settings & Profile',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String id,
    required IconData icon,
    required String tooltip,
    String? label,
  }) {
    final isSelected = widget.currentNav == id || (id == 'home' && widget.currentNav.isEmpty);
    final isFocused = _focusedItem == id;

    return _TvRailButton(
      id: id,
      tooltip: tooltip,
      isSelected: isSelected,
      isFocused: isFocused,
      onFocusChange: (f) => setState(() => _focusedItem = f ? id : null),
      onTap: () => widget.onNavigate(id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: label != null ? 19 : 22,
            color: isSelected
                ? Colors.black
                : (isFocused ? Colors.white : Colors.white60),
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.black
                    : (isFocused ? Colors.white : Colors.white60),
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                height: 1.0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TvRailButton extends StatelessWidget {
  final String id;
  final String tooltip;
  final Widget child;
  final bool isSelected;
  final bool isFocused;
  final ValueChanged<bool> onFocusChange;
  final VoidCallback onTap;

  const _TvRailButton({
    required this.id,
    required this.tooltip,
    required this.child,
    this.isSelected = false,
    this.isFocused = false,
    required this.onFocusChange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: onFocusChange,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => onTap(),
        ),
      },
      child: Tooltip(
        message: tooltip,
        preferBelow: false,
        verticalOffset: 20,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedScale(
            scale: isFocused ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00E676)
                    : (isFocused ? Colors.white.withOpacity(0.12) : Colors.transparent),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFocused
                      ? const Color(0xFF00E676)
                      : (isSelected ? const Color(0xFF00E676) : Colors.transparent),
                  width: isFocused ? 2.5 : 0.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00E676).withOpacity(0.55),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ]
                    : (isFocused
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E676).withOpacity(0.35),
                              blurRadius: 12,
                            ),
                          ]
                        : null),
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
