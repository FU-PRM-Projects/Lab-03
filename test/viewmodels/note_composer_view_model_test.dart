import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/models/image_ref.dart';
import 'package:lab03/models/note.dart';
import 'package:lab03/models/note_type.dart';
import 'package:lab03/services/analytics_events.dart';
import 'package:lab03/services/analytics_service.dart';
import 'package:lab03/services/app_exception.dart';
import 'package:lab03/services/clock.dart';
import 'package:lab03/services/draft_store.dart';
import 'package:lab03/services/image_service.dart';
import 'package:lab03/services/note_repository.dart';
import 'package:lab03/viewmodels/image_upload_view_model.dart';
import 'package:lab03/viewmodels/note_composer_view_model.dart';
import 'package:lab03/viewmodels/today_view_model.dart';

import '../support/fakes.dart';

const _photo = ImageRef(
  url: 'https://res.cloudinary.com/demo/image/upload/moment.jpg',
  publicId: 'notes/moment',
);

class _FakePicker implements ImagePickerService {
  @override
  Future<PickedImage?> pick(ImagePickSource source) async =>
      PickedImage(bytes: Uint8List(8), fileName: 'moment.jpg');
}

class _FakeCloudinary implements ImageService {
  /// Giữ lần tải ở nửa chừng cho tới khi test cho chạy tiếp.
  Completer<void>? gate;

  @override
  Stream<ImageUploadProgress> upload(
    PickedImage image, {
    required ImageFolder folder,
  }) async* {
    yield const ImageUploadProgress(0.5);
    await gate?.future;
    yield const ImageUploadProgress(1, image: _photo);
  }
}

/// Flow F1: S03a ảnh khoảnh khắc → S03b chiến thắng → S03c nhật ký → lưu.
void main() {
  late FakeNoteRepository notes;
  late FakeDraftStore drafts;
  late FixedClock clock;
  late FakeAnalyticsService analytics;
  late _FakeCloudinary cloudinary;
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
        analyticsServiceProvider.overrideWithValue(analytics),
        imagePickerServiceProvider.overrideWithValue(_FakePicker()),
        imageServiceProvider.overrideWithValue(cloudinary),
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
    analytics = FakeAnalyticsService();
    cloudinary = _FakeCloudinary();
    container = makeContainer();
  });

  Future<void> takePhoto() async {
    await container
        .read(imageUploadViewModelProvider(ImageFolder.note).notifier)
        .pickAndUpload(ImagePickSource.camera);
    await pumpEventQueue();
  }

  test('bước 1: chưa có ảnh thì Tiếp bị khoá, Bỏ qua sang bước 2', () {
    expect(state().step, 1);
    expect(state().canContinue, isFalse);
    vm().next();
    expect(state().step, 1);

    vm().skipPhoto();
    expect(state().step, 2);
    expect(state().draft.image, isNull);
  });

  test(
    'chụp ảnh xong: ảnh vào nháp, Tiếp mở, rồi mới tới bước chiến thắng',
    () async {
      await takePhoto();
      expect(state().draft.image, _photo);
      expect(state().canContinue, isTrue);

      vm().next();
      expect(state().step, 2);
      expect(state().draft.image, _photo);
    },
  );

  test('ảnh đang tải: không sang bước 2 để khỏi mất ảnh', () async {
    cloudinary.gate = Completer<void>();
    final upload = container
        .read(imageUploadViewModelProvider(ImageFolder.note).notifier)
        .pickAndUpload(ImagePickSource.camera);
    await pumpEventQueue();

    vm()
      ..skipPhoto()
      ..next();
    expect(state().step, 1);

    cloudinary.gate!.complete();
    await upload;
    await pumpEventQueue();
    expect(state().draft.image, _photo);
    vm().next();
    expect(state().step, 2);
  });

  test('gỡ ảnh: nháp không còn ảnh', () async {
    await takePhoto();
    vm().removeImage();
    expect(state().draft.image, isNull);
    expect(state().canContinue, isFalse);
  });

  test('bước 2: ô trống khoá Tiếp; chạm chip điền tên chip', () {
    vm().skipPhoto();
    expect(state().canContinue, isFalse);
    expect(state().quickWins, hasLength(6));

    vm().pickQuickWin('Đi bộ');
    expect(state().draft.title, 'Đi bộ');
    expect(state().canContinue, isTrue);

    vm().setTitle('   ');
    expect(state().canContinue, isFalse);
  });

  test('lưu xong ghi note_saved với duration_ms, không kèm nội dung', () async {
    clock.current = clock.current.add(const Duration(seconds: 12));
    vm()
      ..skipPhoto()
      ..setTitle('Chuyện riêng tư')
      ..next()
      ..setBody('Nội dung nhật ký');
    await vm().save();
    await Future<void>.delayed(Duration.zero);

    final event = analytics.events.single;
    expect(event.name, AnalyticsEvents.noteSaved);
    expect(event.params[AnalyticsParams.durationMs], 12000);
    expect(event.params[AnalyticsParams.mood], 'none');
    expect(event.params[AnalyticsParams.hasJournal], 'true');
    expect(event.params.values.join(), isNot(contains('riêng tư')));
    expect(event.params.values.join(), isNot(contains('nhật ký')));
  });

  test(
    'happy path: lưu nốt kèm ảnh khoảnh khắc, không cần tâm trạng',
    () async {
      drafts.draft = const NoteDraft(title: 'cũ');
      await takePhoto();
      vm()
        ..next()
        ..setTitle('  Dọn bàn học  ')
        ..next()
        ..setBody(' Nhẹ hơn hôm qua. ');
      await vm().save();

      final saved = notes.notes.single;
      expect(saved.type, NoteType.chienThang);
      expect(saved.mood, isNull);
      expect(saved.title, 'Dọn bàn học');
      expect(saved.body, 'Nhẹ hơn hôm qua.');
      expect(saved.image, _photo);
      expect(saved.createdAt, clock.current);
      expect(state().savedNoteId, saved.id);
      expect(drafts.draft, isNull);
    },
  );

  test('bỏ qua ảnh: nốt lưu không kèm ảnh', () async {
    vm()
      ..skipPhoto()
      ..setTitle('Đi bộ');
    await vm().save(skipJournal: true);
    expect(notes.notes.single.image, isNull);
  });

  test('"Bỏ qua phần kể thêm" lưu luôn với nhật ký rỗng', () async {
    vm()
      ..skipPhoto()
      ..setBody('sẽ bị bỏ')
      ..pickQuickWin('Ăn đủ bữa');
    await vm().save(skipJournal: true);
    expect(notes.notes.single.body, isEmpty);
  });

  test('không lưu khi thiếu tiêu đề hoặc tiêu đề quá 120 ký tự', () async {
    await vm().save();
    vm().setTitle('a' * 121);
    await vm().save();
    expect(notes.notes, isEmpty);
  });

  test('đang lưu: saving = true, bấm lần nữa không tạo nốt thứ hai', () async {
    final gate = Completer<void>();
    notes.addGate = gate;
    vm().setTitle('Đi bộ');
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
    vm().setTitle('Đi bộ');
    await vm().save();
    expect(state().savedNoteId, isNull);
    expect(state().message, contains('Chưa lưu được'));
    expect(drafts.draft?.title, 'Đi bộ');
  });

  test('Back: bước 3 về 2, bước 2 về 1, bước 1 có dữ liệu thì hỏi', () {
    expect(vm().back(), ComposerBack.close);
    vm()
      ..skipPhoto()
      ..setTitle('Đi bộ')
      ..next();
    expect(state().step, 3);
    expect(vm().back(), ComposerBack.previousStep);
    expect(state().step, 2);
    expect(vm().back(), ComposerBack.previousStep);
    expect(state().step, 1);
    expect(vm().back(), ComposerBack.confirmKeepDraft);
  });

  test('Giữ nháp: lưu trên máy và S02 thấy có nháp', () async {
    expect(await container.read(hasDraftProvider.future), isFalse);
    vm().setTitle('Đi bộ');
    await vm().keepDraft();
    expect(drafts.draft?.title, 'Đi bộ');
    expect(await container.read(hasDraftProvider.future), isTrue);

    await vm().discardDraft();
    expect(drafts.draft, isNull);
  });

  test('mở lại S03: điền sẵn nháp đã giữ', () async {
    drafts.draft = const NoteDraft(title: 'Giúp ai đó', image: _photo);
    container = makeContainer();
    await pumpEventQueue();
    expect(state().draft.title, 'Giúp ai đó');
    expect(state().draft.image, _photo);
  });
}
