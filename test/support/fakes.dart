import 'dart:async';
import 'dart:typed_data';

import 'package:lab03/models/app_user.dart';
import 'package:lab03/models/challenge.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/note.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/models/report.dart';
import 'package:lab03/models/self_control.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:lab03/services/auth_service.dart';
import 'package:lab03/services/challenge_repository.dart';
import 'package:lab03/services/clock.dart';
import 'package:lab03/services/draft_store.dart';
import 'package:lab03/services/note_repository.dart';
import 'package:lab03/services/report_services.dart';
import 'package:lab03/services/self_control_services.dart';
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
      challenge: draft.challenge,
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
      challenge: old.challenge,
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

/// Thói quen và cài đặt trong bộ nhớ. Là [HabitRepository]; dùng
/// [settingsView] làm [SettingsRepository] (hai interface cùng có `watch`).
class FakeSelfControl implements HabitRepository {
  HabitList habits = const HabitList();
  UserSettings settings = const UserSettings();
  final _habitChanges = StreamController<HabitList>.broadcast();
  final _settingChanges = StreamController<UserSettings>.broadcast();

  @override
  Stream<HabitList> watch() => Stream<HabitList>.multi((controller) {
    controller.add(habits);
    final sub = _habitChanges.stream.listen(controller.add);
    controller.onCancel = sub.cancel;
  });

  Stream<UserSettings> watchSettings() =>
      Stream<UserSettings>.multi((controller) {
        controller.add(settings);
        final sub = _settingChanges.stream.listen(controller.add);
        controller.onCancel = sub.cancel;
      });

  @override
  Future<void> setSelected(String habit, {required bool selected}) async {
    habits = HabitList(
      selected: selected
          ? <String>{...habits.selected, habit}
          : (Set<String>.of(habits.selected)..remove(habit)),
      custom: habits.custom,
    );
    _habitChanges.add(habits);
  }

  @override
  Future<void> addCustom(String habit) async {
    habits = HabitList(
      selected: <String>{...habits.selected, habit},
      custom: <String>[...habits.custom, habit],
    );
    _habitChanges.add(habits);
  }

  late final SettingsRepository settingsView = FakeSettingsView(this);

  Future<void> save(UserSettings value) async {
    settings = value;
    _settingChanges.add(settings);
  }
}

class FakeSettingsView implements SettingsRepository {
  FakeSettingsView(this.source);

  final FakeSelfControl source;

  @override
  Stream<UserSettings> watch() => source.watchSettings();

  @override
  Future<void> save(UserSettings settings) => source.save(settings);
}

class FakeLocalAuth implements LocalAuthService {
  bool result = true;
  int calls = 0;

  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return result;
  }
}

class FakeScreenGuard implements ScreenGuard {
  bool secure = false;
  bool keepScreenOn = false;

  @override
  Future<void> setSecure(bool enabled) async => secure = enabled;

  @override
  Future<void> setKeepScreenOn(bool enabled) async => keepScreenOn = enabled;
}

/// Kho thẻ mẫu: 2 chủ đề × 2 cấp × [perLevel] thẻ, id dạng `dc-1-1`, `vd-2-3`.
List<Challenge> sampleCatalog({int perLevel = 3}) => <Challenge>[
  for (final topic in ChallengeTopic.values)
    for (var level = 1; level <= 2; level++)
      for (var i = 1; i <= perLevel; i++)
        Challenge(
          id: '${topic == ChallengeTopic.dungCam ? 'dc' : 'vd'}-$level-$i',
          topic: topic,
          level: level,
          order: i,
          title: '${topic.label} cấp $level thẻ $i',
          minutes: level * 2 + i,
          tip: 'Mẹo $i',
          script: topic == ChallengeTopic.dungCam ? 'Câu mẫu $i' : '',
        ),
];

class FakeChallengeRepository implements ChallengeRepository {
  FakeChallengeRepository([List<Challenge>? catalog])
    : cards = catalog ?? sampleCatalog();

  final List<Challenge> cards;
  final Map<ChallengeTopic, ChallengeProgress> progress =
      <ChallengeTopic, ChallengeProgress>{};
  final _changes = StreamController<void>.broadcast();
  AppException? catalogError;

  @override
  Future<List<Challenge>> catalog() async {
    if (catalogError != null) throw catalogError!;
    return cards;
  }

  @override
  Future<Challenge> get(String id) async {
    for (final card in cards) {
      if (card.id == id) return card;
    }
    throw const AppException(AppErrorKind.notFound);
  }

  @override
  Stream<Map<ChallengeTopic, ChallengeProgress>> watchProgress() =>
      Stream<Map<ChallengeTopic, ChallengeProgress>>.multi((controller) {
        controller.add(Map.of(progress));
        final sub = _changes.stream.listen(
          (_) => controller.add(Map.of(progress)),
        );
        controller.onCancel = sub.cancel;
      });

  @override
  Future<ChallengeProgress> progressOf(ChallengeTopic topic) async =>
      progress[topic] ?? const ChallengeProgress();

  @override
  Future<void> complete(
    ChallengeTopic topic,
    String challengeId, {
    required int level,
  }) async {
    final old = progress[topic] ?? const ChallengeProgress();
    progress[topic] = ChallengeProgress(
      level: level,
      completed: <String>{...old.completed, challengeId},
    );
    _changes.add(null);
  }
}

class FakeReportService implements ReportService {
  final List<WeeklySummary> built = <WeeklySummary>[];
  final List<String> shared = <String>[];
  AppException? buildError;

  @override
  Future<Uint8List> weeklyCard(WeeklySummary summary) async {
    if (buildError != null) throw buildError!;
    built.add(summary);
    return Uint8List.fromList(<int>[37, 80, 68, 70]);
  }

  @override
  Future<void> share(Uint8List bytes, String fileName) async =>
      shared.add(fileName);
}

class FakeStorageService implements StorageService {
  final List<String> uploaded = <String>[];
  AppException? uploadError;

  @override
  Stream<UploadProgress> uploadReport(String fileName, Uint8List bytes) async* {
    yield const UploadProgress(0.5);
    if (uploadError != null) throw uploadError!;
    uploaded.add('reports/u-minh/$fileName');
    yield UploadProgress(
      1,
      url: 'https://storage.example/reports/u-minh/$fileName',
    );
  }
}
