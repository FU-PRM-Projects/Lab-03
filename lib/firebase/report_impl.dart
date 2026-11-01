import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/mood.dart';
import '../models/report.dart';
import '../services/app_exception.dart';
import '../services/report_services.dart';

/// [ReportService] bằng gói `pdf`, chia sẻ qua `printing`.
///
/// Font Be Vietnam Pro tải qua `PdfGoogleFonts` (font PDF mặc định không có
/// dấu tiếng Việt), lưu đệm sau lần tải đầu.
class PdfReportService implements ReportService {
  const PdfReportService();

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  static const List<String> _weekdays = <String>[
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  /// Màu tâm trạng theo token `heat/1` … `heat/5`, cùng ánh xạ với
  /// `AppColors.mood` (gói `pdf` không đọc được ThemeData).
  static PdfColor _moodColor(Mood? mood) => switch (mood) {
    Mood.vui => const PdfColor.fromInt(0xFFA9DCF5),
    Mood.on => const PdfColor.fromInt(0xFF7FD9B3),
    Mood.binhThuong => const PdfColor.fromInt(0xFFFFD24A),
    Mood.met => const PdfColor.fromInt(0xFFFF9A3D),
    Mood.roi => const PdfColor.fromInt(0xFFF0524B),
    null => const PdfColor.fromInt(0xFFE7E9F3),
  };

  @override
  Future<Uint8List> weeklyCard(WeeklySummary summary) async {
    final pw.Font regular;
    final pw.Font bold;
    try {
      regular = await PdfGoogleFonts.beVietnamProRegular();
      bold = await PdfGoogleFonts.beVietnamProBold();
    } on Object catch (e) {
      throw AppException(
        AppErrorKind.network,
        code: 'font-download',
        detail: '$e',
      );
    }

    const primary = PdfColor.fromInt(0xFF3D4FD6);
    const muted = PdfColor.fromInt(0xFF555B6E);
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      title: 'Thẻ tuần ${summary.isoWeek}',
      author: 'Nốt',
    );
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              'THẺ TUẦN · NỐT',
              style: const pw.TextStyle(
                fontSize: 10,
                color: muted,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${_date(summary.weekStart)} – ${_date(summary.weekEnd)}',
              style: const pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              children: <pw.Widget>[
                _stat('Nốt tuần này', '${summary.noteCount}', primary),
                pw.SizedBox(width: 12),
                _stat(
                  'Mục tiêu tuần',
                  '${summary.daysWithNotes}/7 ngày',
                  primary,
                ),
                pw.SizedBox(width: 12),
                _stat(
                  'Năng lượng',
                  summary.energy == null
                      ? '–'
                      : '${summary.energy!.toStringAsFixed(1).replaceAll('.', ',')}/5',
                  primary,
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Tâm trạng 7 ngày',
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: <pw.Widget>[
                for (var i = 0; i < 7; i++)
                  pw.Expanded(
                    child: pw.Column(
                      children: <pw.Widget>[
                        pw.Container(
                          height: 24,
                          margin: const pw.EdgeInsets.symmetric(horizontal: 2),
                          decoration: pw.BoxDecoration(
                            color: _moodColor(summary.dayMoods[i]),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          _weekdays[i],
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          summary.dayMoods[i]?.label ?? '',
                          style: const pw.TextStyle(fontSize: 8, color: muted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Chiến thắng nhỏ',
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            if (summary.wins.isEmpty)
              pw.Text(
                'Tuần sau ghi thêm vài chiến thắng nhé.',
                style: const pw.TextStyle(color: muted),
              )
            else
              for (final win in summary.wins) pw.Bullet(text: win),
            pw.SizedBox(height: 16),
            pw.Text(
              'Cân bằng 5 điều tốt',
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 12,
              runSpacing: 4,
              children: <pw.Widget>[
                for (final entry in summary.balance.entries)
                  pw.Text('${entry.key}: ${entry.value}'),
              ],
            ),
            pw.Spacer(),
            pw.Text(
              'Mỗi ngày một nốt tích cực.',
              style: const pw.TextStyle(color: muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  static pw.Widget _stat(String label, String value, PdfColor color) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFEEF0FE),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 2),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Future<void> share(Uint8List bytes, String fileName) async {
    try {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } on Object catch (e) {
      throw AppException(AppErrorKind.unknown, code: 'share', detail: '$e');
    }
  }
}

/// [StorageService] trên Firebase Storage, đường dẫn `reports/{uid}/…`
/// (`storage.rules` chỉ cho chủ thư mục đọc / ghi).
class FirebaseStorageService implements StorageService {
  FirebaseStorageService({required this.currentUid, FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  /// Uid của người đang đăng nhập; `null` khi đã đăng xuất.
  final String? Function() currentUid;
  final FirebaseStorage _storage;

  static AppException _map(FirebaseException e) => AppException(
    switch (e.code) {
      'unauthorized' || 'unauthenticated' => AppErrorKind.permissionDenied,
      'canceled' => AppErrorKind.cancelled,
      'retry-limit-exceeded' || 'unknown' => AppErrorKind.network,
      'object-not-found' => AppErrorKind.notFound,
      _ => AppErrorKind.unknown,
    },
    code: e.code,
    detail: e.message,
  );

  @override
  Stream<UploadProgress> uploadReport(String fileName, Uint8List bytes) async* {
    final uid = currentUid();
    if (uid == null) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        code: 'signed-out',
      );
    }
    final ref = _storage.ref('reports/$uid/$fileName');
    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: 'application/pdf'),
    );
    try {
      await for (final snapshot in task.snapshotEvents) {
        final total = snapshot.totalBytes;
        if (snapshot.state == TaskState.running && total > 0) {
          yield UploadProgress(snapshot.bytesTransferred / total);
        }
        if (snapshot.state == TaskState.success) break;
      }
      await task;
      yield UploadProgress(1, url: await ref.getDownloadURL());
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }
}
