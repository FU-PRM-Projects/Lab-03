import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/mood.dart';
import '../models/report.dart';
import '../services/app_exception.dart';
import '../services/report_services.dart';
import 'firestore_errors.dart';
import 'report_file_web.dart' if (dart.library.io) 'report_file_io.dart';

/// [ReportService] bằng gói `pdf`.
///
/// Font Be Vietnam Pro đóng gói trong `assets/fonts/` (font PDF mặc định
/// không có dấu tiếng Việt), nên tạo được PDF cả khi offline.
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

  static Future<pw.Font> _font(String name) async =>
      pw.Font.ttf(await rootBundle.load('assets/fonts/$name'));

  @override
  Future<Uint8List> weeklyCard(WeeklySummary summary) async {
    try {
      return await _build(summary);
    } on AppException {
      rethrow;
    } on Object catch (e) {
      throw AppException(AppErrorKind.unknown, code: 'pdf', detail: '$e');
    }
  }

  Future<Uint8List> _build(WeeklySummary summary) async {
    final regular = await _font('BeVietnamPro-Regular.ttf');
    final bold = await _font('BeVietnamPro-Bold.ttf');

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
}

/// [ReportFileStore] trên máy: thư mục tài liệu riêng của app, chia sẻ qua
/// hộp chia sẻ của hệ thống (`share_plus`).
class DeviceReportFileStore implements ReportFileStore {
  const DeviceReportFileStore();

  @override
  Future<SavedReport> save(Uint8List bytes, String fileName) async =>
      SavedReport(
        fileName: fileName,
        bytes: bytes,
        path: await writeReportFile(bytes, fileName),
      );

  @override
  Future<void> share(SavedReport report) async {
    final file = switch (report.path) {
      final path? => XFile(path, mimeType: 'application/pdf'),
      null => XFile.fromData(
        report.bytes,
        name: report.fileName,
        mimeType: 'application/pdf',
      ),
    };
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[file],
          fileNameOverrides: <String>[report.fileName],
          title: 'Thẻ tuần',
        ),
      );
    } on Object catch (e) {
      throw AppException(AppErrorKind.unknown, code: 'share', detail: '$e');
    }
  }
}

/// [ReportRepository] trên Firestore: `users/{uid}/reports/{isoWeek}`, chỉ
/// chủ tài khoản đọc / ghi (xem `firestore.rules`).
class FirestoreReportRepository implements ReportRepository {
  FirestoreReportRepository({
    required this.currentUid,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  /// Uid của người đang đăng nhập; `null` khi đã đăng xuất.
  final String? Function() currentUid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _reports(String uid) =>
      _db.collection('users').doc(uid).collection('reports');

  String _uid() {
    final uid = currentUid();
    if (uid == null) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        code: 'signed-out',
      );
    }
    return uid;
  }

  @override
  Future<void> record(ReportRecord record) async {
    final uid = _uid();
    try {
      await _reports(uid).doc(record.isoWeek).set(<String, Object?>{
        'kind': 'weekly_card',
        'isoWeek': record.isoWeek,
        'fileName': record.fileName,
        'sizeBytes': record.sizeBytes,
        'noteCount': record.noteCount,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw firestoreException(e);
    }
  }

  @override
  Stream<ReportRecord?> watchWeek(String isoWeek) {
    final uid = currentUid();
    if (uid == null) return Stream<ReportRecord?>.value(null);
    return _reports(uid)
        .doc(isoWeek)
        .snapshots()
        .map((snap) {
          final data = snap.data();
          if (data == null) return null;
          return ReportRecord(
            isoWeek: isoWeek,
            fileName: data['fileName'] as String? ?? '',
            sizeBytes: (data['sizeBytes'] as num?)?.toInt() ?? 0,
            noteCount: (data['noteCount'] as num?)?.toInt() ?? 0,
            savedAt: (data['savedAt'] as Timestamp?)?.toDate(),
          );
        })
        .handleError((Object e) {
          if (e is FirebaseException) throw firestoreException(e);
          throw e;
        });
  }
}
