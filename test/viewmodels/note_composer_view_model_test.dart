import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/note.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:lab03/services/clock.dart';
import 'package:lab03/services/draft_store.dart';
import 'package:lab03/services/note_repository.dart';
import 'package:lab03/viewmodels/note_composer_view_model.dart';
import 'package:lab03/viewmodels/today_view_model.dart';

import '../support/fakes.dart';

/// Flow F1: S03a tâm trạng → S03b chiến thắng → S03c nhật ký → lưu.
void main() {
  late FakeNoteRepository notes;
  late FakeDraftStore drafts;
  late FixedClock clock;
  late ProviderContainer container;

  final provider = noteComposerViewModelProvider((step: 1, groupId: null));
  NoteComposerViewModel vm() => container.read(provider.notifier);
  NoteComposerState state() => container.read(provider);

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(notes),
        draftStoreProvider.overrideWithValue(drafts),
        clockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(c.dispose);
    // Giữ provider autoDispose sống trong suốt test.
    c.listen(provider, (_, _) {});
    return c;
  }

  setUp(() {
    notes = FakeNoteRepository();
    drafts = FakeDraftStore();
    clock = FixedClock();
    container = makeContainer();
  });

  test('bước 1: chưa chọn tâm trạng thì Tiếp bị khoá', () {
    expect(state().step, 1);
    expect(state().canContinue, isFalse);
    vm().next();
    expect(state().step, 1);

    vm().selectMood(Mood.on);
    expect(state().canContinue, isTrue);
    vm().next();
    expect(state().step, 2);
  });

  test('bước 2: ô trống khoá Tiếp; chạm chip điền tên chip', () {
    vm()
      ..selectMood(Mood.vui)
      ..next();
    expect(state().canContinue, isFalse);
    expect(state().quickWins, hasLength(6));

    vm().pickQuickWin('Đi bộ');
    expect(state().draft.title, 'Đi bộ');
    expect(state().canContinue, isTrue);

    vm().setTitle('   ');
    expect(state().canContinue, isFalse);
  });

  test('happy path: lưu nốt chiến thắng với giờ máy, xoá nháp', () async {
    drafts.draft = const NoteDraft(title: 'cũ');
    vm()
      ..selectMood(Mood.on)
      ..next()
      ..setTitle('  Dọn bàn học  ')
      ..next()
      ..setBody(' Nhẹ hơn hôm qua. ');
    await vm().save();

    final saved = notes.notes.single;
    expect(saved.type, NoteType.chienThang);
    expect(saved.mood, Mood.on);
    expect(saved.title, 'Dọn bàn học');
    expect(saved.body, 'Nhẹ hơn hôm qua.');
    expect(saved.createdAt, clock.current);
    expect(state().savedNoteId, saved.id);
    expect(drafts.draft, isNull);
  });

  test('"Bỏ qua nhật ký" lưu luôn với nhật ký rỗng', () async {
    vm()
      ..selectMood(Mood.met)
      ..next()
      ..setBody('sẽ bị bỏ')
      ..pickQuickWin('Ăn đủ bữa');
    await vm().save(skipJournal: true);
    expect(notes.notes.single.body, isEmpty);
  });

  test('không lưu khi thiếu tâm trạng hoặc tiêu đề quá 120 ký tự', () async {
    vm().setTitle('Đi bộ');
    await vm().save();
    vm()
      ..selectMood(Mood.on)
      ..setTitle('a' * 121);
    await vm().save();
    expect(notes.notes, isEmpty);
  });

  test('đang lưu: saving = true, bấm lần nữa không tạo nốt thứ hai', () async {
    final gate = Completer<void>();
    notes.addGate = gate;
    vm()
      ..selectMood(Mood.on)
      ..setTitle('Đi bộ');
    final first = vm().save();
    expect(state().saving, isTrue);
    unawaited(vm().save());
    gate.complete();
    await first;
    expect(notes.notes, hasLength(1));
    expect(state().saving, isFalse);
  });

  test('lỗi lưu: báo lỗi, giữ nội dung làm nháp', () async {
    notes.nextError = const AppException(AppErrorKind.permissionDenied);
    vm()
      ..selectMood(Mood.on)
      ..setTitle('Đi bộ');
    await vm().save();
    expect(state().savedNoteId, isNull);
    expect(state().message, contains('Chưa lưu được'));
    expect(drafts.draft?.title, 'Đi bộ');
  });

  test('Back: bước 3 về bước 2, bước 2 có dữ liệu thì hỏi, bước 1 đóng', () {
    expect(vm().back(), ComposerBack.close);
    vm()
      ..selectMood(Mood.on)
      ..next()
      ..setTitle('Đi bộ')
      ..next();
    expect(vm().back(), ComposerBack.previousStep);
    expect(state().step, 2);
    expect(vm().back(), ComposerBack.confirmKeepDraft);
  });

  test('Giữ nháp: lưu trên máy và S02 thấy có nháp', () async {
    expect(await container.read(hasDraftProvider.future), isFalse);
    vm()
      ..selectMood(Mood.on)
      ..setTitle('Đi bộ');
    await vm().keepDraft();
    expect(drafts.draft?.title, 'Đi bộ');
    expect(await container.read(hasDraftProvider.future), isTrue);

    await vm().discardDraft();
    expect(drafts.draft, isNull);
  });

  test('mở lại S03: điền sẵn nháp đã giữ', () async {
    drafts.draft = const NoteDraft(mood: Mood.vui, title: 'Giúp ai đó');
    container = makeContainer();
    await pumpEventQueue();
    expect(state().draft.mood, Mood.vui);
    expect(state().draft.title, 'Giúp ai đó');
  });

  test('ngày Rối: gợi ý sơ cứu và hiện một chiến thắng cũ', () async {
    notes.notes.add(sampleNote('old', DateTime(2026, 10, 2)));
    vm().selectMood(Mood.roi);
    expect(state().isRoughDay, isTrue);
    await pumpEventQueue();
    expect(state().oldNote?.id, 'old');
  });
}
