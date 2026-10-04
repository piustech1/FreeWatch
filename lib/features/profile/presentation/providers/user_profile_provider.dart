import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String name;
  final String bio;
  final String dateJoined;
  final int moviesWatched;
  final double averageRating;
  final double avgWatchTimeHours;
  final int totalDownloads;
  final int followingCount;
  final int followersCount;

  const UserProfile({
    required this.name,
    this.bio = 'Action & Sci-Fi enthusiast • Luganda dubbed movie lover',
    this.dateJoined = 'October 2024',
    this.moviesWatched = 129,
    this.averageRating = 3.8,
    this.avgWatchTimeHours = 48.5,
    this.totalDownloads = 14,
    this.followingCount = 52,
    this.followersCount = 84,
  });

  UserProfile copyWith({
    String? name,
    String? bio,
    String? dateJoined,
    int? moviesWatched,
    double? averageRating,
    double? avgWatchTimeHours,
    int? totalDownloads,
    int? followingCount,
    int? followersCount,
  }) {
    return UserProfile(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      dateJoined: dateJoined ?? this.dateJoined,
      moviesWatched: moviesWatched ?? this.moviesWatched,
      averageRating: averageRating ?? this.averageRating,
      avgWatchTimeHours: avgWatchTimeHours ?? this.avgWatchTimeHours,
      totalDownloads: totalDownloads ?? this.totalDownloads,
      followingCount: followingCount ?? this.followingCount,
      followersCount: followersCount ?? this.followersCount,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  static const _prefKeyUserName = 'freewatch_user_profile_name';
  static const _prefKeyUserBio = 'freewatch_user_profile_bio';

  UserProfileNotifier() : super(const UserProfile(name: 'Toby Taylor')) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_prefKeyUserName);
      final savedBio = prefs.getString(_prefKeyUserBio);
      state = state.copyWith(
        name: savedName != null && savedName.trim().isNotEmpty
            ? savedName.trim()
            : state.name,
        bio: savedBio != null && savedBio.trim().isNotEmpty
            ? savedBio.trim()
            : state.bio,
      );
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

  Future<void> updateProfile({required String name, required String bio}) async {
    final trimmedName = name.trim();
    final trimmedBio = bio.trim();
    if (trimmedName.isEmpty) return;
    state = state.copyWith(
      name: trimmedName,
      bio: trimmedBio.isNotEmpty ? trimmedBio : state.bio,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyUserName, trimmedName);
      if (trimmedBio.isNotEmpty) {
        await prefs.setString(_prefKeyUserBio, trimmedBio);
      }
    } catch (_) {}
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});
