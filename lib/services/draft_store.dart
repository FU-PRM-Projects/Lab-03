import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note.dart';

/// Nháp S03 lưu trên máy ("Giữ nháp"), để S02 hiện "Tiếp tục ghi nốt".
abstract interface class DraftStore {
  Future<NoteDraft?> load();

  Future<void> save(NoteDraft draft);

  Future<void> clear();
}

final draftStoreProvider = Provider<DraftStore>(
  (ref) => throw UnimplementedError('draftStoreProvider chưa được gắn'),
);
