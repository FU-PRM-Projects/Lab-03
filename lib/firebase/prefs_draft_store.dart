import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/image_ref.dart';
import '../models/mood.dart';
import '../models/note.dart';
import '../models/note_type.dart';
import '../services/draft_store.dart';

/// [DraftStore] bằng SharedPreferences: một nháp duy nhất, dạng JSON.
///
/// Nằm trong `firebase/` cùng các hiện thực service khác dù không dùng
/// Firebase: đây là lớp được phép gọi SDK của nền tảng.
class PrefsDraftStore implements DraftStore {
  PrefsDraftStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const String _key = 'note_draft';

  @override
  Future<NoteDraft?> load() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      final draft = NoteDraft(
        type: NoteType.fromId(json['type'] as String?) ?? NoteType.chienThang,
        mood: Mood.fromId(json['mood'] as String?),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        // Nháp cũ chưa có khoá `image` → null, vẫn đọc được bình thường.
        image: ImageRef.fromMap(json['image']),
      );
      return draft.hasInput ? draft : null;
    } on FormatException {
      await clear();
      return null;
    } on TypeError {
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(NoteDraft draft) => _prefs.setString(
    _key,
    jsonEncode(<String, Object?>{
      'type': draft.type.id,
      'mood': draft.mood?.id,
      'title': draft.title,
      'body': draft.body,
      'image': draft.image?.toMap(),
    }),
  );

  @override
  Future<void> clear() => _prefs.remove(_key);
}
