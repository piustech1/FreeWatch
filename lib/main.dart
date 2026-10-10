import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';
import 'core/services/movie_notification_tracker.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with FreeWatch project configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize device OS notifications service
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification service initialization notice: $e');
  }

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Riverpod root container
  final container = ProviderContainer();

  // Start background monitoring of MovieMax database for new uploads
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
