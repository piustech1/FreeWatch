import 'package:flutter_test/flutter_test.dart';
import 'package:freewatch/core/services/app_update_service.dart';

void main() {
  group('AppUpdateService.isRemoteVersionNewer tests', () {
    test('Returns false when remote and local versions & builds are identical', () {
      final isNewer = AppUpdateService.isRemoteVersionNewer(
        remoteVersion: '1.0.69',
        remoteBuild: 70,
        localVersion: '1.0.69',
        localBuild: 70,
      );
      expect(isNewer, isFalse);
    });

    test('Returns false when remote tag has v prefix matching installed version', () {
      final isNewer = AppUpdateService.isRemoteVersionNewer(
        remoteVersion: 'v1.0.69',
        remoteBuild: 0,
        localVersion: '1.0.69',
        localBuild: 70,
      );
      expect(isNewer, isFalse);
    });

    test('Returns false when remote version is older than local version', () {
      final isNewer = AppUpdateService.isRemoteVersionNewer(
        remoteVersion: 'v1.0.68',
        remoteBuild: 69,
        localVersion: '1.0.69',
        localBuild: 70,
      );
      expect(isNewer, isFalse);
    });

    test('Returns true when remote semantic version is strictly newer (GitHub release)', () {
      final isNewer = AppUpdateService.isRemoteVersionNewer(
        remoteVersion: 'v1.0.70',
        remoteBuild: 0,
        localVersion: '1.0.69',
        localBuild: 70,
      );
      expect(isNewer, isTrue);
    });

    test('Returns true when remote major or minor version is newer', () {
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteVersion: '2.0.0',
          remoteBuild: 0,
          localVersion: '1.0.69',
          localBuild: 70,
        ),
        isTrue,
      );

      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteVersion: '1.1.0',
          remoteBuild: 0,
          localVersion: '1.0.69',
          localBuild: 70,
        ),
        isTrue,
      );
    });

    test('Returns true when semantic versions match but remote build number is higher', () {
      final isNewer = AppUpdateService.isRemoteVersionNewer(
        remoteVersion: '1.0.69',
        remoteBuild: 75,
        localVersion: '1.0.69',
        localBuild: 70,
      );
      expect(isNewer, isTrue);
    });

    test('Returns false when semantic versions match and remote build number is lower or equal', () {
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteVersion: '1.0.69',
          remoteBuild: 65,
          localVersion: '1.0.69',
          localBuild: 70,
        ),
        isFalse,
      );

      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteVersion: '1.0.69',
          remoteBuild: 70,
          localVersion: '1.0.69',
          localBuild: 70,
        ),
        isFalse,
      );
    });

    test('Handles embedded build numbers with + sign correctly', () {
      // 1.0.69+70 vs 1.0.69+70 -> false
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteVersion: '1.0.69+70',
          remoteBuild: 0,
          localVersion: '1.0.69+70',
          localBuild: 0,
        ),
        isFalse,
      );

      // 1.0.70+71 vs 1.0.69+70 -> true
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteVersion: '1.0.70+71',
          remoteBuild: 0,
          localVersion: '1.0.69+70',
          localBuild: 0,
        ),
        isTrue,
      );

      // 1.0.69+75 vs 1.0.69+70 -> true
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteVersion: '1.0.69+75',
          remoteBuild: 0,
          localVersion: '1.0.69+70',
          localBuild: 0,
        ),
        isTrue,
      );
    });
  });
}
