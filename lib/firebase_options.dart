import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Generated for FreeWatch project `freewatch-a0bc7`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBAWxF0RefJNdYm5fBImexTjwD-D0uH3mw',
    appId: '1:211067099380:web:c3256a4da1b27ae37fe6a1',
    messagingSenderId: '211067099380',
    projectId: 'freewatch-a0bc7',
    authDomain: 'freewatch-a0bc7.firebaseapp.com',
    databaseURL: 'https://freewatch-a0bc7-default-rtdb.firebaseio.com',
    storageBucket: 'freewatch-a0bc7.firebasestorage.app',
    measurementId: 'G-76Z2VJHLTB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA7GoAsmMBX0gLlrLr7bb2__AMr8jUehys',
    appId: '1:211067099380:android:5f633520cef7cf177fe6a1',
    messagingSenderId: '211067099380',
    projectId: 'freewatch-a0bc7',
    databaseURL: 'https://freewatch-a0bc7-default-rtdb.firebaseio.com',
    storageBucket: 'freewatch-a0bc7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA7GoAsmMBX0gLlrLr7bb2__AMr8jUehys',
    appId: '1:211067099380:ios:5f633520cef7cf177fe6a1',
    messagingSenderId: '211067099380',
    projectId: 'freewatch-a0bc7',
    databaseURL: 'https://freewatch-a0bc7-default-rtdb.firebaseio.com',
    storageBucket: 'freewatch-a0bc7.firebasestorage.app',
    iosBundleId: 'com.freewatch.freewatch',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA7GoAsmMBX0gLlrLr7bb2__AMr8jUehys',
    appId: '1:211067099380:ios:5f633520cef7cf177fe6a1',
    messagingSenderId: '211067099380',
    projectId: 'freewatch-a0bc7',
    databaseURL: 'https://freewatch-a0bc7-default-rtdb.firebaseio.com',
    storageBucket: 'freewatch-a0bc7.firebasestorage.app',
    iosBundleId: 'com.freewatch.freewatch',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA7GoAsmMBX0gLlrLr7bb2__AMr8jUehys',
    appId: '1:211067099380:web:5f633520cef7cf177fe6a1',
    messagingSenderId: '211067099380',
    projectId: 'freewatch-a0bc7',
    databaseURL: 'https://freewatch-a0bc7-default-rtdb.firebaseio.com',
    storageBucket: 'freewatch-a0bc7.firebasestorage.app',
  );
}
