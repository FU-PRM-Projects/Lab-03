import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../services/remote_config_service.dart';

/// Remote Config thật: giá trị mặc định lấy từ [InAppRemoteConfig], nên khi
/// tải thất bại (mất mạng, chưa publish) app chạy y như trước.
class FirebaseRemoteConfigService implements RemoteConfigService {
  FirebaseRemoteConfigService._(this._config);

  final FirebaseRemoteConfig _config;

  static const InAppRemoteConfig _fallback = InAppRemoteConfig();

  /// Đặt mặc định rồi tải một lần; không bao giờ ném lỗi ra ngoài.
  static Future<FirebaseRemoteConfigService> create() async {
    final config = FirebaseRemoteConfig.instance;
    final service = FirebaseRemoteConfigService._(config);
    try {
      await config.setDefaults(<String, Object>{
        'quick_win_chips': jsonEncode(InAppRemoteConfig.defaultQuickWinChips),
        'monthly_milestone': InAppRemoteConfig.defaultMonthlyMilestone,
        'discord_enabled': true,
        'discord_invite_url': InAppRemoteConfig.defaultDiscordInviteUrl,
        'discord_channel_map': '{}',
        'discord_greetings': jsonEncode(
          InAppRemoteConfig.defaultDiscordGreetings,
        ),
        'firebase_demo_enabled': true,
      });
      await config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Debug lấy ngay để demo "đổi trên Console, không build lại".
          minimumFetchInterval: kReleaseMode
              ? const Duration(hours: 1)
              : Duration.zero,
        ),
      );
      await config.fetchAndActivate();
    } on Object catch (error) {
      debugPrint('[remote-config] dùng giá trị mặc định: $error');
    }
    return service;
  }

  List<String> _strings(String key, List<String> fallback) {
    try {
      final decoded = jsonDecode(_config.getString(key));
      if (decoded is List) {
        final items = decoded.whereType<String>().toList();
        if (items.isNotEmpty) {
          return items;
        }
      }
    } on FormatException {
      // JSON hỏng trên Console: giữ giá trị mặc định.
    }
    return fallback;
  }

  @override
  List<String> get quickWinChips =>
      _strings('quick_win_chips', _fallback.quickWinChips);

  @override
  int get monthlyMilestone {
    final value = _config.getInt('monthly_milestone');
    return value > 0 ? value : _fallback.monthlyMilestone;
  }

  @override
  bool get discordEnabled => _config.getBool('discord_enabled');

  @override
  String get discordInviteUrl {
    final value = _config.getString('discord_invite_url');
    return value.isEmpty ? _fallback.discordInviteUrl : value;
  }

  @override
  Map<String, String> get discordChannels {
    try {
      final decoded = jsonDecode(_config.getString('discord_channel_map'));
      if (decoded is Map) {
        return <String, String>{
          for (final entry in decoded.entries)
            if (entry.key is String && entry.value is String)
              entry.key as String: entry.value as String,
        };
      }
    } on FormatException {
      // JSON hỏng: coi như chưa có link riêng.
    }
    return _fallback.discordChannels;
  }

  @override
  List<String> get discordGreetings =>
      _strings('discord_greetings', _fallback.discordGreetings);

  @override
  bool get firebaseDemoEnabled => _config.getBool('firebase_demo_enabled');

  @override
  Future<bool> refresh() async {
    try {
      return await _config.fetchAndActivate();
    } on Object catch (error) {
      debugPrint('[remote-config] tải lại thất bại: $error');
      return false;
    }
  }
}
