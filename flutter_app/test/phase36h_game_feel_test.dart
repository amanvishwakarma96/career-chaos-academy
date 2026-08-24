import 'package:career_chaos_academy/widgets/developer_game_feel_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 36H Developer game-feel policy', () {
    test('danger feedback is detected from live simulation language', () {
      expect(
        DeveloperGameFeelPolicy.toneFor(
          'CANARY FAILED. Rollback required before retry.',
        ),
        DeveloperGameFeedbackTone.danger,
      );
      expect(
        DeveloperGameFeelPolicy.toneFor('Approval blocked by staging gate.'),
        DeveloperGameFeedbackTone.danger,
      );
      expect(
        DeveloperGameFeelPolicy.toneFor('Time is up. Submit the current run.'),
        DeveloperGameFeedbackTone.danger,
      );
    });

    test('success feedback is detected without changing gameplay state', () {
      expect(
        DeveloperGameFeelPolicy.toneFor(
          'Release healthy. All six gates are green.',
        ),
        DeveloperGameFeedbackTone.success,
      );
      expect(
        DeveloperGameFeelPolicy.toneFor('Incident contained and stable.'),
        DeveloperGameFeedbackTone.success,
      );
    });

    test('ordinary instructions remain visually neutral', () {
      expect(
        DeveloperGameFeelPolicy.toneFor('Inspect logs before patching.'),
        DeveloperGameFeedbackTone.neutral,
      );
    });

    test('critical window ignores uninitialized zero timer', () {
      expect(DeveloperGameFeelPolicy.isCriticalWindow(0), isFalse);
      expect(DeveloperGameFeelPolicy.isCriticalWindow(16), isFalse);
      expect(DeveloperGameFeelPolicy.isCriticalWindow(15), isTrue);
      expect(DeveloperGameFeelPolicy.isCriticalWindow(1), isTrue);
    });
  });
}
