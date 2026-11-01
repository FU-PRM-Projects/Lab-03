import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge.dart';
import '../models/mood.dart';
import '../models/note.dart';
import '../models/note_type.dart';
import '../models/report.dart';
import '../services/challenge_repository.dart';
import '../services/clock.dart';
import '../services/note_repository.dart';
import '../utils/dates.dart';
import '../utils/journey_stats.dart';
import 'auth_view_model.dart';
import 'error_messages.dart';
import 'view_state.dart';

/// Số liệu S11b Thống kê và S11c Lịch, tính từ nốt đã tải.
class JourneyData {
  const JourneyData({
    required this.now,
    required this.notes,
    required this.thisWeek,
    required this.lastWeek,
    required this.streak,
    required this.record,
    required this.weekGoalDays,
    required this.energy7,
    required this.energy30,
    required this.balance,
    this.previousEnergy7,
    this.previousEnergy30,
    required this.byWeekday,
    required this.dayMoods,
  });

  /// Dưới chừng này ngày có tâm trạng thì biểu đồ thay bằng lời nhắc.
  static const int minEnergyDays = 3;

  final DateTime now;

  /// Nốt từ đầu năm (hoặc 60 ngày gần nhất nếu dài hơn), mới nhất trước.
  final List<Note> notes;
  final int thisWeek;
  final int lastWeek;
  final int streak;
  final int record;
  final int weekGoalDays;
  final List<EnergyPoint> energy7;
  final List<EnergyPoint> energy30;

  /// Năng lượng trung bình của 7 / 30 ngày ngay trước khoảng đang xem, cho
  /// dòng "↑ Tăng 0,4 điểm so với 30 ngày trước"; `null` khi không có dữ liệu.
  final double? previousEnergy7;
  final double? previousEnergy30;

  /// "Cân bằng 5 điều tốt" của tháng này.
  final Map<GoodThing, int> balance;

  /// Số nốt theo thứ trong 30 ngày gần nhất (0 = Thứ Hai).
  final List<int> byWeekday;
  final Map<DateTime, Mood> dayMoods;

  /// "↑ 20%" so với tuần trước; `null` khi tuần trước không có nốt.
  int? get weekChangePercent =>
      lastWeek == 0 ? null : ((thisWeek - lastWeek) * 100 / lastWeek).round();

  /// Loại đang ít nhất tháng này, để gợi ý ("thử thêm một nốt Vận động").
  GoodThing get leastBalanced =>
      balance.entries.reduce((a, b) => b.value < a.value ? b : a).key;

  /// Nốt của một ngày (sheet khi chạm ô lịch), mới nhất trước.
  List<Note> notesOn(DateTime day) =>
      notes.where((n) => Dates.sameDay(n.createdAt, day)).toList();
}

enum PathNodeStatus { done, current, locked }

class PathNode {
  const PathNode(this.challenge, this.status);

  final Challenge challenge;
  final PathNodeStatus status;
}

/// Một chặng trên S11a Con đường: cấp hiện tại của một chủ đề.
class PathStage {
  const PathStage({
    required this.topic,
    required this.level,
    required this.nodes,
    required this.hasNextLevel,
  });

  final ChallengeTopic topic;
  final int level;
  final List<PathNode> nodes;
  final bool hasNextLevel;

  int get done => nodes.where((n) => n.status == PathNodeStatus.done).length;

  PathNode? get current =>
      nodes.where((n) => n.status == PathNodeStatus.current).firstOrNull;
}

class JourneyState {
  const JourneyState({
    this.data = const Loading<JourneyData>(),
    this.path = const Loading<List<PathStage>>(),
    this.energyDays = 30,
    this.yearMode = false,
    this.month,
    this.supportVisible = false,
  });

  final ViewState<JourneyData> data;
  final ViewState<List<PathStage>> path;

  /// Biểu đồ năng lượng 7 hoặc 30 ngày (`DropdownButton`).
  final int energyDays;

  /// Lịch: Năm (pixel) hay Tháng.
  final bool yearMode;

  /// Tháng đang xem trên lịch (ngày 1); `null` là tháng hiện tại.
  final DateTime? month;

  /// P6: Mệt / Rối 5 ngày liền, chưa đóng dialog gợi ý hỗ trợ.
  final bool supportVisible;

  JourneyState copyWith({
    ViewState<JourneyData>? data,
    ViewState<List<PathStage>>? path,
    int? energyDays,
    bool? yearMode,
    DateTime? month,
    bool? supportVisible,
  }) => JourneyState(
    data: data ?? this.data,
    path: path ?? this.path,
    energyDays: energyDays ?? this.energyDays,
    yearMode: yearMode ?? this.yearMode,
    month: month ?? this.month,
    supportVisible: supportVisible ?? this.supportVisible,
  );
}

final journeyViewModelProvider =
    NotifierProvider<JourneyViewModel, JourneyState>(JourneyViewModel.new);

/// ViewModel của S11 (flow P6, T2, T3; chặng hiện tại của F3).
class JourneyViewModel extends Notifier<JourneyState> {
  /// Mệt / Rối liền chừng này ngày thì gợi ý hỗ trợ (P6).
  static const int lowDaysForSupport = 5;

  /// Đã đóng dialog hỗ trợ trong lần chạy app này: không hỏi lại liên tục.
  bool _supportDismissed = false;

  List<Challenge>? _catalog;
  Map<ChallengeTopic, ChallengeProgress>? _progress;

  @override
  JourneyState build() {
    ref.watch(authUserProvider.select((user) => user.value?.uid));
    _catalog = null;
    _progress = null;

    final now = ref.read(clockProvider).now();
    final yearStart = DateTime(now.year);
    final sixtyDays = DateTime(now.year, now.month, now.day - 60);
    final since = sixtyDays.isBefore(yearStart) ? sixtyDays : yearStart;

    final challenges = ref.read(challengeRepositoryProvider);
    final subs = <StreamSubscription<Object?>>[
      ref
          .read(noteRepositoryProvider)
          .watchSince(since)
          .listen(
            (notes) => _onNotes(notes, now),
            onError: (Object error) {
              if (state.data is! Data<JourneyData>) {
                state = state.copyWith(data: ErrorMessages.failure(error));
              }
            },
          ),
      challenges.watchProgress().listen((progress) {
        _progress = progress;
        _emitPath();
      }, onError: _onPathError),
    ];
    unawaited(_loadCatalog(challenges));

    // T3 → T2: quá 10 giây chưa có dữ liệu thì báo lỗi.
    final timeout = Timer(const Duration(seconds: 10), () {
      if (state.data is Loading<JourneyData>) {
        state = state.copyWith(
          data: const Failure<JourneyData>(ErrorMessages.slow, offline: true),
        );
      }
    });
    ref.onDispose(() {
      timeout.cancel();
      for (final sub in subs) {
        sub.cancel();
      }
    });
    return const JourneyState();
  }

  void _onNotes(List<Note> notes, DateTime now) {
    final week = JourneyStats.weekStart(now);
    final lastWeekStart = DateTime(week.year, week.month, week.day - 7);
    final nextWeek = DateTime(week.year, week.month, week.day + 7);
    final thirtyDays = DateTime(now.year, now.month, now.day - 29);
    final data = JourneyData(
      now: now,
      notes: notes,
      thisWeek: JourneyStats.between(notes, week, nextWeek).length,
      lastWeek: JourneyStats.between(notes, lastWeekStart, week).length,
      streak: JourneyStats.streak(notes, now),
      record: JourneyStats.longestStreak(notes),
      weekGoalDays: JourneyStats.daysWithNotesThisWeek(notes, now),
      energy7: JourneyStats.energy(notes, now, 7),
      energy30: JourneyStats.energy(notes, now, 30),
      previousEnergy7: JourneyStats.average(
        JourneyStats.energy(
          notes,
          DateTime(now.year, now.month, now.day - 7),
          7,
        ),
      ),
      previousEnergy30: JourneyStats.average(
        JourneyStats.energy(
          notes,
          DateTime(now.year, now.month, now.day - 30),
          30,
        ),
      ),
      balance: JourneyStats.balance(
        JourneyStats.between(
          notes,
          Dates.startOfMonth(now),
          Dates.startOfNextMonth(now),
        ),
      ),
      byWeekday: JourneyStats.byWeekday(
        JourneyStats.between(notes, thirtyDays, nextWeek),
      ),
      dayMoods: JourneyStats.dayMoods(notes),
    );
    final low = JourneyStats.lowMoodRun(notes, now) >= lowDaysForSupport;
    state = state.copyWith(
      data: Data<JourneyData>(data),
      supportVisible: low && !_supportDismissed,
    );
  }

  Future<void> _loadCatalog(ChallengeRepository challenges) async {
    try {
      final catalog = await challenges.catalog();
      if (!ref.mounted) return;
      _catalog = catalog;
      _emitPath();
    } on Object catch (error) {
      if (ref.mounted) _onPathError(error);
    }
  }

  void _onPathError(Object error) {
    if (state.path is! Data<List<PathStage>>) {
      state = state.copyWith(path: ErrorMessages.failure(error));
    }
  }

  void _emitPath() {
    final catalog = _catalog;
    final progress = _progress;
    if (catalog == null || progress == null) return;
    final stages = <PathStage>[
      for (final topic in ChallengeTopic.values)
        ?_stage(topic, catalog, progress[topic]),
    ];
    state = state.copyWith(
      path: stages.isEmpty
          ? const Empty<List<PathStage>>()
          : Data<List<PathStage>>(stages),
    );
  }

  static PathStage? _stage(
    ChallengeTopic topic,
    List<Challenge> catalog,
    ChallengeProgress? progress,
  ) {
    final p = progress ?? const ChallengeProgress();
    final inTopic = catalog.where((c) => c.topic == topic).toList();
    if (inTopic.isEmpty) return null;
    final level = inTopic.any((c) => c.level == p.level)
        ? p.level
        : inTopic.map((c) => c.level).reduce((a, b) => a < b ? a : b);
    // Đã làm → tick; thẻ chưa làm đầu tiên → ngôi sao; còn lại → ổ khoá.
    final nodes = <PathNode>[];
    for (final c in inTopic.where((c) => c.level == level)) {
      final status = p.completed.contains(c.id)
          ? PathNodeStatus.done
          : nodes.any((n) => n.status == PathNodeStatus.current)
          ? PathNodeStatus.locked
          : PathNodeStatus.current;
      nodes.add(PathNode(c, status));
    }
    return PathStage(
      topic: topic,
      level: level,
      nodes: nodes,
      hasNextLevel: inTopic.any((c) => c.level > level),
    );
  }

  void retry() => ref.invalidateSelf();

  void setEnergyDays(int days) => state = state.copyWith(energyDays: days);

  void setYearMode(bool yearMode) => state = state.copyWith(yearMode: yearMode);

  /// Lùi / tới một tháng trên lịch (không quá tháng hiện tại).
  void shiftMonth(int delta) {
    final now = ref.read(clockProvider).now();
    final current = state.month ?? Dates.startOfMonth(now);
    final next = DateTime(current.year, current.month + delta);
    if (next.isAfter(Dates.startOfMonth(now))) return;
    state = state.copyWith(month: next);
  }

  /// "Để sau" / đóng dialog hỗ trợ (P6).
  void dismissSupport() {
    _supportDismissed = true;
    state = state.copyWith(supportVisible: false);
  }

  /// Nội dung Thẻ tuần cho tuần hiện tại.
  WeeklySummary? weeklySummary() {
    final value = state.data;
    if (value is! Data<JourneyData>) return null;
    final data = value.value;
    final start = JourneyStats.weekStart(data.now);
    final end = DateTime(start.year, start.month, start.day + 7);
    final week = JourneyStats.between(data.notes, start, end);
    return WeeklySummary(
      weekStart: start,
      noteCount: week.length,
      daysWithNotes: data.weekGoalDays,
      dayMoods: <Mood?>[
        for (var i = 0; i < 7; i++)
          data.dayMoods[DateTime(start.year, start.month, start.day + i)],
      ],
      wins: week
          .where((n) => n.type == NoteType.chienThang)
          .take(3)
          .map((n) => n.title)
          .toList(),
      balance: <String, int>{
        for (final entry in JourneyStats.balance(week).entries)
          entry.key.label: entry.value,
      },
      energy: JourneyStats.average(
        JourneyStats.energy(week, data.now, data.now.weekday),
      ),
    );
  }
}
