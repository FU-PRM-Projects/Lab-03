import 'package:flutter_test/flutter_test.dart';
import 'package:lab03/theme/app_theme.dart';
import 'package:lab03/viewmodels/breathing_view_model.dart';
import 'package:lab03/widgets/breathing_buddy.dart';
import 'package:lab03/widgets/mascot.dart';
import 'package:material_ui/material_ui.dart';

/// S10: Nốt đổi nét mặt theo nhịp thở và vẫn đứng yên khi máy tắt chuyển động.
void main() {
  Widget host(BreathPhase phase, {bool done = false, bool noMotion = false}) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: noMotion),
        child: Scaffold(
          body: Center(
            child: BreathingBuddy(phase: phase, phaseSeconds: 4, done: done),
          ),
        ),
      ),
    );
  }

  MascotState face(WidgetTester tester) =>
      tester.widgetList<Mascot>(find.byType(Mascot)).last.state;

  testWidgets('nét mặt đổi theo nhịp: hít, giữ, thở, xong', (tester) async {
    await tester.pumpWidget(host(BreathPhase.inhale));
    expect(face(tester), MascotState.tapTrung);

    await tester.pumpWidget(host(BreathPhase.hold));
    await tester.pump(const Duration(milliseconds: 400));
    expect(face(tester), MascotState.doi);

    await tester.pumpWidget(host(BreathPhase.exhale));
    await tester.pump(const Duration(milliseconds: 400));
    expect(face(tester), MascotState.thongTha);

    await tester.pumpWidget(host(BreathPhase.exhale, done: true));
    await tester.pump(const Duration(milliseconds: 400));
    expect(face(tester), MascotState.xong);
  });

  testWidgets('đang thở thì Nốt chuyển động liên tục', (tester) async {
    await tester.pumpWidget(host(BreathPhase.inhale));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('tắt chuyển động: không nhún, không hạt bay', (tester) async {
    await tester.pumpWidget(host(BreathPhase.inhale, noMotion: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('xong vòng thì Nốt dừng nhún', (tester) async {
    await tester.pumpWidget(host(BreathPhase.exhale, done: true));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
