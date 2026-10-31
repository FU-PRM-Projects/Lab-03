import 'dart:async';

import 'package:lab03/models/app_user.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/note.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:lab03/services/auth_service.dart';
import 'package:lab03/services/clock.dart';
import 'package:lab03/services/draft_store.dart';
import 'package:lab03/services/note_repository.dart';
import 'package:lab03/services/user_repository.dart';

const AppUser testUser = AppUser(
  uid: 'u-minh',
  email: 'minh.test@example.com',
  displayName: 'Minh',
);

/// [AuthService] trong bộ nhớ. Giống Firebase: người nghe mới nhận ngay trạng
/// thái hiện tại.
class FakeAuthService implements AuthService {
  FakeAuthService({AppUser? signedIn}) : _user = signedIn;

  AppUser? _user;
  final _changes = StreamController<AppUser?>.broadcast();

  /// Lỗi ném ra ở lần gọi đăng nhập/đăng ký/gửi link kế tiếp.
  AppException? nextError;

  /// Giữ lần đăng nhập Google chưa xong để test thấy trạng thái Loading.
  Completer<void>? googleGate;

  int signOutCount = 0;
  final List<String> resetEmails = <String>[];

  void _set(AppUser? user) {
    _user = user;
    _changes.add(user);
  }

  Future<AppUser> _signIn(AppUser user) async {
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
    _set(user);
    return user;
  }

  @override
  Stream<AppUser?> authStateChanges() => Stream<AppUser?>.multi((controller) {
    controller.add(_user);
    final sub = _changes.stream.listen(controller.add);
    controller.onCancel = sub.cancel;
  });

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInWithGoogle() async {
    await googleGate?.future;
    return _signIn(testUser);
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) =>
      _signIn(AppUser(uid: 'u-$email', email: email));

  @override
  Future<AppUser> registerWithEmail(String email, String password) =>
      _signIn(AppUser(uid: 'u-$email', email: email));

  @override
  Future<void> sendPasswordReset(String email) async {
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
    resetEmails.add(email);
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    _set(null);
  }
}

class FakeUserRepository implements UserRepository {
  final List<AppUser> profiles = <AppUser>[];
  int clearCount = 0;
  AppException? ensureError;

  @override
  Future<void> ensureProfile(AppUser user) async {
    if (ensureError != null) throw ensureError!;
    profiles.add(user);
  }

  @override
  Future<void> clearLocalData() async => clearCount++;
}

/// Giờ cố định: Thứ Bảy, 24/10/2026, 21:30 (dữ liệu mẫu Lab 2).
class FixedClock implements Clock {
  FixedClock([DateTime? now]) : current = now ?? DateTime(2026, 10, 24, 21, 30);

  DateTime current;

  @override
  DateTime now() => current;
}

/// [NoteRepository] trong bộ nhớ, giống Firestore: người nghe mới nhận ngay
/// danh sách hiện tại, mới nhất trước.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository([List<Note> initial = const <Note>[]])
    : notes = List<Note>.of(initial);

  final List<Note> notes;
  final List<DateTime> stickers = <DateTime>[];
  final _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  /// Lỗi ném ra ở lần gọi kế tiếp (đọc hoặc ghi).
  AppException? nextError;

  /// Lỗi phát trên luồng `watchSince`.
  AppException? watchError;

  /// Lưu xong nhưng chưa đồng bộ (offline).
  bool offline = false;

  /// Giữ lần lưu chưa xong để test thấy trạng thái Loading.
  Completer<void>? addGate;

  void _throwIfError() {
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
  }

  List<Note> get _sorted =>
      List<Note>.of(notes)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<Note>> watchSince(DateTime since) =>
      Stream<List<Note>>.multi((controller) {
        if (watchError != null) {
          controller.addError(watchError!);
          return;
        }
        List<Note> current() =>
            _sorted.where((n) => !n.createdAt.isBefore(since)).toList();
        controller.add(current());
        final sub = _changes.stream.listen((_) => controller.add(current()));
        controller.onCancel = sub.cancel;
      });

  @override
  Stream<List<Note>> watchRecent({int limit = 30}) =>
      Stream<List<Note>>.multi((controller) {
        if (watchError != null) {
          controller.addError(watchError!);
          return;
        }
        controller.add(_sorted.take(limit).toList());
        final sub = _changes.stream.listen(
          (_) => controller.add(_sorted.take(limit).toList()),
        );
        controller.onCancel = sub.cancel;
      });

  @override
  Future<List<Note>> list({DateTime? before, int limit = 30}) async {
    _throwIfError();
    return _sorted
        .where((n) => before == null || n.createdAt.isBefore(before))
        .take(limit)
        .toList();
  }

  @override
  Future<int> countBetween(DateTime start, DateTime end) async {
    _throwIfError();
    return notes
        .where((n) => !n.createdAt.isBefore(start) && n.createdAt.isBefore(end))
        .length;
  }

  @override
  Future<Note> get(String id) async {
    _throwIfError();
    for (final note in notes) {
      if (note.id == id) return note;
    }
    throw const AppException(AppErrorKind.notFound);
  }

  @override
  Future<Note> add(NoteDraft draft, {required DateTime createdAt}) async {
    await addGate?.future;
    _throwIfError();
    final note = Note(
      id: 'n${_nextId++}',
      type: draft.type,
      title: draft.title,
      body: draft.body,
      mood: draft.mood,
      createdAt: createdAt,
      pendingSync: offline,
    );
    notes.add(note);
    _changes.add(null);
    return note;
  }

  @override
  Future<Note> update(
    String id, {
    required String title,
    required String body,
  }) async {
    _throwIfError();
    final i = notes.indexWhere((n) => n.id == id);
    if (i < 0) throw const AppException(AppErrorKind.notFound);
    final old = notes[i];
    final note = Note(
      id: id,
      type: old.type,
      title: title.trim(),
      body: body.trim(),
      mood: old.mood,
      createdAt: old.createdAt,
      pendingSync: offline,
    );
    notes[i] = note;
    _changes.add(null);
    return note;
  }

  final List<String> deleted = <String>[];

  @override
  Future<void> delete(String id) async {
    _throwIfError();
    notes.removeWhere((n) => n.id == id);
    deleted.add(id);
    _changes.add(null);
  }

  @override
  Future<void> saveMonthSticker(DateTime month) async {
    _throwIfError();
    stickers.add(month);
  }

  @override
  Future<List<String>> listStickers() async {
    _throwIfError();
    return stickers
        .map((m) => '${m.year}-${m.month.toString().padLeft(2, '0')}')
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }
}

class FakeDraftStore implements DraftStore {
  FakeDraftStore([this.draft]);

  NoteDraft? draft;

  @override
  Future<NoteDraft?> load() async => draft;

  @override
  Future<void> save(NoteDraft value) async => draft = value;

  @override
  Future<void> clear() async => draft = null;
}

/// Nốt mẫu, mặc định là chiến thắng tâm trạng Ổn.
Note sampleNote(
  String id,
  DateTime createdAt, {
  NoteType type = NoteType.chienThang,
  Mood? mood = Mood.on,
  String title = 'Dọn bàn học, gửi email hỏi thầy',
  bool pendingSync = false,
}) => Note(
  id: id,
  type: type,
  title: title,
  mood: mood,
  createdAt: createdAt,
  pendingSync: pendingSync,
);
