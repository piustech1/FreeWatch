import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Floating capsule pill navigation bar matching the design with neon green active state
class FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 0, 36, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.floatingNav,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: AppColors.floatingNavBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.08),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavBarItem(
                    icon: Icons.home,
                    isSelected: selectedIndex == 0,
                    onTap: () => onItemSelected(0),
                  ),
                  _NavBarItem(
                    icon: Icons.search,
                    isSelected: selectedIndex == 1,
                    onTap: () => onItemSelected(1),
                  ),
                  _NavBarItem(
                    icon: Icons.favorite,
                    isSelected: selectedIndex == 2,
                    onTap: () => onItemSelected(2),
                  ),
                  _NavBarItem(
                    icon: Icons.person,
                    isSelected: selectedIndex == 3,
                    onTap: () => onItemSelected(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.accent.withOpacity(0.18),
                shape: BoxShape.circle,
              )
            : const BoxDecoration(),
        child: Icon(
          icon,
          color: isSelected ? AppColors.accent : AppColors.textHint,
          size: 24,
        ),
      ),
    );
  }
}
