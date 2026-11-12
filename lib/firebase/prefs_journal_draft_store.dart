import 'package:shared_preferences/shared_preferences.dart';

import '../services/journal_draft_store.dart';

/// [JournalDraftStore] bằng SharedPreferences: một trang nháp duy nhất.
///
/// Nằm trong `firebase/` cùng [PrefsDraftStore] vì đây là lớp được phép gọi
/// SDK của nền tảng.
class PrefsJournalDraftStore implements JournalDraftStore {
  PrefsJournalDraftStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const String _key = 'journal_draft';

  @override
  Future<String?> load() async {
    final text = await _prefs.getString(_key);
    return text == null || text.trim().isEmpty ? null : text;
  }

  @override
  Future<void> save(String text) =>
      text.trim().isEmpty ? _prefs.remove(_key) : _prefs.setString(_key, text);

  @override
  Future<void> clear() => _prefs.remove(_key);
}
