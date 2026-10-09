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
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.section,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.linkedMovie,
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
      isRead: isRead ?? this.isRead,
    );
  }
}
