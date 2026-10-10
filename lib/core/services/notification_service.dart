import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

/// Central Notification Service managing OS-level device notifications
/// with rich BigPicture support for movie posters and backdrops.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'freewatch_alerts';
  static const String channelName = 'FreeWatch New Releases';
  static const String channelDescription =
      'Real-time alerts for newly uploaded movies, series, and VJ translations';

  bool _isInitialized = false;

  Future<void> initialize({void Function(NotificationResponse)? onNotificationTap}) async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: onNotificationTap,
      );

      // Create Android Notification Channel & Request permissions
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlatform.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Downloads remote image to temporary file for BigPictureStyleInformation
  Future<String?> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null && response.data!.isNotEmpty) {
        await file.writeAsBytes(response.data!);
        return filePath;
      }
    } catch (e) {
      debugPrint('Failed to download notification image: $e');
    }
    return null;
  }

  /// Displays OS-level device notification with movie banner / backdrop
  Future<void> showMovieNotification({
    required int id,
    required String title,
    required String body,
    String? imageUrl,
    String? payload,
  }) async {
    try {
      String? localImagePath;
      if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
        final cleanFileName = 'notif_${id}_${imageUrl.hashCode.abs()}.jpg';
        localImagePath = await _downloadAndSaveFile(imageUrl, cleanFileName);
      }

      StyleInformation? styleInformation;
      if (localImagePath != null) {
        styleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(localImagePath),
          largeIcon: FilePathAndroidBitmap(localImagePath),
          contentTitle: '🎬 $title',
          summaryText: body,
          hideExpandedLargeIcon: true,
        );
      } else {
        styleInformation = BigTextStyleInformation(
          body,
          contentTitle: '🎬 $title',
        );
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: styleInformation,
        color: const Color(0xFF00E676),
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        attachments: localImagePath != null
            ? [DarwinNotificationAttachment(localImagePath)]
            : null,
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show movie notification: $e');
    }
  }
}
