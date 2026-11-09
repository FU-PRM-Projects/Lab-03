import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';
import '../services/clock.dart';
import '../services/note_repository.dart';
import 'auth_view_model.dart';

final noteWallProvider =
    AsyncNotifierProvider<NoteWallViewModel, Map<String, DateTime>>(
      NoteWallViewModel.new,
    );

class NoteWallViewModel extends AsyncNotifier<Map<String, DateTime>> {
  static const duration = Duration(days: 2);

  late final _prefs = SharedPreferencesAsync();
  String? _key;
  Future<void> _pending = Future<void>.value();

  @override
  Future<Map<String, DateTime>> build() async {
    final uid = ref.watch(authUserProvider.select((user) => user.value?.uid));
    final key = _key = uid == null ? null : 'note_wall.$uid';
    if (key == null) return {};
    final stored = await _prefs.getString(key);
    if (stored == null) return {};
    final values = jsonDecode(stored) as Map<String, dynamic>;
    return {
      for (final entry in values.entries)
        if (entry.value case final int timestamp)
          entry.key: DateTime.fromMillisecondsSinceEpoch(timestamp),
    };
  }

  Future<void> pin(String id) {
    final expires = ref.read(clockProvider).now().add(duration);
    return _update((pins) => pins[id] = expires);
  }

  Future<void> release(String id, DateTime expires) => _update((pins) {
    if (pins[id] == expires) pins.remove(id);
  });

  Future<void> _update(void Function(Map<String, DateTime>) change) {
    final key = _key;
    final operation = _pending.then((_) async {
      if (!ref.mounted || key == null || key != _key) {
        throw StateError('Tài khoản đã thay đổi.');
      }
      final updated = Map<String, DateTime>.of(await future);
      if (!ref.mounted || key != _key) {
        throw StateError('Tài khoản đã thay đổi.');
      }
      change(updated);
      await _prefs.setString(
        key,
        jsonEncode(
          updated.map((id, date) => MapEntry(id, date.millisecondsSinceEpoch)),
        ),
      );
      if (ref.mounted && key == _key) state = AsyncData(updated);
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}

final noteWallItemProvider = FutureProvider.autoDispose.family<Note, String>((
  ref,
  id,
) {
  ref.watch(authUserProvider.select((user) => user.value?.uid));
  return ref.watch(noteRepositoryProvider).get(id);
});
