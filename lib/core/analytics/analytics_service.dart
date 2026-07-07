import 'dart:developer' as developer;
import '../network/api_client.dart';

class AnalyticsService {
  const AnalyticsService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> logEvent(String eventName, {Map<String, dynamic>? properties}) async {
    try {
      developer.log('Analytics Event: $eventName $properties');
      await _apiClient.postJson('/analytics', body: {
        'event_name': eventName,
        if (properties != null) 'properties': properties,
      });
    } catch (e) {
      // Graceful degradation: do not fail application functions if tracking has issues
      developer.log('Analytics Error: $e');
    }
  }
}
