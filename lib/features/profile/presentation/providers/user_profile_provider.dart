import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String name;
  final int moviesWatched;
  final double averageRating;
  final int followingCount;
  final int followersCount;

  const UserProfile({
    required this.name,
    this.moviesWatched = 129,
    this.averageRating = 3.8,
    this.followingCount = 52,
    this.followersCount = 84,
  });

  UserProfile copyWith({
    String? name,
    int? moviesWatched,
    double? averageRating,
    int? followingCount,
    int? followersCount,
  }) {
    return UserProfile(
      name: name ?? this.name,
      moviesWatched: moviesWatched ?? this.moviesWatched,
      averageRating: averageRating ?? this.averageRating,
      followingCount: followingCount ?? this.followingCount,
      followersCount: followersCount ?? this.followersCount,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  static const _prefKeyUserName = 'freewatch_user_profile_name';

  UserProfileNotifier() : super(const UserProfile(name: 'Toby Taylor')) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_prefKeyUserName);
      if (savedName != null && savedName.trim().isNotEmpty) {
        state = state.copyWith(name: savedName.trim());
      }
    } catch (_) {}
  }

  Future<void> updateName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(name: trimmed);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyUserName, trimmed);
    } catch (_) {}
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});
