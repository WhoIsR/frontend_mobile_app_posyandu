import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../network/api_client.dart';

class FcmRegistrationService {
  const FcmRegistrationService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> registerTokenIfAvailable() async {
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _apiClient.postJson('/fcm-token', body: {'fcm_token': token});
    } catch (_) {
      // Firebase config is optional in PRD v1.1. Database notifications still work.
    }
  }
}
