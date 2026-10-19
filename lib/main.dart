import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';
import 'core/services/movie_notification_tracker.dart';
import 'core/services/user_presence_service.dart';
import 'core/services/support_chat_notification_service.dart';
import 'core/services/admob_service.dart';
import 'core/services/device_type_service.dart';
import 'core/router/app_router.dart';
import 'features/favorites/presentation/providers/favorites_provider.dart';
import 'features/profile/presentation/providers/watch_history_provider.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with FreeWatch project configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Register background messaging handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize device OS notifications service with deep-link navigation
  try {
    await NotificationService().initialize(
      onNotificationTap: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          if (payload == '/developer-chat' || payload == '/chat') {
            appRouter.push('/developer-chat');
          } else if (payload.startsWith('/')) {
            appRouter.push(payload);
          } else if (int.tryParse(payload) != null) {
            appRouter.push('/movie/$payload');
          }
        }
      },
    );
  } catch (e) {
    debugPrint('Notification service initialization notice: $e');
  }

  // Initialize real-time presence & connection monitoring
  try {
    UserPresenceService().initialize();
  } catch (e) {
    debugPrint('User presence service initialization notice: $e');
  }

  // Initialize real-time admin support chat response listener
  try {
    await SupportChatNotificationService().initialize();
  } catch (e) {
    debugPrint('Support chat notification service initialization notice: $e');
  }

  // Initialize AdMob Interstitial Ads
  try {
    await AdmobService().initialize();
  } catch (e) {
    debugPrint('AdMob initialization notice: $e');
  }

  // Apply device orientations (landscape for Android TV, portrait for phones)
  try {
    await DeviceTypeService().applyDeviceOrientations();
  } catch (e) {
    debugPrint('Orientation configuration notice: $e');
  }

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Riverpod root container
  final container = ProviderContainer();

  // Listen to Firebase Auth state to synchronize user-scoped favorites, watch history, and chat alerts
  try {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      container.read(favoritesProvider.notifier).syncWithUser(user?.uid);
      container.read(watchHistoryProvider.notifier).syncWithUser(user?.uid);
      if (user?.uid != null) {
        NotificationService().subscribeToUserTopic(user!.uid);
        SupportChatNotificationService().startListening(user.uid);
      }
    });
  } catch (e) {
    debugPrint('Auth state sync listener notice: $e');
  }

  // Start background monitoring of MumoWatch database for new uploads
  try {
    MovieNotificationTracker(container).startTracking();
  } catch (e) {
    debugPrint('Movie notification tracker start notice: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FreeWatchApp(),
    ),
  );
}
