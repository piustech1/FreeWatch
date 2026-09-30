import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/avatar_item.dart';

const String _prefKeyAvatarPath = 'selected_user_avatar_path';

class UserAvatarNotifier extends StateNotifier<AvatarItem> {
  UserAvatarNotifier() : super(AvatarItem.defaultAvatar) {
    _loadSavedAvatar();
  }

  Future<void> _loadSavedAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString(_prefKeyAvatarPath);
      if (savedPath != null && savedPath.isNotEmpty) {
        state = AvatarItem.fromAsset(savedPath);
      }
    } catch (_) {
      // Fallback to default
    }
  }

  Future<void> setAvatar(AvatarItem avatar) async {
    state = avatar;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyAvatarPath, avatar.assetPath);
    } catch (_) {}
  }
}

final userAvatarProvider =
    StateNotifierProvider<UserAvatarNotifier, AvatarItem>((ref) {
  return UserAvatarNotifier();
});
