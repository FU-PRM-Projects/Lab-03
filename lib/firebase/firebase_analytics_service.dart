import 'package:firebase_analytics/firebase_analytics.dart';

import '../services/analytics_service.dart';

/// Hiện thực bằng Google Analytics for Firebase (project thật).
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService() : _analytics = FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) =>
      _analytics.logEvent(name: name, parameters: parameters);

  @override
  Future<void> logScreen(String screenName) =>
      _analytics.logScreenView(screenName: screenName);

  @override
  Future<void> setUserId(String? uid) => _analytics.setUserId(id: uid);
}
