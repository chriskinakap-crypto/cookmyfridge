import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAK_tsMmE2G5regLXAwVMh09Bqe3GBCtK0',
    appId: '1:232949842942:android:1c4b484268f727969ff6af',
    messagingSenderId: '232949842942',
    projectId: 'cookmyfridge-2351f',
    storageBucket: 'cookmyfridge-2351f.firebasestorage.app',
  );
}
