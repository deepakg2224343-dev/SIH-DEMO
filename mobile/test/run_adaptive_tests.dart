import 'package:smriti_setu/data/adaptive/adaptive_difficulty_engine.dart';
import 'package:smriti_setu/domain/services/adaptive_difficulty_service.dart';

void main() {
  print('=====================================================');
  print('Running SmritiSetu Adaptive Difficulty Test Suite');
  print('=====================================================');

  final engine = AdaptiveDifficultyEngine();
  int passed = 0;
  int failed = 0;

  void runTest(String name, void Function() testFn) {
    try {
      testFn();
      print(' [PASS] $name');
      passed++;
    } catch (e, st) {
      print(' [FAIL] $name');
      print('   Error: $e');
      print('   Stack: $st');
      failed++;
    }
  }

  runTest('Single high session without history maintains difficulty', () {
    final input = DifficultyEvaluationInput(
      currentDifficulty: 2,
      accuracyPercentage: 1.0,
      avgResponseTimeMs: 1500.0,
      totalHesitationMs: 500.0,
      errorCount: 0,
      historicalScores: [0.60],
    );
    final decision = engine.evaluateDifficulty(input);
    assert(!decision.isPromoted, 'Should not promote on single high session');
    assert(decision.nextDifficulty == 2, 'Difficulty should remain 2');
    assert(decision.reasonCode == 'MAINTAINED_STEADY_ZONE', 'Reason should be steady zone');
  });

  runTest('Consecutive high sessions promote difficulty gradually (+1)', () {
    final input = DifficultyEvaluationInput(
      currentDifficulty: 2,
      accuracyPercentage: 0.95,
      avgResponseTimeMs: 1600.0,
      totalHesitationMs: 600.0,
      errorCount: 0,
      historicalScores: [0.88],
    );
    final decision = engine.evaluateDifficulty(input);
    assert(decision.isPromoted, 'Should promote after consecutive high sessions');
    assert(decision.nextDifficulty == 3, 'Difficulty should increment to 3');
    assert(decision.reasonCode == 'PROMOTED_HIGH_PERFORMANCE', 'Reason code should match');
  });

  runTest('Single isolated mistake in good session does not demote', () {
    final input = DifficultyEvaluationInput(
      currentDifficulty: 3,
      accuracyPercentage: 0.80,
      avgResponseTimeMs: 2500.0,
      totalHesitationMs: 1200.0,
      errorCount: 1,
      historicalScores: [0.75],
    );
    final decision = engine.evaluateDifficulty(input);
    assert(!decision.isDemoted, 'Single mistake must not trigger demotion');
    assert(decision.nextDifficulty == 3, 'Difficulty must stay at 3');
  });

  runTest('Persistent struggle across consecutive sessions demotes (-1)', () {
    final input = DifficultyEvaluationInput(
      currentDifficulty: 3,
      accuracyPercentage: 0.40,
      avgResponseTimeMs: 7000.0,
      totalHesitationMs: 4500.0,
      errorCount: 3,
      historicalScores: [0.40],
    );
    final decision = engine.evaluateDifficulty(input);
    assert(decision.isDemoted, 'Should demote on persistent struggle');
    assert(decision.nextDifficulty == 2, 'Difficulty should decrement to 2');
    assert(decision.reasonCode == 'DEMOTED_REDUCE_FRUSTRATION');
  });

  runTest('Severe struggle in current session (< 0.30) demotes to relieve frustration', () {
    final input = DifficultyEvaluationInput(
      currentDifficulty: 2,
      accuracyPercentage: 0.20,
      avgResponseTimeMs: 8000.0,
      totalHesitationMs: 5000.0,
      errorCount: 4,
      historicalScores: [0.55],
    );
    final decision = engine.evaluateDifficulty(input);
    assert(decision.isDemoted, 'Should demote on severe current struggle');
    assert(decision.nextDifficulty == 1, 'Difficulty should reduce to 1');
  });

  runTest('Upper boundary is strictly clamped at Level 5', () {
    final input = DifficultyEvaluationInput(
      currentDifficulty: 5,
      accuracyPercentage: 1.0,
      avgResponseTimeMs: 1000.0,
      totalHesitationMs: 100.0,
      errorCount: 0,
      historicalScores: [0.95],
    );
    final decision = engine.evaluateDifficulty(input);
    assert(decision.nextDifficulty == 5, 'Should not exceed max level 5');
    assert(decision.reasonCode == 'MAINTAINED_AT_CEILING');
  });

  runTest('Lower boundary is strictly clamped at Level 1', () {
    final input = DifficultyEvaluationInput(
      currentDifficulty: 1,
      accuracyPercentage: 0.10,
      avgResponseTimeMs: 9000.0,
      totalHesitationMs: 6000.0,
      errorCount: 5,
      historicalScores: [0.20],
    );
    final decision = engine.evaluateDifficulty(input);
    assert(decision.nextDifficulty == 1, 'Should not decrease below min level 1');
    assert(decision.reasonCode == 'MAINTAINED_AT_FLOOR');
  });

  print('=====================================================');
  print('Result: $passed Passed, $failed Failed');
  print('=====================================================');

  if (failed > 0) {
    throw Exception('$failed tests failed!');
  }
}
