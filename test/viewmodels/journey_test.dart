import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/challenge.dart';
import 'package:lab03/models/mood.dart';
import 'package:lab03/models/note.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/models/report.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:lab03/services/auth_service.dart';
import 'package:lab03/services/challenge_repository.dart';
import 'package:lab03/services/clock.dart';
import 'package:lab03/services/note_repository.dart';
import 'package:lab03/services/report_services.dart';
import 'package:lab03/utils/journey_stats.dart';
import 'package:lab03/viewmodels/journey_view_model.dart';
import 'package:lab03/viewmodels/view_state.dart';
import 'package:lab03/viewmodels/weekly_report_view_model.dart';

import '../support/fakes.dart';

/// S11 Hành trình. Hôm nay là Thứ Bảy 24/10/2026; tuần này từ Thứ Hai 19/10.
void main() {
  final now = DateTime(2026, 10, 24, 21, 30);

  group('JourneyStats', () {
    test('tuần bắt đầu Thứ Hai; lưới tháng 10/2026 đủ 5 tuần', () {
      expect(JourneyStats.weekStart(now), DateTime(2026, 10, 19));
      final grid = JourneyStats.monthGrid(DateTime(2026, 10));
      expect(grid.first, DateTime(2026, 9, 28));
      expect(grid.last, DateTime(2026, 11));
      expect(grid.length % 7, 0);
    });

    test('chuỗi ngày: hôm nay chưa ghi vẫn giữ chuỗi; kỷ lục', () {
      final notes = <Note>[
        for (final day in <int>[23, 22, 21, 18, 17, 16, 15])
          sampleNote('d$day', DateTime(2026, 10, day, 20)),
      ];
      expect(JourneyStats.streak(notes, now), 3);
      expect(JourneyStats.longestStreak(notes), 4);
    });

    test('năng lượng: trung bình tâm trạng mỗi ngày, ngày trống là null', () {
      final notes = <Note>[
        sampleNote('a', DateTime(2026, 10, 24, 8), mood: Mood.vui),
        sampleNote('b', DateTime(2026, 10, 24, 20), mood: Mood.met),
        sampleNote('c', DateTime(2026, 10, 22), mood: null),
      ];
      final points = JourneyStats.energy(notes, now, 7);
      expect(points, hasLength(7));
      expect(points.last.day, DateTime(2026, 10, 24));
      expect(points.last.energy, 3.5);
      expect(points.last.count, 2);
      expect(points[points.length - 3].energy, isNull);
      expect(points[points.length - 3].count, 1);
    });

    test('cân bằng 5 điều tốt tách thử thách Vận động và Người lạ', () {
      final notes = <Note>[
        sampleNote('w', now),
        sampleNote('t', now, type: NoteType.tuChu),
        Note(
          id: 'v',
          type: NoteType.thuThach,
          title: 'Đi bộ',
          createdAt: now,
          challenge: const ChallengeResult(
            challengeId: 'vd-1-1',
            subtype: 'van_dong',
            outcome: ChallengeOutcome.smooth,
          ),
        ),
        Note(
          id: 'n',
          type: NoteType.thuThach,
          title: 'Hỏi thầy',
          createdAt: now,
          challenge: const ChallengeResult(
            challengeId: 'dc-1-1',
            subtype: 'nguoi_la',
            outcome: ChallengeOutcome.smooth,
          ),
        ),
      ];
      expect(JourneyStats.balance(notes), <GoodThing, int>{
        GoodThing.chienThang: 1,
        GoodThing.nhatKy: 0,
        GoodThing.tuChu: 1,
        GoodThing.vanDong: 1,
        GoodThing.nguoiLa: 1,
      });
    });

    test('Mệt / Rối liền nhau: ngày không có tâm trạng làm đứt chuỗi', () {
      final notes = <Note>[
        for (var day = 19; day <= 23; day++)
          sampleNote('d$day', DateTime(2026, 10, day), mood: Mood.met),
      ];
      expect(JourneyStats.lowMoodRun(notes, now), 5);
      notes.add(sampleNote('ok', DateTime(2026, 10, 21, 22)));
      expect(JourneyStats.lowMoodRun(notes, now), 2);
    });

    test('tên file Thẻ tuần theo tuần ISO', () {
      final summary = WeeklySummary(
        weekStart: DateTime(2026, 10, 19),
        noteCount: 0,
        daysWithNotes: 0,
        dayMoods: List<Mood?>.filled(7, null),
        wins: const <String>[],
        balance: const <String, int>{},
      );
      expect(summary.fileName, 'weekly-2026-W43.pdf');
      expect(summary.weekEnd, DateTime(2026, 10, 25));
    });
  });

  group('JourneyViewModel', () {
    late FakeNoteRepository notes;
    late FakeChallengeRepository challenges;
    late FakeReportService reports;
    late FakeStorageService storage;

    setUp(() {
      notes = FakeNoteRepository();
      challenges = FakeChallengeRepository();
      reports = FakeReportService();
      storage = FakeStorageService();
    });

    ProviderContainer makeContainer() {
      final c = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(
            FakeAuthService(signedIn: testUser),
          ),
          noteRepositoryProvider.overrideWithValue(notes),
          challengeRepositoryProvider.overrideWithValue(challenges),
          clockProvider.overrideWithValue(FixedClock()),
          reportServiceProvider.overrideWithValue(reports),
          storageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(c.dispose);
      c.listen(journeyViewModelProvider, (_, _) {});
      return c;
    }

    JourneyState state(ProviderContainer c) => c.read(journeyViewModelProvider);
    JourneyData data(ProviderContainer c) =>
        (state(c).data as Data<JourneyData>).value;

    test('nốt tuần này so với tuần trước, mục tiêu tuần', () async {
      notes.notes.addAll(<Note>[
        for (final day in <int>[19, 20, 20, 22, 24])
          sampleNote('n$day-${notes.notes.length}', DateTime(2026, 10, day)),
        for (final day in <int>[12, 14, 15, 16])
          sampleNote('o$day', DateTime(2026, 10, day)),
      ]);
      final c = makeContainer();
      await pumpEventQueue();
      expect(data(c).thisWeek, 5);
      expect(data(c).lastWeek, 4);
      expect(data(c).weekChangePercent, 25);
      expect(data(c).weekGoalDays, 4);
    });

    test(
      'con đường: đã xong → tick, thẻ kế → ngôi sao, còn lại khoá',
      () async {
        challenges.progress[ChallengeTopic.dungCam] = const ChallengeProgress(
          completed: <String>{'dc-1-1'},
        );
        final c = makeContainer();
        await pumpEventQueue();
        final stage = (state(c).path as Data<List<PathStage>>).value.first;
        expect(stage.topic, ChallengeTopic.dungCam);
        expect(stage.nodes.map((n) => n.status), <PathNodeStatus>[
          PathNodeStatus.done,
          PathNodeStatus.current,
          PathNodeStatus.locked,
        ]);
        expect(stage.done, 1);
        expect(stage.current?.challenge.id, 'dc-1-2');
        expect(stage.hasNextLevel, isTrue);
      },
    );

    test('P6: Mệt / Rối 5 ngày liền bật gợi ý hỗ trợ, "Để sau" tắt', () async {
      notes.notes.addAll(<Note>[
        for (var day = 20; day <= 24; day++)
          sampleNote('d$day', DateTime(2026, 10, day), mood: Mood.roi),
      ]);
      final c = makeContainer();
      await pumpEventQueue();
      expect(state(c).supportVisible, isTrue);
      c.read(journeyViewModelProvider.notifier).dismissSupport();
      expect(state(c).supportVisible, isFalse);

      // Nốt mới không bật lại trong lần chạy app này.
      await notes.add(
        const NoteDraft(mood: Mood.roi, title: 'Thêm'),
        createdAt: now,
      );
      await pumpEventQueue();
      expect(state(c).supportVisible, isFalse);
    });

    test('lịch: không đi quá tháng hiện tại', () async {
      final c = makeContainer();
      await pumpEventQueue();
      final vm = c.read(journeyViewModelProvider.notifier)..shiftMonth(1);
      expect(state(c).month, isNull);
      vm.shiftMonth(-1);
      expect(state(c).month, DateTime(2026, 9));
    });

    test('lỗi tải nốt: Error state', () async {
      notes.watchError = const AppException(AppErrorKind.network);
      final c = makeContainer();
      await pumpEventQueue();
      expect(state(c).data, isA<Failure<JourneyData>>());
    });

    test(
      'Thẻ tuần: tạo PDF, tải lên reports/{uid}/, có link, mở chia sẻ',
      () async {
        notes.notes.addAll(<Note>[
          sampleNote('w1', DateTime(2026, 10, 20), title: 'Dọn bàn học'),
          sampleNote('w2', DateTime(2026, 10, 23), title: 'Đi bộ 20 phút'),
          sampleNote('old', DateTime(2026, 10, 12), title: 'Tuần trước'),
        ]);
        final c = makeContainer()
          ..listen(weeklyReportViewModelProvider, (_, _) {});
        await pumpEventQueue();
        final summary = c
            .read(journeyViewModelProvider.notifier)
            .weeklySummary()!;
        expect(summary.noteCount, 2);
        expect(summary.wins, <String>['Đi bộ 20 phút', 'Dọn bàn học']);
        expect(summary.dayMoods[1], Mood.on);
        expect(summary.dayMoods[0], isNull);

        await c.read(weeklyReportViewModelProvider.notifier).export(summary);
        final report = c.read(weeklyReportViewModelProvider);
        expect(report.phase, ReportPhase.done);
        expect(report.url, contains('reports/u-minh/weekly-2026-W43.pdf'));
        expect(storage.uploaded.single, 'reports/u-minh/weekly-2026-W43.pdf');
        expect(reports.shared.single, 'weekly-2026-W43.pdf');
      },
    );

    test('Thẻ tuần: mất mạng khi tải lên → báo lỗi, thử lại được', () async {
      storage.uploadError = const AppException(AppErrorKind.network);
      final c = makeContainer()
        ..listen(weeklyReportViewModelProvider, (_, _) {});
      await pumpEventQueue();
      final summary = c
          .read(journeyViewModelProvider.notifier)
          .weeklySummary()!;
      await c.read(weeklyReportViewModelProvider.notifier).export(summary);
      final report = c.read(weeklyReportViewModelProvider);
      expect(report.phase, ReportPhase.failed);
      expect(report.message, contains('Wi-Fi'));
      expect(reports.shared, isEmpty);
    });
  });
}
