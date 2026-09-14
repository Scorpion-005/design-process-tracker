import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Ask for notification permission and save this device's FCM token
  /// under a shared `fcm_tokens` collection so the Cloud Function can
  /// broadcast to every device.
  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    // Keep the stored token fresh if it ever rotates.
    _messaging.onTokenRefresh.listen(_saveToken);
  }

  static Future<void> _saveToken(String token) async {
    await FirebaseFirestore.instance
        .collection('fcm_tokens')
        .doc(token)
        .set({
      'token': token,
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Call on logout so the device stops receiving notifications meant
  /// for a signed-in session (optional but keeps fcm_tokens tidy).
  static Future<void> removeCurrentToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(token)
          .delete();
    }
  }
}
