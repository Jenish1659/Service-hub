import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for project `service-hub-5fcd1`.
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
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB_service_hub_5fcd1_web_key',
    appId: '1:1059432857421:web:3e5c9b74301fa7d82910ba',
    messagingSenderId: '1059432857421',
    projectId: 'service-hub-5fcd1',
    authDomain: 'service-hub-5fcd1.firebaseapp.com',
    storageBucket: 'service-hub-5fcd1.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB_service_hub_5fcd1_partner_key',
    appId: '1:1059432857421:android:3e5c9b74301fa7d82910ba',
    messagingSenderId: '1059432857421',
    projectId: 'service-hub-5fcd1',
    storageBucket: 'service-hub-5fcd1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB_service_hub_5fcd1_ios_key',
    appId: '1:1059432857421:ios:3e5c9b74301fa7d82910ba',
    messagingSenderId: '1059432857421',
    projectId: 'service-hub-5fcd1',
    storageBucket: 'service-hub-5fcd1.firebasestorage.app',
    iosBundleId: 'com.example.serviceHubPartner',
  );
}
