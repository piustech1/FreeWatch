import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';

Future<void> _persistToAppNotificationCenter({
  required String id,
  required String? title,
  required String message,
  String? imageUrl,
  String? link,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString('freewatch_user_notifications_v1');
    List<dynamic> list = [];
    if (savedJson != null && savedJson.isNotEmpty) {
      list = jsonDecode(savedJson) as List<dynamic>;
    }
    // Prevent duplicate entries
    if (list.any((e) => e is Map && e['id'] == id)) return;

    final newItem = {
      'id': id,
      'section': 'Today',
      'title': title,
      'message': message,
      'time': 'Just now',
      'imageUrl': imageUrl,
      'link': link,
      'iconColor': 0xFFC084FC,
      'isRead': false,
    };
    list.insert(0, newItem);
    await prefs.setString('freewatch_user_notifications_v1', jsonEncode(list));
  } catch (_) {}
}

/// Top-level background message handler required by FirebaseMessaging on Android/iOS
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  debugPrint('FCM background message received: ${message.messageId}');
  final notification = message.notification;
  final data = message.data;

  final title = notification?.title ?? data['title'] ?? 'FreeWatch New Release';
  final body = notification?.body ?? data['body'] ?? 'Watch the latest translated releases now!';
  final imageUrl = data['imageUrl'] ?? data['image'] ?? notification?.android?.imageUrl;
  final link = data['link'] ?? data['url'] ?? data['movieId'] ?? data['payload'];

  // Persist into user notifications feed
  await _persistToAppNotificationCenter(
    id: message.messageId ?? 'bg_${DateTime.now().millisecondsSinceEpoch}',
    title: title,
    message: body,
    imageUrl: imageUrl,
    link: link,
  );

  await NotificationService().showMovieNotification(
    id: message.messageId.hashCode,
    title: title,
    body: body,
    imageUrl: imageUrl,
    payload: link,
  );
}

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

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
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

      // Explicitly prompt user for OS-level notification permissions via Firebase Messaging
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('FCM user granted notification permission: ${settings.authorizationStatus}');

      // Subscribe to global FreeWatch broadcast topics for real-time cloud push alerts
      try {
        await messaging.subscribeToTopic('all_users');
        await messaging.subscribeToTopic('new_releases');
        debugPrint('Subscribed to FCM topics: all_users, new_releases');
      } catch (e) {
        debugPrint('FCM topic subscription notice: $e');
      }

      // Foreground message listener for real-time alerts while app is open
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM foreground message received: ${message.messageId}');
        final notification = message.notification;
        final data = message.data;
        final title = notification?.title ?? data['title'] ?? 'FreeWatch New Release';
        final body = notification?.body ?? data['body'] ?? 'Watch the latest releases now!';
        final imageUrl = data['imageUrl'] ?? data['image'] ?? notification?.android?.imageUrl;
        final link = data['link'] ?? data['url'] ?? data['movieId'] ?? data['payload'];

        _persistToAppNotificationCenter(
          id: message.messageId ?? 'fg_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          message: body,
          imageUrl: imageUrl,
          link: link,
        );

        showMovieNotification(
          id: message.messageId.hashCode,
          title: title,
          body: body,
          imageUrl: imageUrl,
          payload: link,
        );
      });

      // Schedule OS-level recurring alerts that trigger even when the app is closed
      await scheduleRecurringAlerts();

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
        icon: '@drawable/ic_notification',
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

  /// Schedules daily OS-level release alerts that fire even when the app is
  /// completely closed, killed from recents, or the device was restarted.
  Future<void> scheduleRecurringAlerts() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFF00E676),
        icon: '@drawable/ic_notification',
        enableVibration: true,
        playSound: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      // Cancel previous periodic alert to avoid stacking
      await _notificationsPlugin.cancel(77701);

      // Schedule recurring daily alert via OS AlarmManager
      await _notificationsPlugin.periodicallyShow(
        77701,
        '🎬 Trending on FreeWatch',
        'New Luganda translated movies & series are now streaming for free! Tap to explore today\'s top releases.',
        RepeatInterval.daily,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('scheduleRecurringAlerts error: $e');
    }
  }
}
