import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/discord_service.dart';

/// [DiscordService] bằng `url_launcher` và `shared_preferences`.
class DeviceDiscordService implements DiscordService {
  const DeviceDiscordService();

  static const String _rulesSeenKey = 'discord_rules_seen';

  @override
  Future<bool> open(String url, {bool inBrowser = false}) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    try {
      return await launchUrl(
        uri,
        mode: inBrowser
            ? LaunchMode.inAppBrowserView
            : LaunchMode.externalApplication,
      );
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> rulesSeen() async =>
      (await SharedPreferences.getInstance()).getBool(_rulesSeenKey) ?? false;

  @override
  Future<void> markRulesSeen() async =>
      (await SharedPreferences.getInstance()).setBool(_rulesSeenKey, true);
}
