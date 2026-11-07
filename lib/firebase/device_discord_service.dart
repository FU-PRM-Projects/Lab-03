import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_exception.dart';
import '../services/discord_service.dart';
import 'firestore_errors.dart';

/// [DiscordService] bằng `url_launcher`, `shared_preferences` và Firestore.
class DeviceDiscordService implements DiscordService {
  DeviceDiscordService({
    String? Function()? currentUid,
    FirebaseFirestore? firestore,
  }) : _currentUid = currentUid ?? (() => null),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final String? Function() _currentUid;
  late final FirebaseFirestore _firestore;

  FirebaseFirestore get _db => _firestore;

  static const String _rulesSeenKey = 'discord_rules_seen';

  String _requireUid() {
    final uid = _currentUid();
    if (uid == null) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        code: 'signed-out',
      );
    }
    return uid;
  }

  DocumentReference<Map<String, Object?>> _userDiscordDoc(String uid) =>
      _db.collection('users').doc(uid).collection('private').doc('discord');

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

  @override
  Stream<DiscordLink?> watchLink() {
    final uid = _currentUid();
    if (uid == null) return Stream<DiscordLink?>.value(null);
    return _userDiscordDoc(uid)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (!doc.exists || data == null) return null;
          final discordId = data['discordId'] as String?;
          final discordUsername = data['discordUsername'] as String?;
          if (discordId == null || discordUsername == null) return null;
          final linkedAt = switch (data['linkedAt']) {
            final Timestamp ts => ts.toDate(),
            _ => null,
          };
          return DiscordLink(
            discordId: discordId,
            discordUsername: discordUsername,
            linkedAt: linkedAt,
          );
        })
        .transform(
          StreamTransformer<DiscordLink?, DiscordLink?>.fromHandlers(
            handleError: (error, stack, sink) => sink.addError(
              error is FirebaseException ? firestoreException(error) : error,
              stack,
            ),
          ),
        );
  }

  @override
  Future<DiscordLink> connectWithCode(String rawCode) async {
    final uid = _requireUid();
    final code = rawCode.trim().toUpperCase();
    if (code.length != 6) {
      throw const AppException(
        AppErrorKind.invalidInput,
        code: 'invalid-code-format',
      );
    }

    try {
      return await _db.runTransaction<DiscordLink>((tx) async {
        final userRef = _userDiscordDoc(uid);
        final codeRef = _db.collection('discordConnectCodes').doc(code);

        final userSnap = await tx.get(userRef);
        if (userSnap.exists) {
          throw const AppException(
            AppErrorKind.invalidInput,
            code: 'account-already-linked',
          );
        }

        final codeSnap = await tx.get(codeRef);
        final codeData = codeSnap.data();
        if (!codeSnap.exists || codeData == null) {
          throw const AppException(
            AppErrorKind.notFound,
            code: 'code-not-found',
          );
        }

        final expiresAt = switch (codeData['expiresAt']) {
          final Timestamp ts => ts.toDate(),
          _ => null,
        };
        if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
          throw const AppException(
            AppErrorKind.invalidInput,
            code: 'code-expired',
          );
        }

        final discordId = codeData['discordId'] as String?;
        final discordUsername = codeData['discordUsername'] as String?;
        if (discordId == null ||
            discordId.isEmpty ||
            discordUsername == null ||
            discordUsername.isEmpty) {
          throw const AppException(
            AppErrorKind.invalidInput,
            code: 'code-invalid',
          );
        }

        final linkRef = _db.collection('discordLinks').doc(discordId);
        final linkSnap = await tx.get(linkRef);
        if (linkSnap.exists) {
          throw const AppException(
            AppErrorKind.invalidInput,
            code: 'discord-already-linked',
          );
        }

        final now = FieldValue.serverTimestamp();
        tx
          ..set(userRef, <String, Object?>{
            'discordId': discordId,
            'discordUsername': discordUsername,
            'linkedAt': now,
          })
          ..set(linkRef, <String, Object?>{
            'uid': uid,
            'discordUsername': discordUsername,
            'linkedAt': now,
          })
          ..delete(codeRef);

        return DiscordLink(
          discordId: discordId,
          discordUsername: discordUsername,
          linkedAt: DateTime.now(),
        );
      });
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }

  @override
  Future<void> disconnect() async {
    final uid = _requireUid();
    try {
      await _db.runTransaction<void>((tx) async {
        final userRef = _userDiscordDoc(uid);
        final userSnap = await tx.get(userRef);
        final data = userSnap.data();
        if (!userSnap.exists || data == null) return;

        final discordId = data['discordId'] as String?;
        tx.delete(userRef);
        if (discordId != null && discordId.isNotEmpty) {
          tx.delete(_db.collection('discordLinks').doc(discordId));
        }
      });
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }
}
