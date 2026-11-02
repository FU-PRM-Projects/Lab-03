import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge.dart';

/// Kho thẻ thử thách (`challenges`) và tiến độ của người dùng đang đăng nhập
/// (`users/{uid}/challengeProgress/{topic}`). Lỗi là `AppException`.
abstract interface class ChallengeRepository {
  /// Toàn bộ kho thẻ (vài chục thẻ), sắp theo chủ đề, cấp, thứ tự.
  Future<List<Challenge>> catalog();

  /// Ném `AppException(notFound)` khi không có thẻ [id]; tìm trong kho rồi
  /// đến thẻ tự thêm của người dùng.
  Future<Challenge> get(String id);

  /// Thẻ người dùng tự thêm (`users/{uid}/customChallenges`), mới nhất trước.
  Stream<List<Challenge>> watchMine();

  /// Thêm một thẻ của riêng người dùng. Ngoại tuyến thì Firestore giữ lệnh
  /// ghi và gửi khi có mạng.
  Future<Challenge> addMine({
    required ChallengeTopic topic,
    required String title,
    required int minutes,
    String tip = '',
  });

  /// Xoá thẻ tự thêm; các nốt đã ghi từ thẻ đó vẫn còn trong hũ.
  Future<void> deleteMine(String id);

  /// Tiến độ theo chủ đề; chủ đề chưa có tài liệu thì không có trong map.
  Stream<Map<ChallengeTopic, ChallengeProgress>> watchProgress();

  /// Tiến độ hiện tại của [topic] (đọc một lần); chưa có thì cấp 1.
  Future<ChallengeProgress> progressOf(ChallengeTopic topic);

  /// Đánh dấu đã làm [challengeId]; [level] là cấp mới của chủ đề (lên cấp
  /// khi làm hết thẻ của cấp hiện tại).
  Future<void> complete(
    ChallengeTopic topic,
    String challengeId, {
    required int level,
  });
}

final challengeRepositoryProvider = Provider<ChallengeRepository>(
  (ref) =>
      throw UnimplementedError('challengeRepositoryProvider chưa được gắn'),
);
