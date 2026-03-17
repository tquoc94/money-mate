import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAl9sNHsd0kstFAOF9C9ZpdheNBhEg0hao',
    appId: '1:956904880043:android:081e3671a4a17af0be44ee',
    messagingSenderId: '956904880043',
    projectId: 'qlct-f927c',
    storageBucket: 'qlct-f927c.firebasestorage.app',
  );
}
