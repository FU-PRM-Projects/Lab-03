import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/note.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:lab03/services/auth_service.dart';
import 'package:lab03/services/clock.dart';
import 'package:lab03/services/note_repository.dart';
import 'package:lab03/viewmodels/jar_view_model.dart';
import 'package:lab03/viewmodels/note_deleter.dart';
import 'package:lab03/viewmodels/note_detail_view_model.dart';
import 'package:lab03/viewmodels/view_state.dart';

import '../support/fakes.dart';

void main() {
  late FakeNoteRepository notes;

  setUp(() => notes = FakeNoteRepository());

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(
          FakeAuthService(signedIn: testUser),
        ),
        noteRepositoryProvider.overrideWithValue(notes),
        clockProvider.overrideWithValue(FixedClock()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// [count] nốt, mỗi ngày một nốt lùi dần từ 24/10/2026.
  List<Note> manyNotes(int count) => <Note>[
    for (var i = 0; i < count; i++)
      sampleNote('n$i', DateTime(2026, 10, 24 - i, 20), title: 'Nốt $i'),
  ];

  JarData jarData(ProviderContainer c) =>
      (c.read(jarViewModelProvider) as Data<JarData>).value;

  group('JarViewModel (S05)', () {
    test('hũ rỗng: Empty state (T1)', () async {
      final c = makeContainer()..listen(jarViewModelProvider, (_, _) {});
      await pumpEventQueue();
      expect(c.read(jarViewModelProvider), isA<Empty<JarData>>());
    });

    test('lỗi tải: Error state Offline có Thử lại (T2)', () async {
      notes.watchError = const AppException(AppErrorKind.network);
      final c = makeContainer()..listen(jarViewModelProvider, (_, _) {});
      await pumpEventQueue();
      final state = c.read(jarViewModelProvider);
      expect(state, isA<Failure<JarData>>());
      expect((state as Failure<JarData>).offline, isTrue);

      notes.watchError = null;
      c.read(jarViewModelProvider.notifier).refresh();
      await pumpEventQueue();
      expect(c.read(jarViewModelProvider), isA<Empty<JarData>>());
    });

    test('mới nhất trước; đếm nốt tháng này và nhãn dán', () async {
      notes.notes.addAll(<Note>[
        sampleNote('sep', DateTime(2026, 9, 28)),
        sampleNote('a', DateTime(2026, 10, 20)),
        sampleNote('b', DateTime(2026, 10, 24)),
      ]);
      notes.stickers.add(DateTime(2026, 9));
      final c = makeContainer()..listen(jarViewModelProvider, (_, _) {});
      await pumpEventQueue();
      final data = jarData(c);
      expect(data.notes.map((n) => n.id), <String>['b', 'a', 'sep']);
      expect(data.monthCount, 2);
      expect(data.month, 10);
      expect(data.stickers.single, DateTime(2026, 9));
    });

    test('tải theo trang 30 nốt khi cuộn tới cuối', () async {
      notes.notes.addAll(manyNotes(45));
      final c = makeContainer()..listen(jarViewModelProvider, (_, _) {});
      await pumpEventQueue();
      expect(jarData(c).notes, hasLength(30));
      expect(jarData(c).hasMore, isTrue);

      await c.read(jarViewModelProvider.notifier).loadMore();
      expect(jarData(c).notes, hasLength(45));
      expect(jarData(c).hasMore, isFalse);
      expect(jarData(c).notes.last.id, 'n44');
    });

    test('nốt mới lưu hiện ngay đầu lưới', () async {
      notes.notes.addAll(manyNotes(2));
      final c = makeContainer()..listen(jarViewModelProvider, (_, _) {});
      await pumpEventQueue();
      await notes.add(
        const NoteDraft(title: 'Mới'),
        createdAt: DateTime(2026, 10, 24, 21),
      );
      await pumpEventQueue();
      expect(jarData(c).notes.first.title, 'Mới');
    });
  });

  group('NoteDeleter (P5)', () {
    test('ẩn nốt ngay, Hoàn tác trả nốt về đúng chỗ, không xoá', () {
      fakeAsync((async) {
        notes.notes.addAll(manyNotes(3));
        final c = makeContainer()..listen(jarViewModelProvider, (_, _) {});
        async.elapse(const Duration(milliseconds: 1));

        c.read(noteDeleterProvider.notifier).deleteWithUndo(notes.notes[1]);
        async.elapse(const Duration(milliseconds: 1));
        expect(jarData(c).notes.map((n) => n.id), <String>['n0', 'n2']);
        expect(jarData(c).monthCount, 2);

        async.elapse(const Duration(seconds: 2));
        c.read(noteDeleterProvider.notifier).undo();
        async.elapse(const Duration(milliseconds: 1));
        expect(jarData(c).notes.map((n) => n.id), <String>['n0', 'n1', 'n2']);

        async.elapse(const Duration(seconds: 10));
        expect(notes.deleted, isEmpty);
      });
    });

    test('hết 5 giây: xoá thật trên repository', () {
      fakeAsync((async) {
        notes.notes.addAll(manyNotes(2));
        final c = makeContainer()..listen(jarViewModelProvider, (_, _) {});
        async.elapse(const Duration(milliseconds: 1));
        c.read(noteDeleterProvider.notifier).deleteWithUndo(notes.notes[0]);

        async.elapse(const Duration(milliseconds: 4900));
        expect(notes.deleted, isEmpty);
        async.elapse(const Duration(milliseconds: 200));
        expect(notes.deleted, <String>['n0']);
        expect(c.read(noteDeleterProvider).note, isNull);
        expect(jarData(c).notes.map((n) => n.id), <String>['n1']);
      });
    });

    test('xoá thất bại: báo lỗi, nốt hiện lại', () {
      fakeAsync((async) {
        notes.notes.addAll(manyNotes(1));
        final c = makeContainer()..listen(jarViewModelProvider, (_, _) {});
        async.elapse(const Duration(milliseconds: 1));
        c.read(noteDeleterProvider.notifier).deleteWithUndo(notes.notes[0]);
        notes.nextError = const AppException(AppErrorKind.network);
        async.elapse(NoteDeleter.undoWindow);
        async.elapse(const Duration(milliseconds: 1));

        expect(c.read(noteDeleterProvider).failure, contains('Chưa xoá được'));
        expect(jarData(c).notes.single.id, 'n0');
      });
    });
  });

  group('NoteDetailViewModel (S06)', () {
    const args = (id: 'n0', edit: false);

    Future<ProviderContainer> open({NoteDetailArgs a = args}) async {
      final c = makeContainer()
        ..listen(noteDetailViewModelProvider(a), (_, _) {});
      await pumpEventQueue();
      return c;
    }

    NoteDetailViewModel vm(ProviderContainer c, [NoteDetailArgs a = args]) =>
        c.read(noteDetailViewModelProvider(a).notifier);
    NoteDetailState state(ProviderContainer c, [NoteDetailArgs a = args]) =>
        c.read(noteDetailViewModelProvider(a));

    test('không tìm thấy nốt: Error state', () async {
      final c = await open();
      expect(state(c).note, isA<Failure<Note>>());
    });

    test('sửa tiêu đề và nhật ký rồi lưu', () async {
      notes.notes.addAll(manyNotes(1));
      final c = await open();
      expect(state(c).loaded?.title, 'Nốt 0');

      vm(c).startEdit();
      expect(state(c).hasChanges, isFalse);
      expect(state(c).canSave, isFalse);
      vm(c)
        ..setTitle('Dọn bàn học')
        ..setBody('Nhẹ hơn hôm qua.');
      expect(state(c).hasChanges, isTrue);
      await vm(c).save();

      expect(state(c).editing, isFalse);
      expect(state(c).loaded?.title, 'Dọn bàn học');
      expect(notes.notes.single.body, 'Nhẹ hơn hôm qua.');
    });

    test('tiêu đề trống hoặc quá 120 ký tự: báo lỗi, không lưu', () async {
      notes.notes.addAll(manyNotes(1));
      final c = await open();
      vm(c)
        ..startEdit()
        ..setTitle('  ');
      expect(state(c).titleError, isNotNull);
      expect(state(c).canSave, isFalse);
      vm(c).setTitle('a' * 121);
      expect(state(c).titleError, contains('120'));
    });

    test('"Gợi ý" thêm câu hỏi gợi mở vào nhật ký (P4)', () async {
      notes.notes.addAll(manyNotes(1));
      final c = await open();
      vm(c)
        ..startEdit()
        ..addPrompt();
      expect(state(c).body, startsWith(NoteDetailViewModel.prompts.first));
      vm(c).addPrompt();
      expect(state(c).body, contains(NoteDetailViewModel.prompts[1]));
    });

    test('"Viết thêm" từ S04: mở sẵn chế độ sửa', () async {
      notes.notes.addAll(manyNotes(1));
      const editArgs = (id: 'n0', edit: true);
      final c = await open(a: editArgs);
      expect(state(c, editArgs).editing, isTrue);
    });

    test('lỗi lưu: báo lỗi, giữ chế độ sửa', () async {
      notes.notes.addAll(manyNotes(1));
      final c = await open();
      vm(c)
        ..startEdit()
        ..setTitle('Mới');
      notes.nextError = const AppException(AppErrorKind.permissionDenied);
      await vm(c).save();
      expect(state(c).editing, isTrue);
      expect(state(c).message, contains('Chưa lưu được'));
    });
  });
}
