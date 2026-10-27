import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../models/mood.dart';

/// 8 trạng thái của component `Mascot` (Tụi Nốt, DESIGN.md mục 9).
enum MascotState {
  thongTha('thong-tha', 'Nốt Thong Thả'),
  voi('voi', 'Nốt Vội'),
  chay('chay', 'Nốt Cháy'),
  xong('xong', 'Nốt Xong'),
  ngu('ngu', 'Nốt Ngủ'),
  doi('doi', 'Nốt Đợi'),
  lac('lac', 'Nốt Lạc'),
  tapTrung('tap-trung', 'Nốt Tập Trung');

  const MascotState(this.fileName, this.label);

  final String fileName;
  final String label;

  String get asset => 'assets/mascot/mascot-not-$fileName.svg';
}

/// Mặt mascot đi kèm mỗi tâm trạng, để tâm trạng không chỉ báo bằng màu.
extension MoodMascot on Mood {
  MascotState get mascot => switch (this) {
    Mood.vui => MascotState.xong,
    Mood.on => MascotState.thongTha,
    Mood.binhThuong => MascotState.doi,
    Mood.met => MascotState.ngu,
    Mood.roi => MascotState.lac,
  };
}

/// Component `Mascot`. Mặc định là hình trang trí (bị bỏ khỏi cây
/// accessibility); truyền [semanticLabel] khi hình mang thông tin.
class Mascot extends StatelessWidget {
  const Mascot({
    required this.state,
    this.size = 96,
    this.semanticLabel,
    super.key,
  });

  final MascotState state;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      state.asset,
      width: size,
      height: size,
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
