import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
    this.storeUrl = 'https://freewatch-piustech.vercel.app/download',
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

  // Fallback defaults matching current pubspec version 1.0.58+59
  static const int defaultBuildNumber = 59;
  static const String defaultVersionName = '1.0.58';
  static const String defaultStoreListingUrl = 'https://freewatch-piustech.vercel.app/';

  /// Strictly determines if [remoteVersion] or [remoteBuild] is newer than the locally installed app
  static bool isRemoteVersionNewer({
    required String remoteVersion,
    required int remoteBuild,
    required String localVersion,
    required int localBuild,
  }) {
    // 1. If remote build number is provided and both are positive, compare build numbers
    if (remoteBuild > 0 && localBuild > 0) {
      if (remoteBuild > localBuild) return true;
      if (remoteBuild < localBuild) return false;
      // If build numbers are equal, check semantic version below as secondary
    }

    // 2. Semantic version comparison e.g. "1.0.59" > "1.0.58"
    final cleanRemote = remoteVersion.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    final cleanLocal = localVersion.replaceAll(RegExp(r'[^0-9.]'), '').trim();

    if (cleanRemote.isEmpty) return false;
    if (cleanLocal.isEmpty) return true;

    final rParts = cleanRemote.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final lParts = cleanLocal.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    final maxLen = rParts.length > lParts.length ? rParts.length : lParts.length;
    for (int i = 0; i < maxLen; i++) {
      final r = i < rParts.length ? rParts[i] : 0;
      final l = i < lParts.length ? lParts[i] : 0;
      if (r > l) return true;
      if (r < l) return false;
    }

    // If version numbers are identical, this is the current release
    return false;
  }

  /// Get the actual installed app version and build number from the OS
  Future<Map<String, dynamic>> getInstalledAppInfo() async {
    String versionName = defaultVersionName;
    int buildNumber = defaultBuildNumber;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (packageInfo.version.isNotEmpty) {
        versionName = packageInfo.version;
      }
      final parsedBuild = int.tryParse(packageInfo.buildNumber);
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
        final tagName = data['tag_name']?.toString() ?? ''; // e.g. "v1.0.58"
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
            for (final a in assets) {
              if (a is Map && a['name']?.toString().endsWith('.apk') == true) {
                apkUrl = a['browser_download_url']?.toString();
                break;
              }
            }
          }

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

        final isNewer = isRemoteVersionNewer(
          remoteVersion: latestVersion,
          remoteBuild: latestBuild,
          localVersion: localVersion,
          localBuild: localBuild,
        );

        // Strictly require that the RTDB release is genuinely newer than local installed app
        if (isNewer) {
          debugPrint('[AppUpdateService] Newer RTDB version found: $latestVersion+$latestBuild');
          return AppUpdateInfo(
            hasUpdate: true,
            version: latestVersion.isNotEmpty ? latestVersion : '1.0.59',
            buildNumber: latestBuild > 0 ? latestBuild : localBuild + 1,
            releaseNotes: releaseNotes,
            storeUrl: storeUrl.isNotEmpty ? storeUrl : defaultStoreListingUrl,
            directApkUrl: directApkUrl,
            isMandatory: isMandatory,
          );
        }
      }
    } catch (e) {
      debugPrint('[AppUpdateService] RTDB check notice: $e');
    }

    // Installed app is up to date! Banner will NOT show.
    return const AppUpdateInfo(hasUpdate: false);
  }
}
