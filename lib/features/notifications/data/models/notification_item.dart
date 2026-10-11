import 'package:flutter/material.dart';
import '../../../../data/models/movie.dart';

class NotificationItem {
  final String id;
  final String section; // 'Today', 'This week', 'Earlier'
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Movie? linkedMovie;
  final String? imageUrl;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.section,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.linkedMovie,
    this.imageUrl,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    String? section,
    String? message,
    String? time,
    IconData? icon,
    Color? iconColor,
    Movie? linkedMovie,
    String? imageUrl,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      section: section ?? this.section,
      message: message ?? this.message,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      linkedMovie: linkedMovie ?? this.linkedMovie,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      section: json['section'] as String? ?? 'Today',
      message: json['message'] as String? ?? '',
      time: json['time'] as String? ?? 'Just now',
      icon: Icons.movie_filter_rounded,
      iconColor: json['iconColor'] != null
          ? Color(json['iconColor'] as int)
          : const Color(0xFFC084FC),
      linkedMovie: json['linkedMovie'] != null
          ? Movie.fromJson(Map<String, dynamic>.from(json['linkedMovie'] as Map))
          : null,
      imageUrl: json['imageUrl'] as String?,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'section': section,
        'message': message,
        'time': time,
        'iconColor': iconColor.value,
        if (linkedMovie != null) 'linkedMovie': linkedMovie!.toJson(),
        if (imageUrl != null) 'imageUrl': imageUrl,
        'isRead': isRead,
      };
}
