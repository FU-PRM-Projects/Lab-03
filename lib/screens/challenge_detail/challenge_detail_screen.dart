import 'package:material_ui/material_ui.dart';

import '../common/screen_skeleton.dart';

/// S08 · Chi tiết thử thách.
class ChallengeDetailScreen extends StatelessWidget {
  const ChallengeDetailScreen({required this.challengeId, super.key});

  final String challengeId;

  @override
  Widget build(BuildContext context) {
    return const NestedScaffold(
      title: 'Thử thách',
      body: ScreenSkeleton(code: 'S08', name: 'Chi tiết thử thách'),
    );
  }
}
