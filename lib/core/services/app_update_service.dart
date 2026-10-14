import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

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

/// Central service monitoring GitHub Releases & Firebase RTDB for future application updates
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  // Current installed app build version metadata
  static const int currentBuildNumber = 57; // v1.0.56 release build
  static const String currentVersionName = '1.0.56';
  static const String defaultStoreListingUrl = 'https://freewatch-piustech.vercel.app/download';

  /// Query latest release from Firebase RTDB and fallback to GitHub Releases
  Future<AppUpdateInfo> checkForUpdate() async {
    // 1. Try Firebase RTDB app_config/update first for instantaneous config
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

        if (latestBuild > currentBuildNumber ||
            (latestVersion.isNotEmpty && latestVersion != currentVersionName)) {
          return AppUpdateInfo(
            hasUpdate: true,
            version: latestVersion.isNotEmpty ? latestVersion : '1.0.56',
            buildNumber: latestBuild > 0 ? latestBuild : 57,
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

    // 2. Direct GitHub Releases API Fallback
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
        final tagName = data['tag_name']?.toString() ?? ''; // e.g. "v1.0.56"
        final body = data['body']?.toString() ?? '';
        final cleanTag = tagName.replaceAll('v', '').trim();

        // Extract build number or version comparison
        final remoteVersionParts = cleanTag.split('.');
        final localVersionParts = currentVersionName.split('.');

        bool hasNewerVersion = false;
        for (int i = 0; i < remoteVersionParts.length && i < localVersionParts.length; i++) {
          final r = int.tryParse(remoteVersionParts[i]) ?? 0;
          final l = int.tryParse(localVersionParts[i]) ?? 0;
          if (r > l) {
            hasNewerVersion = true;
            break;
          } else if (r < l) {
            break;
          }
        }

        if (hasNewerVersion) {
          // Look for APK release asset download URL
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
            buildNumber: currentBuildNumber + 1,
            releaseNotes: body.isNotEmpty
                ? body
                : 'FreeWatch $cleanTag brings offline storage improvements, chat alerts, and player updates.',
            storeUrl: defaultStoreListingUrl,
            directApkUrl: apkUrl,
            isMandatory: false,
          );
        }
      }
    } catch (e) {
      debugPrint('[AppUpdateService] GitHub check notice: $e');
    }

    return const AppUpdateInfo(hasUpdate: false);
  }
}
