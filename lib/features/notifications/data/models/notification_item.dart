import 'package:flutter/material.dart';
import '../../../../data/models/movie.dart';

class NotificationItem {
  final String id;
  final String section; // 'Today', 'This week', 'Earlier'
  final String? title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Movie? linkedMovie;
  final String? imageUrl;
  final String? link;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.section,
    this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.linkedMovie,
    this.imageUrl,
    this.link,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    String? section,
    String? title,
    String? message,
    String? time,
    IconData? icon,
    Color? iconColor,
    Movie? linkedMovie,
    String? imageUrl,
    String? link,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      section: section ?? this.section,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      linkedMovie: linkedMovie ?? this.linkedMovie,
      imageUrl: imageUrl ?? this.imageUrl,
      link: link ?? this.link,
      isRead: isRead ?? this.isRead,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      section: json['section'] as String? ?? 'Today',
      title: json['title'] as String?,
      message: json['message'] as String? ?? json['body'] as String? ?? '',
      time: json['time'] as String? ?? 'Just now',
      icon: Icons.movie_filter_rounded,
      iconColor: json['iconColor'] != null
          ? Color(json['iconColor'] as int)
          : const Color(0xFFC084FC),
      linkedMovie: json['linkedMovie'] != null
          ? Movie.fromJson(Map<String, dynamic>.from(json['linkedMovie'] as Map))
          : null,
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      link: json['link'] as String? ?? json['url'] as String? ?? json['payload'] as String?,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'section': section,
        if (title != null) 'title': title,
        'message': message,
        'time': time,
        'iconColor': iconColor.value,
        if (linkedMovie != null) 'linkedMovie': linkedMovie!.toJson(),
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (link != null) 'link': link,
        'isRead': isRead,
      };
}
