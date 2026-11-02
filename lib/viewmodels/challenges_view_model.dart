import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge.dart';
import '../models/note.dart';
import '../models/note_type.dart';
import '../services/app_exception.dart';
import '../services/challenge_repository.dart';
import '../services/clock.dart';
import '../services/note_repository.dart';
import '../services/remote_config_service.dart';
import '../utils/dates.dart';
import 'auth_view_model.dart';
import 'error_messages.dart';
import 'view_state.dart';

/// Một thẻ trên chồng thẻ S07, kèm tiến độ cấp của chủ đề.
class DeckCard {
  const DeckCard({
    required this.challenge,
    required this.levelDone,
    required this.levelTotal,
    this.easier = false,
    this.doneToday = false,
  });

  /// Thẻ tự thêm: không có cấp, nên không có thanh tiến độ.
  const DeckCard.mine(this.challenge, {this.doneToday = false})
    : levelDone = 0,
      levelTotal = 0,
      easier = false;

  final Challenge challenge;

  /// "3/5": số thẻ đã làm / số thẻ của cấp hiện tại.
  final int levelDone;
  final int levelTotal;

  /// Thẻ dễ hơn vừa chọn từ "Đổi thẻ dễ hơn" ở S08.
  final bool easier;

  /// Thẻ tự thêm đã làm hôm nay; vẫn làm lại được, nằm cuối chồng thẻ.
  final bool doneToday;

  /// "Dũng cảm · cấp 2"; thẻ tự thêm là "Của bạn · Dũng cảm".
  String get header => challenge.mine
      ? 'Của bạn · ${challenge.topic.label}'
      : '${challenge.topic.label} · cấp ${challenge.level}';
}

/// Dựng chồng thẻ từ kho thẻ, tiến độ và tâm trạng hôm qua (hàm thuần, để
/// test không cần Firestore).
abstract final class ChallengeDeck {
  /// Kho thẻ dùng được: `discord_enabled` tắt thì bỏ thẻ làm trên Discord,
  /// cấp đó chỉ còn thẻ ngoài đời.
  static List<Challenge> available(
    List<Challenge> catalog, {
    required bool discord,
  }) => discord ? catalog : catalog.where((c) => !c.onDiscord).toList();

  /// Thẻ chưa làm ở cấp hiện tại của từng chủ đề. Làm hết một cấp thì lấy cấp
  /// kế tiếp. Hôm qua tâm trạng thấp thì chủ đề Vận động lên trước (nhẹ hơn
  /// mở lời với người lạ).
  ///
  /// Thẻ tự thêm ([mine]) chưa làm hôm nay nằm ngay sau thẻ dễ hơn; thẻ đã
  /// làm hôm nay ([doneToday]) nằm cuối, vẫn làm lại được.
  static List<DeckCard> build({
    required List<Challenge> catalog,
    required Map<ChallengeTopic, ChallengeProgress> progress,
    required bool lowYesterday,
    Challenge? easier,
    List<Challenge> mine = const <Challenge>[],
    Set<String> doneToday = const <String>{},
  }) {
    final topics = lowYesterday
        ? <ChallengeTopic>[ChallengeTopic.vanDong, ChallengeTopic.dungCam]
        : <ChallengeTopic>[ChallengeTopic.dungCam, ChallengeTopic.vanDong];
    final cards = <DeckCard>[];
    if (easier != null) {
      final p = progress[easier.topic] ?? const ChallengeProgress();
      final level = catalog.where(
        (c) => c.topic == easier.topic && c.level == easier.level,
      );
      cards.add(
        DeckCard(
          challenge: easier,
          levelDone: level.where((c) => p.completed.contains(c.id)).length,
          levelTotal: level.length,
          easier: true,
        ),
      );
    }
    cards.addAll(
      mine.where((c) => !doneToday.contains(c.id)).map(DeckCard.mine),
    );
    for (final topic in topics) {
      final p = progress[topic] ?? const ChallengeProgress();
      final inTopic = catalog.where((c) => c.topic == topic).toList();
      final levels = inTopic.map((c) => c.level).toSet().toList()..sort();
      for (final level in levels.where((l) => l >= p.level)) {
        final inLevel = inTopic.where((c) => c.level == level).toList();
        final open = inLevel.where((c) => !p.completed.contains(c.id));
        if (open.isEmpty) continue;
        for (final challenge in open) {
          if (challenge.id == easier?.id) continue;
          cards.add(
            DeckCard(
              challenge: challenge,
              levelDone: inLevel.length - open.length,
              levelTotal: inLevel.length,
            ),
          );
        }
        break;
      }
    }
    cards.addAll(
      mine
          .where((c) => doneToday.contains(c.id))
          .map((c) => DeckCard.mine(c, doneToday: true)),
    );
    return cards;
  }

  /// Thẻ dễ hơn [current]: cùng chủ đề, ở cấp ngay dưới (ít phút nhất).
  /// Đang ở cấp 1 thì lấy thẻ cấp 1 ít phút hơn.
  static Challenge? easierThan(Challenge current, List<Challenge> catalog) {
    final sameTopic = catalog.where(
      (c) => c.topic == current.topic && c.id != current.id,
    );
    final lower = sameTopic.where((c) => c.level < current.level).toList();
    final candidates = lower.isNotEmpty
        ? lower
        : sameTopic
              .where(
                (c) => c.level == current.level && c.minutes < current.minutes,
              )
              .toList();
    candidates.sort(
      (a, b) => a.level != b.level
          ? b.level.compareTo(a.level)
          : a.minutes.compareTo(b.minutes),
    );
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Cấp của chủ đề sau khi làm xong [done]: lên cấp khi đã làm hết thẻ của
  /// cấp hiện tại và còn cấp sau.
  static int levelAfter(
    Challenge done,
    ChallengeProgress progress,
    List<Challenge> catalog,
  ) {
    final completed = <String>{...progress.completed, done.id};
    final inLevel = catalog.where(
      (c) => c.topic == done.topic && c.level == progress.level,
    );
    final hasNext = catalog.any(
      (c) => c.topic == done.topic && c.level > progress.level,
    );
    final levelDone =
        inLevel.isNotEmpty && inLevel.every((c) => completed.contains(c.id));
    return levelDone && hasNext ? progress.level + 1 : progress.level;
  }
}

final challengesViewModelProvider =
    NotifierProvider<ChallengesViewModel, ViewState<List<DeckCard>>>(
      ChallengesViewModel.new,
    );

/// ViewModel của S07 (flow F3, P3).
class ChallengesViewModel extends Notifier<ViewState<List<DeckCard>>> {
  List<Challenge>? _catalog;
  Map<ChallengeTopic, ChallengeProgress>? _progress;
  bool? _lowYesterday;
  Challenge? _easier;
  List<Challenge>? _mine;
  Set<String> _doneToday = const <String>{};

  ChallengeRepository get _challenges => ref.read(challengeRepositoryProvider);

  @override
  ViewState<List<DeckCard>> build() {
    ref.watch(authUserProvider.select((user) => user.value?.uid));
    _catalog = null;
    _progress = null;
    _lowYesterday = null;
    _easier = null;
    _mine = null;
    _doneToday = const <String>{};

    final now = ref.read(clockProvider).now();
    final yesterday = Dates.startOfYesterday(now);
    final subs = <StreamSubscription<Object?>>[
      _challenges.watchProgress().listen((progress) {
        _progress = progress;
        _emit();
      }, onError: _onError),
      _challenges.watchMine().listen(
        (mine) {
          _mine = mine;
          _emit();
        },
        // Thẻ tự thêm chỉ là phần thêm: lỗi thì vẫn có chồng thẻ của kho.
        onError: (Object _) {
          _mine = const <Challenge>[];
          _emit();
        },
      ),
      ref
          .read(noteRepositoryProvider)
          .watchSince(yesterday)
          .listen(
            (notes) {
              _lowYesterday = notes.any(
                (Note n) =>
                    Dates.sameDay(n.createdAt, yesterday) &&
                    (n.mood?.isLow ?? false),
              );
              _doneToday = <String>{
                for (final Note n in notes)
                  if (Dates.sameDay(n.createdAt, now) && n.challenge != null)
                    n.challenge!.challengeId,
              };
              _emit();
            },
            // Tâm trạng hôm qua chỉ để sắp thứ tự; lỗi thì dùng thứ tự mặc định.
            onError: (Object _) {
              _lowYesterday = false;
              _emit();
            },
          ),
    ];
    unawaited(_loadCatalog());
    final timeout = Timer(const Duration(seconds: 10), () {
      if (state is Loading<List<DeckCard>>) {
        state = const Failure<List<DeckCard>>(
          ErrorMessages.slow,
          offline: true,
        );
      }
    });
    ref.onDispose(() {
      timeout.cancel();
      for (final sub in subs) {
        sub.cancel();
      }
    });
    return const Loading<List<DeckCard>>();
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = ChallengeDeck.available(
        await _challenges.catalog(),
        discord: ref.read(remoteConfigServiceProvider).discordEnabled,
      );
      if (!ref.mounted) return;
      _catalog = catalog;
      _emit();
    } on Object catch (error) {
      if (ref.mounted) _onError(error);
    }
  }

  void _onError(Object error) {
    if (state is! Data<List<DeckCard>>) state = ErrorMessages.failure(error);
  }

  void _emit() {
    final catalog = _catalog;
    final progress = _progress;
    final low = _lowYesterday;
    final mine = _mine;
    if (catalog == null || progress == null || low == null || mine == null) {
      return;
    }
    final cards = ChallengeDeck.build(
      catalog: catalog,
      progress: progress,
      lowYesterday: low,
      easier: _easier,
      mine: mine,
      doneToday: _doneToday,
    );
    state = cards.isEmpty
        ? const Empty<List<DeckCard>>()
        : Data<List<DeckCard>>(cards);
  }

  void retry() => ref.invalidateSelf();

  /// "Đổi thẻ dễ hơn" ở S08: đặt thẻ dễ hơn [current] lên đầu chồng thẻ.
  /// Trả `false` khi không còn thẻ nào dễ hơn.
  Future<bool> showEasierThan(Challenge current) async {
    // S08 có thể mở thẳng từ thông báo, trước khi S07 tải kho thẻ.
    if (_catalog == null) await _loadCatalog();
    final catalog = _catalog;
    if (catalog == null || !ref.mounted) return false;
    final easier = ChallengeDeck.easierThan(current, catalog);
    if (easier == null) return false;
    _easier = easier;
    _emit();
    return true;
  }

  /// Đã làm xong một thẻ: bỏ thẻ dễ hơn đang ghim (tiến độ tự cập nhật).
  void clearEasier() {
    _easier = null;
    _emit();
  }

  /// Thêm một điều tốt nhỏ của riêng người dùng. Ném `AppException` khi tên
  /// trống hoặc quá dài, hoặc đã đủ [CustomChallengeLimits.count] thẻ.
  Future<Challenge> addMine({
    required ChallengeTopic topic,
    required String title,
    required int minutes,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.length > CustomChallengeLimits.titleMax) {
      throw const AppException(
        AppErrorKind.invalidInput,
        code: 'challenge-title',
      );
    }
    if ((_mine?.length ?? 0) >= CustomChallengeLimits.count) {
      throw const AppException(
        AppErrorKind.invalidInput,
        code: 'challenge-limit',
      );
    }
    return _challenges.addMine(
      topic: topic,
      title: trimmed,
      minutes: minutes.clamp(1, CustomChallengeLimits.minutesMax),
    );
  }

  Future<void> deleteMine(String id) => _challenges.deleteMine(id);

  /// Lời nhắn dưới ô tên khi [addMine] không thành công.
  static String addError(Object error) => switch (error) {
    AppException(code: 'challenge-limit') =>
      'Bạn đã có ${CustomChallengeLimits.count} thẻ riêng. '
          'Xoá bớt một thẻ để thêm thẻ mới.',
    AppException(code: 'challenge-title') =>
      'Tên thẻ cần từ 1 đến ${CustomChallengeLimits.titleMax} ký tự.',
    AppException(kind: AppErrorKind.permissionDenied) =>
      'Phiên đăng nhập đã hết. Đăng nhập lại rồi thử lại nhé.',
    _ => 'Chưa thêm được thẻ. Thử lại nhé.',
  };
}

/// Số thử thách đã làm hôm nay (nốt `thu_thach` tạo hôm nay): "mỗi ngày một
/// điều tốt nhỏ, cộng dồn thành điều lớn".
final goodDeedsTodayProvider = StreamProvider.autoDispose<int>((ref) {
  ref.watch(authUserProvider.select((user) => user.value?.uid));
  final now = ref.read(clockProvider).now();
  return ref
      .read(noteRepositoryProvider)
      .watchSince(Dates.startOfDay(now))
      .map(
        (notes) => notes
            .where(
              (n) =>
                  n.type == NoteType.thuThach &&
                  Dates.sameDay(n.createdAt, now),
            )
            .length,
      );
});
