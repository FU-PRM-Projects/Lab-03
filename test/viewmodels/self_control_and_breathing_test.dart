import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/models/self_control.dart';
import 'package:lab03/services/auth_service.dart';
import 'package:lab03/services/clock.dart';
import 'package:lab03/services/note_repository.dart';
import 'package:lab03/services/self_control_services.dart';
import 'package:lab03/viewmodels/breathing_view_model.dart';
import 'package:lab03/viewmodels/self_control_view_model.dart';
import 'package:lab03/viewmodels/view_state.dart';

import '../support/fakes.dart';

/// Flow F2 Tự chủ: S09 và S10.
void main() {
  late FakeNoteRepository notes;
  late FakeSelfControl selfControl;
  late FakeLocalAuth localAuth;
  late FakeScreenGuard guard;

  setUp(() {
    notes = FakeNoteRepository();
    selfControl = FakeSelfControl();
    localAuth = FakeLocalAuth();
    guard = FakeScreenGuard();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(
          FakeAuthService(signedIn: testUser),
        ),
        noteRepositoryProvider.overrideWithValue(notes),
        clockProvider.overrideWithValue(FixedClock()),
        habitRepositoryProvider.overrideWithValue(selfControl),
        settingsRepositoryProvider.overrideWithValue(selfControl.settingsView),
        localAuthServiceProvider.overrideWithValue(localAuth),
        screenGuardProvider.overrideWithValue(guard),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('SelfControlViewModel (S09)', () {
    Future<ProviderContainer> open() async {
      final c = makeContainer()
        ..listen(selfControlViewModelProvider, (_, _) {});
      await pumpEventQueue();
      return c;
    }

    SelfControlViewModel vm(ProviderContainer c) =>
        c.read(selfControlViewModelProvider.notifier);
    SelfControlState state(ProviderContainer c) =>
        c.read(selfControlViewModelProvider);
    SelfControlSummary summary(ProviderContainer c) =>
        (state(c).summary as Data<SelfControlSummary>).value;

    test('đếm lần tự chủ tháng này; bật FLAG_SECURE khi mở', () async {
      notes.notes.addAll([
        sampleNote('a', DateTime(2026, 10, 3), type: NoteType.tuChu),
        sampleNote('b', DateTime(2026, 10, 20), type: NoteType.tuChu),
        sampleNote('c', DateTime(2026, 10, 21)),
        sampleNote('d', DateTime(2026, 9, 30), type: NoteType.tuChu),
      ]);
      final c = await open();
      expect(summary(c).monthCount, 2);
      expect(guard.secure, isTrue);
      c.dispose();
      expect(guard.secure, isFalse);
    });

    test('"Mình vừa dừng lại": ghi một nốt tự chủ có giờ, mở S04', () async {
      final c = await open();
      await vm(c).recordStop();
      final saved = notes.notes.single;
      expect(saved.type, NoteType.tuChu);
      expect(saved.title, 'Dừng lại lúc 21:30');
      expect(state(c).savedNoteId, saved.id);
    });

    test(
      'chọn / bỏ chọn thói quen lưu ngay; + Thêm kiểm tra dữ liệu',
      () async {
        final c = await open();
        await vm(c).toggleHabit('Video ngắn');
        // Chờ luồng thói quen phát lại trước khi chạm lần nữa.
        await pumpEventQueue();
        expect(selfControl.habits.selected, contains('Video ngắn'));
        await vm(c).toggleHabit('Video ngắn');
        await pumpEventQueue();
        expect(selfControl.habits.selected, isEmpty);

        expect(await vm(c).addHabit('  '), isNotNull);
        expect(await vm(c).addHabit('a' * 41), contains('40'));
        expect(await vm(c).addHabit('video ngắn'), contains('đã có'));
        expect(await vm(c).addHabit('Đọc truyện tới 2h'), isNull);
        await pumpEventQueue();
        expect(summary(c).habits.all.last, 'Đọc truyện tới 2h');
        expect(summary(c).habits.selected, contains('Đọc truyện tới 2h'));
      },
    );

    test('bật khoá: che thói quen; mở khoá thành công / thất bại', () async {
      selfControl.settings = const UserSettings(lockSelfControl: true);
      final c = await open();
      expect(state(c).habitsLocked, isTrue);

      // Đang khoá thì chạm chip không đổi gì.
      await vm(c).toggleHabit('Video ngắn');
      expect(selfControl.habits.selected, isEmpty);

      localAuth.result = false;
      await vm(c).unlock();
      expect(state(c).habitsLocked, isTrue);
      expect(state(c).message, 'Chưa mở được phần này.');

      localAuth.result = true;
      await vm(c).unlock();
      expect(state(c).habitsLocked, isFalse);

      // Rời app thì khoá lại.
      vm(c).lock();
      expect(state(c).habitsLocked, isTrue);
    });

    test('đã lỡ lướt: ghi nhẹ thành nhật ký, không trừ gì', () async {
      final c = await open();
      expect(await vm(c).recordSlip('Mệt'), isTrue);
      final note = notes.notes.single;
      expect(note.type, NoteType.nhatKy);
      expect(note.body, 'Lúc đó mình đang thấy: mệt.');
      await pumpEventQueue();
      expect(summary(c).monthCount, 0);
    });

    test('Giờ tỉnh: bật / tắt và đổi khung giờ', () async {
      final c = await open();
      await vm(c).setAwakeEnabled(false);
      await pumpEventQueue();
      expect(selfControl.settings.awakeEnabled, isFalse);
      await vm(c).setAwakeTimes(22 * 60 + 30, 30);
      expect(selfControl.settings.awakeStart, 22 * 60 + 30);
      expect(selfControl.settings.awakeEnd, 30);
    });
  });

  group('BreathingViewModel (S10)', () {
    test('kiểu 4-6: 9 nhịp trong 90 giây rồi "Xong một vòng"', () {
      fakeAsync((async) {
        final c = makeContainer()
          ..listen(breathingViewModelProvider, (_, _) {});
        BreathingState s() => c.read(breathingViewModelProvider);

        expect(s().phase, BreathPhase.inhale);
        expect(s().remaining, 90);
        expect(guard.keepScreenOn, isTrue);

        async.elapse(const Duration(seconds: 4));
        expect(s().phase, BreathPhase.exhale);
        async.elapse(const Duration(seconds: 6));
        expect(s().phase, BreathPhase.inhale);
        expect(s().remaining, 80);

        async.elapse(const Duration(seconds: 85));
        expect(s().remaining, 0);
        expect(s().roundDone, isTrue);
        expect(guard.keepScreenOn, isFalse);

        c.read(breathingViewModelProvider.notifier).restart();
        expect(s().remaining, 90);
        expect(guard.keepScreenOn, isTrue);
      });
    });

    test('đổi kiểu 4-7-8: có bước giữ hơi, đếm lại từ đầu', () {
      fakeAsync((async) {
        final c = makeContainer()
          ..listen(breathingViewModelProvider, (_, _) {});
        async.elapse(const Duration(seconds: 20));
        c
            .read(breathingViewModelProvider.notifier)
            .changePattern(BreathPattern.fourSevenEight);
        final s = c.read(breathingViewModelProvider);
        expect(s.elapsed, 0);
        expect(s.pattern.description, '4 giây vào · 7 giây giữ · 8 giây ra');
        async.elapse(const Duration(seconds: 5));
        expect(c.read(breathingViewModelProvider).phase, BreathPhase.hold);
      });
    });

    test('"Cơn sóng đã hạ" → chọn việc thay thế → Ghi vào hũ', () async {
      notes.notes.add(
        sampleNote('t', DateTime(2026, 10, 24, 1), type: NoteType.tuChu),
      );
      final c = makeContainer()..listen(breathingViewModelProvider, (_, _) {});
      final vm = c.read(breathingViewModelProvider.notifier);
      await vm.finish();
      expect(c.read(breathingViewModelProvider).after, isTrue);
      expect(c.read(breathingViewModelProvider).todayStops, 1);

      vm.chooseAlternative('Uống nước');
      await vm.saveToJar();
      final saved = notes.notes.last;
      expect(saved.type, NoteType.tuChu);
      expect(saved.title, 'Thở 90 giây rồi uống nước');
      expect(c.read(breathingViewModelProvider).savedNoteId, saved.id);
    });
  });
}
