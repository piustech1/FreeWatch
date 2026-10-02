import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/user_avatar_provider.dart';
import '../../../auth/presentation/screens/choose_avatar_screen.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

/// Dedicated full-screen Profile & Account screen
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _streamingQuality = 'Auto (Up to 4K)';
  String _audioLanguage = 'Luganda (VJ Dubbed)';
  bool _wifiOnlyDownload = true;
  bool _pushNotifications = true;
  int _cacheSizeMb = 142;

  @override
  Widget build(BuildContext context) {
    final avatar = ref.watch(userAvatarProvider);
    final favCount = ref.watch(favoritesProvider).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            // ── Top Title ──────────────────────────────────────────────────
            const Text(
              'My Profile',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 18),

            // ── User Avatar & Identity Card ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF131620),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Active Disney+ Avatar with Edit Ring
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Container(
                            color: const Color(0xFF1E2130),
                            child: Image.asset(
                              avatar.assetPath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openAvatarPicker(context),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.black,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Username
                  const Text(
                    'Pius Tech',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // VIP Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.5),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded,
                            color: AppColors.accent, size: 13),
                        SizedBox(width: 4),
                        Text(
                          'FreeWatch VIP • 4K Unlocked',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // "Change Avatar" Button
                  OutlinedButton.icon(
                    onPressed: () => _openAvatarPicker(context),
                    icon: const Icon(IconlyBold.image,
                        size: 15, color: Colors.white),
                    label: const Text(
                      'Change Disney Avatar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.15)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Streaming Statistics Row ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('24', 'Streamed', IconlyBold.video),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                      '$favCount', 'Watchlist', IconlyBold.heart),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                      '4', 'Offline', Icons.offline_pin_rounded),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Streaming Preferences ───────────────────────────────────────
            const Text(
              'Playback & Streaming',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),

            _buildSectionContainer([
              _buildSettingTile(
                icon: Icons.high_quality_rounded,
                title: 'Streaming Quality',
                subtitle: _streamingQuality,
                onTap: _showQualityPicker,
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.record_voice_over_rounded,
                title: 'Default Translation Audio',
                subtitle: _audioLanguage,
                onTap: _showAudioPicker,
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.wifi_rounded,
                title: 'Download via Wi-Fi only',
                value: _wifiOnlyDownload,
                onChanged: (val) => setState(() => _wifiOnlyDownload = val),
              ),
            ]),

            const SizedBox(height: 24),

            // ── App Settings ────────────────────────────────────────────────
            const Text(
              'App & Storage',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),

            _buildSectionContainer([
              _buildSwitchTile(
                icon: IconlyBold.notification,
                title: 'Push Notifications',
                value: _pushNotifications,
                onChanged: (val) => setState(() => _pushNotifications = val),
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.cleaning_services_rounded,
                title: 'Clear Cache',
                subtitle: '$_cacheSizeMb MB used',
                trailing: TextButton(
                  onPressed: _clearCache,
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w700),
                  ),
                ),
                onTap: _clearCache,
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: 'App Version',
                subtitle: 'FreeWatch v1.0.12 (Official Build 13)',
              ),
            ]),

            const SizedBox(height: 24),

            // ── Sign Out Button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _showSignOutDialog,
                icon: const Icon(IconlyLight.logout,
                    color: Color(0xFFFF5252), size: 18),
                label: const Text(
                  'Log Out of FreeWatch',
                  style: TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: const Color(0xFFFF5252).withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAvatarPicker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ChooseAvatarScreen(),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131620),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131620),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: Colors.white.withOpacity(0.06),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11.5,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: Colors.white30, size: 20)
              : null),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.accent, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      value: value,
      activeColor: AppColors.accent,
      onChanged: onChanged,
    );
  }

  void _showQualityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF10131A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final options = [
          'Auto (Up to 4K)',
          'High (1080p Full HD)',
          'Medium (720p HD)',
          'Data Saver (480p SD)',
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((opt) {
              return ListTile(
                title: Text(opt,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                trailing: _streamingQuality == opt
                    ? const Icon(Icons.check_rounded, color: AppColors.accent)
                    : null,
                onTap: () {
                  setState(() => _streamingQuality = opt);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showAudioPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF10131A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final options = [
          'Luganda (VJ Dubbed)',
          'Original English Audio',
          'Always Ask on Playback',
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((opt) {
              return ListTile(
                title: Text(opt,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                trailing: _audioLanguage == opt
                    ? const Icon(Icons.check_rounded, color: AppColors.accent)
                    : null,
                onTap: () {
                  setState(() => _audioLanguage = opt);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _clearCache() {
    setState(() => _cacheSizeMb = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF161922),
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.accent),
            SizedBox(width: 8),
            Text('App cache successfully cleared (0 MB)'),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161922),
        title: const Text('Log Out',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text(
          'Are you sure you want to log out of FreeWatch on this device?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/onboarding');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
