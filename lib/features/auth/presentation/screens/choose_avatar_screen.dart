import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/avatar_item.dart';
import '../providers/user_avatar_provider.dart';

class ChooseAvatarScreen extends ConsumerStatefulWidget {
  const ChooseAvatarScreen({super.key});

  @override
  ConsumerState<ChooseAvatarScreen> createState() => _ChooseAvatarScreenState();
}

class _ChooseAvatarScreenState extends ConsumerState<ChooseAvatarScreen> {
  late AvatarItem _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = ref.read(userAvatarProvider);
  }

  void _onAvatarTapped(AvatarItem avatar) {
    HapticFeedback.selectionClick();
    setState(() {
      _tempSelected = avatar;
    });
  }

  void _saveAndClose() {
    ref.read(userAvatarProvider.notifier).setAvatar(_tempSelected);
    Navigator.of(context).pop(_tempSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1017),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar (Back, Title, Skip/Done) ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(_tempSelected),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Choose Avatar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _saveAndClose,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'DONE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Scrollable Avatar Sections ────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Featured
                    _buildSectionHeader(AvatarItem.categoryFeatured),
                    const SizedBox(height: 16),
                    _buildAvatarGrid(AvatarItem.featuredAvatars),

                    const SizedBox(height: 36),

                    // Section 2: Disney
                    _buildSectionHeader(AvatarItem.categoryDisney),
                    const SizedBox(height: 16),
                    _buildAvatarGrid(AvatarItem.disneyAvatars),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildAvatarGrid(List<AvatarItem> avatars) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute columns based on width (typically 3 on phone)
        final int crossAxisCount = constraints.maxWidth > 500 ? 4 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 18,
            crossAxisSpacing: 16,
            childAspectRatio: 0.82,
          ),
          itemCount: avatars.length,
          itemBuilder: (context, index) {
            final avatar = avatars[index];
            final bool isSelected = avatar.id == _tempSelected.id;

            return GestureDetector(
              onTap: () => _onAvatarTapped(avatar),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circular Avatar with Disney+ Selection Ring
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.35),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1C1E2A),
                        ),
                        child: Image.asset(
                          avatar.assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.person_rounded,
                              color: AppColors.textHint,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Character Name
                  Text(
                    avatar.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
