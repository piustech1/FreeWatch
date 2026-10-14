import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/app_update_service.dart';

class AppUpdateBanner extends StatefulWidget {
  const AppUpdateBanner({super.key});

  @override
  State<AppUpdateBanner> createState() => _AppUpdateBannerState();
}

class _AppUpdateBannerState extends State<AppUpdateBanner> {
  AppUpdateInfo? _updateInfo;
  bool _dismissed = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    try {
      final info = await AppUpdateService().checkForUpdate();
      if (mounted) {
        setState(() {
          _updateInfo = info;
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _launchStoreListing() async {
    final urlStr = _updateInfo?.storeUrl.isNotEmpty == true
        ? _updateInfo!.storeUrl
        : AppUpdateService.defaultStoreListingUrl;
    try {
      final uri = Uri.parse(urlStr);
      // Attempt external application first (Chrome / Default browser)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback to platform default
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Failed to launch update page: $e');
      // Final fallback attempt
      try {
        final uri = Uri.parse(urlStr);
        await launchUrl(uri);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || _dismissed || _updateInfo == null || !_updateInfo!.hasUpdate) {
      return const SizedBox.shrink();
    }

    final update = _updateInfo!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              // Liquid glass iOS frosted curved surface - no harsh gradients
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Clean Vector Update Icon (No Emojis) in Frosted Glass Squircle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 0.8,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.system_update_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Text Information & Tap Target
                Expanded(
                  child: GestureDetector(
                    onTap: _launchStoreListing,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Update Available',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 7),
                            // Frosted Liquid Glass Version Badge (No green gradients)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                'v${update.version}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Tap to view what\'s new & download latest APK',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.60),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Action Pill Button (Apple App Store style) with direct Material InkWell
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _launchStoreListing,
                    borderRadius: BorderRadius.circular(18),
                    splashColor: Colors.white.withOpacity(0.2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0071E3),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0071E3).withOpacity(0.40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'UPDATE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),

                if (!update.isMandatory) ...[
                  const SizedBox(width: 4),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _dismissed = true),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.45),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
