// ================= FILE 15: push_notification_service.dart =================
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initializeNotifications() async {
    // यूजर से नोटिफिकेशन की परमिशन मांगें
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('🔔 यूजर ने नोटिफिकेशन की अनुमति दे दी है!');
      
      // FCM डिवाइस टोकन प्राप्त करें (वेंडर के लिए)
      String? token = await _messaging.getToken();
      debugPrint('📱 FCM Token: $token');

      // बैकग्राउंड मैसेज लिसनर
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 नया पुश नोटिफिकेशन प्राप्त हुआ: ${message.notification?.title}');
      });
    } else {
      debugPrint('❌ यूजर ने नोटिफिकेशन की अनुमति नहीं दी।');
    }
  }
}
