import 'package:firebase_auth/firebase_auth.dart';
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
    this.bio = 'Luganda dubbed movie lover • Streaming on FreeWatch',
    this.dateJoined = 'Joined Recently',
    this.moviesWatched = 0,
    this.averageRating = 0.0,
    this.avgWatchTimeHours = 0.0,
    this.totalDownloads = 0,
    this.followingCount = 0,
    this.followersCount = 0,
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

  UserProfileNotifier() : super(const UserProfile(name: 'FreeWatch Member')) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_prefKeyUserName);
      final savedBio = prefs.getString(_prefKeyUserBio);

      String resolvedName = state.name;
      if (savedName != null && savedName.trim().isNotEmpty) {
        resolvedName = savedName.trim();
      } else {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser?.displayName != null && currentUser!.displayName!.trim().isNotEmpty) {
          resolvedName = currentUser.displayName!.trim();
        } else if (currentUser?.email != null && currentUser!.email!.isNotEmpty) {
          resolvedName = currentUser.email!.split('@').first;
        }
      }

      state = state.copyWith(
        name: resolvedName,
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
