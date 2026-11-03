import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String version;
  final int buildNumber;
  final String releaseNotes;
  final String storeUrl;
  final String? directApkUrl;
  final bool isMandatory;

  const AppUpdateInfo({
    this.hasUpdate = false,
    this.version = '',
    this.buildNumber = 0,
    this.releaseNotes = '',
    this.storeUrl = 'https://freewatchug.online/store',
    this.directApkUrl,
    this.isMandatory = false,
  });
}

/// Central service dynamically monitoring GitHub Releases & Firebase RTDB for application updates.
/// Guarantees the update banner only appears when a genuinely NEWER version exists.
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  // Fallback defaults matching current pubspec version 1.0.69+70
  static const int defaultBuildNumber = 70;
  static const String defaultVersionName = '1.0.69';
  static const String defaultStoreListingUrl = 'https://freewatchug.online/store';

  Future<void> _notifyUserOfUpdate(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notified_update_$version';
      if (prefs.getBool(key) == true) return;
      await prefs.setBool(key, true);

      await NotificationService().showMovieNotification(
        id: 999999,
        title: '🚀 FreeWatch Update (v$version) Available',
        body: 'A new version of FreeWatch is ready! Tap here to update and enjoy smoother streaming.',
        payload: '/update',
      );
    } catch (_) {}
  }

  /// Strictly determines if [remoteVersion] or [remoteBuild] is newer than the locally installed app
  static bool isRemoteVersionNewer({
    required String remoteVersion,
    required int remoteBuild,
    required String localVersion,
    required int localBuild,
  }) {
    // Extract build number if embedded with '+' e.g. "1.0.69+70"
    String cleanRemote = remoteVersion.trim();
    String cleanLocal = localVersion.trim();

    if (cleanRemote.contains('+')) {
      final parts = cleanRemote.split('+');
      cleanRemote = parts[0];
      if (remoteBuild == 0 && parts.length > 1) {
        remoteBuild = int.tryParse(parts[1]) ?? remoteBuild;
      }
    }

    if (cleanLocal.contains('+')) {
      final parts = cleanLocal.split('+');
      cleanLocal = parts[0];
      if (localBuild == 0 && parts.length > 1) {
        localBuild = int.tryParse(parts[1]) ?? localBuild;
      }
    }

    // Strip leading 'v' or non-numeric/dot characters
    cleanRemote = cleanRemote.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    cleanLocal = cleanLocal.replaceAll(RegExp(r'[^0-9.]'), '').trim();

    if (cleanRemote.isEmpty) return false;
    if (cleanLocal.isEmpty) return true;

    final rParts = cleanRemote.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final lParts = cleanLocal.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    // 1. Semantic version comparison (Major.Minor.Patch)
    final maxLen = rParts.length > lParts.length ? rParts.length : lParts.length;
    for (int i = 0; i < maxLen; i++) {
      final r = i < rParts.length ? rParts[i] : 0;
      final l = i < lParts.length ? lParts[i] : 0;
      if (r > l) return true; // Remote semantic version is strictly higher
      if (r < l) return false; // Remote semantic version is strictly lower
    }

    // 2. If semantic versions are identical, compare build numbers if both are known and positive
    if (remoteBuild > 0 && localBuild > 0) {
      return remoteBuild > localBuild;
    }

    // Identical versions and no higher build number -> up to date!
    return false;
  }

  /// Get the actual installed app version and build number from the OS
  Future<Map<String, dynamic>> getInstalledAppInfo() async {
    String versionName = defaultVersionName;
    int buildNumber = defaultBuildNumber;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (packageInfo.version.trim().isNotEmpty) {
        var v = packageInfo.version.trim();
        if (v.startsWith('v')) v = v.substring(1).trim();
        if (v.isNotEmpty) versionName = v;
      }
      final parsedBuild = int.tryParse(packageInfo.buildNumber.trim());
      if (parsedBuild != null && parsedBuild > 0) {
        buildNumber = parsedBuild;
      }
    } catch (e) {
      debugPrint('[AppUpdateService] PackageInfo lookup fallback: $e');
    }

    return {
      'version': versionName,
      'build': buildNumber,
    };
  }

  /// Check GitHub Releases and Firebase RTDB for a genuinely newer release
  Future<AppUpdateInfo> checkForUpdate() async {
    final localInfo = await getInstalledAppInfo();
    final localVersion = localInfo['version'] as String;
    final localBuild = localInfo['build'] as int;

    debugPrint('[AppUpdateService] Local App Version: $localVersion+$localBuild');

    // 1. Direct GitHub Releases API Check (Automated source of truth)
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ),
      );

      final response = await dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/piustech1/FreeWatch/releases/latest',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final tagName = data['tag_name']?.toString() ?? ''; // e.g. "v1.0.69"
        final body = data['body']?.toString() ?? '';
        final cleanTag = tagName.replaceAll('v', '').trim();

        final isNewer = isRemoteVersionNewer(
          remoteVersion: cleanTag,
          remoteBuild: 0,
          localVersion: localVersion,
          localBuild: localBuild,
        );

        if (isNewer) {
          debugPrint('[AppUpdateService] Newer GitHub release found: $cleanTag > $localVersion');

          String? apkUrl;
          if (data['assets'] is List) {
            final assets = data['assets'] as List;
            // Prefer FreeWatch-release.apk
            for (final a in assets) {
              if (a is Map) {
                final name = a['name']?.toString() ?? '';
                if (name == 'FreeWatch-release.apk') {
                  apkUrl = a['browser_download_url']?.toString();
                  break;
                }
              }
            }
            // Fallback to any .apk asset
            if (apkUrl == null) {
              for (final a in assets) {
                if (a is Map && a['name']?.toString().endsWith('.apk') == true) {
                  apkUrl = a['browser_download_url']?.toString();
                  break;
                }
              }
            }
          }

          _notifyUserOfUpdate(cleanTag);
          return AppUpdateInfo(
            hasUpdate: true,
            version: cleanTag,
            buildNumber: localBuild + 1,
            releaseNotes: body.isNotEmpty
                ? body
                : 'FreeWatch $cleanTag brings offline storage improvements, chat alerts, and player updates.',
            storeUrl: defaultStoreListingUrl,
            directApkUrl: apkUrl,
            isMandatory: false,
          );
        } else {
          debugPrint('[AppUpdateService] GitHub release $cleanTag is current or older than installed $localVersion');
        }
      }
    } catch (e) {
      debugPrint('[AppUpdateService] GitHub check notice: $e');
    }

    // 2. Firebase RTDB app_config/update check (secondary / administrative overrides)
    try {
      final snap = await FirebaseDatabase.instance
          .ref('app_config/update')
          .get()
          .timeout(const Duration(seconds: 3));

      if (snap.exists && snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        final latestBuild = (data['latest_build'] as num?)?.toInt() ?? 0;
        final latestVersion = data['latest_version']?.toString() ?? '';
        final storeUrl = data['store_url']?.toString() ?? defaultStoreListingUrl;
        final directApkUrl = data['direct_apk_url']?.toString();
        final releaseNotes = data['release_notes']?.toString() ??
            'New features, performance enhancements, and stability improvements.';
        final isMandatory = data['is_mandatory'] == true;
        final showBanner = data['show_banner'] != false;

        final isNewer = isRemoteVersionNewer(
          remoteVersion: latestVersion,
          remoteBuild: latestBuild,
          localVersion: localVersion,
          localBuild: localBuild,
        );

        // An update is ONLY returned if remote version is strictly newer than installed app!
        if (isNewer && (showBanner || isMandatory)) {
          debugPrint('[AppUpdateService] Newer RTDB update available: $latestVersion+$latestBuild > $localVersion+$localBuild');
          _notifyUserOfUpdate(latestVersion.isNotEmpty ? latestVersion : '1.0.69');
          return AppUpdateInfo(
            hasUpdate: true,
            version: latestVersion.isNotEmpty ? latestVersion : '1.0.69',
            buildNumber: latestBuild > 0 ? latestBuild : localBuild + 1,
            releaseNotes: releaseNotes,
            storeUrl: storeUrl.isNotEmpty ? storeUrl : defaultStoreListingUrl,
            directApkUrl: directApkUrl,
            isMandatory: isMandatory,
          );
        } else {
          debugPrint('[AppUpdateService] RTDB release ($latestVersion+$latestBuild) is current or older than installed ($localVersion+$localBuild)');
        }
      }
    } catch (e) {
      debugPrint('[AppUpdateService] RTDB check notice: $e');
    }

    // Installed app is up to date! Banner will NOT show.
    return const AppUpdateInfo(hasUpdate: false);
  }
}
