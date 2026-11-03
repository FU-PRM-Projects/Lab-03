import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/note.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:lab03/services/auth_service.dart';
import 'package:lab03/services/clock.dart';
import 'package:lab03/services/note_repository.dart';
import 'package:lab03/viewmodels/note_saved_view_model.dart';
import 'package:lab03/viewmodels/today_view_model.dart';
import 'package:lab03/viewmodels/view_state.dart';

import '../support/fakes.dart';

void main() {
  late FakeNoteRepository notes;
  late FixedClock clock;

  ProviderContainer makeContainer({bool smallMilestone = false}) {
    final c = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(
          FakeAuthService(signedIn: testUser),
        ),
        noteRepositoryProvider.overrideWithValue(notes),
        clockProvider.overrideWithValue(clock),
        // Mốc tháng nhỏ để dễ chạm mốc trong test.
        if (smallMilestone) monthlyMilestoneProvider.overrideWithValue(3),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    notes = FakeNoteRepository();
    clock = FixedClock(); // Thứ Bảy, 24/10/2026, 21:30.
  });

  group('TodayViewModel (S02)', () {
    Future<TodaySummary> summary(ProviderContainer c) async {
      c.listen(todayViewModelProvider, (_, _) {});
      await pumpEventQueue();
      final state = c.read(todayViewModelProvider);
      expect(state, isA<Data<TodaySummary>>());
      return (state as Data<TodaySummary>).value;
    }

    test('đếm nốt hôm nay và tháng này, bỏ nốt tháng trước', () async {
      notes.notes.addAll(<Note>[
        sampleNote('a', DateTime(2026, 10, 24, 8)),
        sampleNote('b', DateTime(2026, 10, 24, 20), type: NoteType.tuChu),
        sampleNote('c', DateTime(2026, 10, 3)),
        sampleNote('d', DateTime(2026, 9, 30)),
      ]);
      final s = await summary(makeContainer());
      expect(s.todayCount, 2);
      expect(s.monthCount, 3);
      expect(s.jarNotes.first, NoteType.tuChu);
      expect(s.fallenNote, isNull);
      expect(s.pendingSync, isFalse);
    });

    test('hôm qua Mệt: một chiến thắng cũ rơi ra khỏi hũ (P6)', () async {
      notes.notes.addAll(<Note>[
        sampleNote('old', DateTime(2026, 10, 10)),
        sampleNote('y', DateTime(2026, 10, 23, 22), mood: Mood.met),
      ]);
      final s = await summary(makeContainer());
      expect(s.fallenNote?.id, 'old');
    });

    test('chọn chiến thắng đáng nhớ: lần đầu > có nhật ký > thường', () async {
      notes.notes.addAll(<Note>[
        sampleNote('plain', DateTime(2026, 10, 12), title: 'Uống đủ nước'),
        Note(
          id: 'journal',
          type: NoteType.chienThang,
          title: 'Dọn xong góc học tập',
          body: 'Nhìn gọn gàng thấy dễ chịu hẳn.',
          createdAt: DateTime(2026, 10, 11),
        ),
        Note(
          id: 'first',
          type: NoteType.chienThang,
          title: 'Thuyết trình trước lớp dù run',
          createdAt: DateTime(2026, 10, 10),
          groupId: 'len-tieng-trong-nhom',
          isFirst: true,
        ),
        sampleNote('y', DateTime(2026, 10, 23, 22), mood: Mood.roi),
      ]);
      final s = await summary(makeContainer());
      expect(s.fallenNote?.id, 'first');
    });

    test('độ đáng nhớ cộng dồn theo lần đầu, thử thách, nhật ký', () {
      final plain = sampleNote('p', DateTime(2026, 10, 2));
      final journal = Note(
        id: 'j',
        type: NoteType.chienThang,
        title: 'x',
        body: 'Có viết vài dòng',
        createdAt: DateTime(2026, 10, 2),
      );
      expect(TodayViewModel.memorability(plain), 0);
      expect(TodayViewModel.memorability(journal), 1);
    });

    test('hũ cập nhật khi lưu nốt mới; nốt offline bật banner', () async {
      final c = makeContainer();
      expect((await summary(c)).monthCount, 0);

      notes.offline = true;
      await notes.add(
        const NoteDraft(mood: Mood.on, title: 'Đi bộ'),
        createdAt: clock.current,
      );
      await pumpEventQueue();
      final s = (c.read(todayViewModelProvider) as Data<TodaySummary>).value;
      expect(s.todayCount, 1);
      expect(s.pendingSync, isTrue);
    });

    test('lỗi tải: Error state có lý do; Thử lại tải lại', () async {
      notes.watchError = const AppException(AppErrorKind.network);
      final c = makeContainer()..listen(todayViewModelProvider, (_, _) {});
      await pumpEventQueue();
      final state = c.read(todayViewModelProvider);
      expect(state, isA<Failure<TodaySummary>>());
      expect((state as Failure<TodaySummary>).offline, isTrue);

      notes.watchError = null;
      c.read(todayViewModelProvider.notifier).retry();
      await pumpEventQueue();
      expect(c.read(todayViewModelProvider), isA<Data<TodaySummary>>());
    });
  });

  group('NoteSavedViewModel (S04)', () {
    Future<ViewState<SavedNoteSummary>> load(
      ProviderContainer c,
      String id,
    ) async {
      c.listen(noteSavedViewModelProvider(id), (_, _) {});
      await pumpEventQueue();
      return c.read(noteSavedViewModelProvider(id));
    }

    test('"Nốt thứ N tháng này" và tiến độ mốc tháng', () async {
      notes.notes.addAll(<Note>[
        sampleNote('a', DateTime(2026, 10, 2)),
        sampleNote('b', DateTime(2026, 10, 24, 21)),
        sampleNote('c', DateTime(2026, 9, 29)),
      ]);
      final state = await load(makeContainer(), 'b');
      final s = (state as Data<SavedNoteSummary>).value;
      expect(s.monthCount, 2);
      expect(s.milestone, defaultMonthlyMilestone);
      expect(s.reachedMilestone, isFalse);
      expect(s.progress, closeTo(2 / 25, 1e-9));
      expect(s.savedToday, isTrue);
    });

    test('chạm mốc tháng: Gắn vào hũ lưu nhãn dán', () async {
      notes.notes.addAll(<Note>[
        for (var day = 1; day <= 3; day++)
          sampleNote('n$day', DateTime(2026, 10, day)),
      ]);
      final c = makeContainer(smallMilestone: true);
      final s = ((await load(c, 'n3')) as Data<SavedNoteSummary>).value;
      expect(s.reachedMilestone, isTrue);
      expect(s.savedToday, isFalse);

      final error = await c
          .read(noteSavedViewModelProvider('n3').notifier)
          .pinSticker();
      expect(error, isNull);
      expect(notes.stickers.single.month, 10);
    });

    test('bộ sưu tập: 3 tháng gần nhất có nhãn dán rồi ô tháng sau', () async {
      notes.stickers.addAll(<DateTime>[
        DateTime(2026, 6),
        DateTime(2026, 8),
        DateTime(2026, 9),
      ]);
      notes.notes.addAll(<Note>[
        for (var day = 1; day <= 3; day++)
          sampleNote('n$day', DateTime(2026, 10, day)),
      ]);
      final c = makeContainer(smallMilestone: true);
      final s = ((await load(c, 'n3')) as Data<SavedNoteSummary>).value;
      expect(s.stickerMonths, <DateTime>[
        DateTime(2026, 8),
        DateTime(2026, 9),
        DateTime(2026, 10),
      ]);
      expect(s.nextStickerMonth, DateTime(2026, 11));
    });

    test('mốc đầu tiên: bộ sưu tập chỉ có tháng này', () async {
      notes.notes.add(sampleNote('n1', DateTime(2026, 12)));
      final s =
          ((await load(makeContainer(), 'n1')) as Data<SavedNoteSummary>).value;
      expect(s.stickerMonths, <DateTime>[DateTime(2026, 12)]);
      expect(s.nextStickerMonth, DateTime(2027));
    });

    test('không tìm thấy nốt: Error state', () async {
      final state = await load(makeContainer(), 'missing');
      expect(state, isA<Failure<SavedNoteSummary>>());
    });
  });
}
