import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to detect whether the application is running on an Android TV device,
/// widescreen display, or mobile phone, and enforce appropriate screen orientation.
class DeviceTypeService {
  static final DeviceTypeService _instance = DeviceTypeService._internal();
  factory DeviceTypeService() => _instance;
  DeviceTypeService._internal();

  static const MethodChannel _deviceChannel = MethodChannel('com.freewatch.app/device');

  bool _isTv = false;
  bool _initialized = false;

  bool get isTv => _isTv;
  bool get isInitialized => _initialized;

  /// Detect native TV capabilities via MainActivity MethodChannel
  Future<void> initialize() async {
    if (_initialized) return;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final bool? tvDetected = await _deviceChannel.invokeMethod<bool>('isTv');
        if (tvDetected != null) {
          _isTv = tvDetected;
        }
      } catch (e) {
        debugPrint('DeviceTypeService: native TV check failed: $e');
      }
    }

    _initialized = true;
  }

  /// Override or update TV mode dynamically based on layout width (e.g. tablet / TV / widescreen)
  void setTvMode(bool isTv) {
    _isTv = isTv;
  }

  /// Apply appropriate screen orientations based on device form factor
  Future<void> applyDeviceOrientations() async {
    await initialize();

    if (_isTv) {
      // Lock Android TV to landscape widescreen
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Lock mobile phones to portrait
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  /// Restore default orientations (used when exiting video player fullscreen)
  Future<void> restoreDefaultOrientations() async {
    if (_isTv) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }
}
