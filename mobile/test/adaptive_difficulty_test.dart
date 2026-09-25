import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_setu/data/adaptive/adaptive_difficulty_engine.dart';
import 'package:smriti_setu/domain/services/adaptive_difficulty_service.dart';

void main() {
  group('Phase 8: AdaptiveDifficultyEngine Core Logic Tests', () {
    late AdaptiveDifficultyEngine engine;

    setUp(() {
      engine = AdaptiveDifficultyEngine();
    });

    test('1. Promotion requires consecutive high scores and rolling performance >= 0.82', () {
      // Single high session without previous high history should NOT promote immediately
      final singleHighInput = DifficultyEvaluationInput(
        currentDifficulty: 2,
        accuracy: 1.0,
        averageResponseTime: 1500.0,
        hesitationTime: 500.0,
        errorCount: 0,
        recentSessionPerformance: [0.60], // previous moderate session
      );

      final decision1 = engine.evaluateDifficulty(singleHighInput);
      expect(decision1.isPromoted, isFalse);
      expect(decision1.nextDifficulty, equals(2));
      expect(decision1.reasonCode, equals('MAINTAINED_STEADY_ZONE'));
      expect(decision1.reason, contains('Maintain'));

      // Two consecutive high sessions SHOULD promote
      final consecutiveHighInput = DifficultyEvaluationInput(
        currentDifficulty: 2,
        accuracy: 0.95,
        averageResponseTime: 1600.0,
        hesitationTime: 600.0,
        errorCount: 0,
        recentSessionPerformance: [0.88], // previous high session
      );

      final decision2 = engine.evaluateDifficulty(consecutiveHighInput);
      expect(decision2.isPromoted, isTrue);
      expect(decision2.nextDifficulty, equals(3));
      expect(decision2.reasonCode, equals('PROMOTED_HIGH_PERFORMANCE'));
      expect(decision2.reason, equals('Increase from Level 2 → Level 3'));
    });

    test('2. Single mistake in an otherwise good session does not trigger demotion', () {
      final singleMistakeInput = DifficultyEvaluationInput(
        currentDifficulty: 3,
        accuracy: 0.80, // 4 out of 5 correct
        averageResponseTime: 2500.0,
        hesitationTime: 1200.0,
        errorCount: 1, // only 1 mistake
        recentSessionPerformance: [0.75],
      );

      final decision = engine.evaluateDifficulty(singleMistakeInput);
      expect(decision.isDemoted, isFalse);
      expect(decision.nextDifficulty, equals(3));
      expect(decision.reasonCode, equals('MAINTAINED_STEADY_ZONE'));
    });

    test('3. Persistent struggle across consecutive sessions demotes difficulty', () {
      final persistentStruggleInput = DifficultyEvaluationInput(
        currentDifficulty: 3,
        accuracy: 0.40,
        averageResponseTime: 7000.0,
        hesitationTime: 4500.0,
        errorCount: 3,
        recentSessionPerformance: [0.40], // previous poor session
      );

      final decision = engine.evaluateDifficulty(persistentStruggleInput);
      expect(decision.isDemoted, isTrue);
      expect(decision.nextDifficulty, equals(2));
      expect(decision.reasonCode, equals('DEMOTED_REDUCE_FRUSTRATION'));
      expect(decision.reason, contains('Reduce from Level 3 → Level 2'));
    });

    test('4. Severe struggle in current session (score < 0.30) demotes to relieve frustration', () {
      final severeStruggleInput = DifficultyEvaluationInput(
        currentDifficulty: 2,
        accuracy: 0.20,
        averageResponseTime: 8000.0,
        hesitationTime: 5000.0,
        errorCount: 4,
        recentSessionPerformance: [0.55],
      );

      final decision = engine.evaluateDifficulty(severeStruggleInput);
      expect(decision.isDemoted, isTrue);
      expect(decision.nextDifficulty, equals(1));
      expect(decision.reasonCode, equals('DEMOTED_REDUCE_FRUSTRATION'));
    });

    test('5. Difficulty is clamped between min level 1 and max level 5', () {
      // Test upper boundary at Level 5
      final maxLevelInput = DifficultyEvaluationInput(
        currentDifficulty: 5,
        accuracy: 1.0,
        averageResponseTime: 1000.0,
        hesitationTime: 100.0,
        errorCount: 0,
        recentSessionPerformance: [0.95],
      );

      final ceilingDecision = engine.evaluateDifficulty(maxLevelInput);
      expect(ceilingDecision.nextDifficulty, equals(5));
      expect(ceilingDecision.reasonCode, equals('MAINTAINED_AT_CEILING'));

      // Test lower boundary at Level 1
      final minLevelInput = DifficultyEvaluationInput(
        currentDifficulty: 1,
        accuracy: 0.10,
        averageResponseTime: 9000.0,
        hesitationTime: 6000.0,
        errorCount: 5,
        recentSessionPerformance: [0.20],
      );

      final floorDecision = engine.evaluateDifficulty(minLevelInput);
      expect(floorDecision.nextDifficulty, equals(1));
      expect(floorDecision.reasonCode, equals('MAINTAINED_AT_FLOOR'));
    });
  });

  group('Phase 8: Edge Cases, Boundaries, Zeroes & Extremes Tests', () {
    late AdaptiveDifficultyEngine engine;

    setUp(() {
      engine = AdaptiveDifficultyEngine();
    });

    test('6. Zero values: handles zero metrics without crash or NaN', () {
      const zeroInput = DifficultyEvaluationInput(
        currentDifficulty: 1,
        accuracy: 0.0,
        averageResponseTime: 0.0,
        hesitationTime: 0.0,
        errorCount: 0,
        recentSessionPerformance: [],
      );

      final decision = engine.evaluateDifficulty(zeroInput);
      expect(decision.nextDifficulty, equals(1));
      expect(decision.singleSessionScore.isNaN, isFalse);
      expect(decision.rollingPerformanceScore.isNaN, isFalse);
      expect(decision.confidence, greaterThan(0.0));
    });

    test('7. Extreme values: handles high response times and large error counts gracefully', () {
      const extremeInput = DifficultyEvaluationInput(
        currentDifficulty: 4,
        accuracy: 0.0,
        averageResponseTime: 60000.0, // 60 seconds
        hesitationTime: 45000.0,
        errorCount: 50,
        recentSessionPerformance: [0.10, 0.10],
      );

      final decision = engine.evaluateDifficulty(extremeInput);
      expect(decision.singleSessionScore, equals(0.0));
      expect(decision.rollingPerformanceScore, lessThan(0.10));
      expect(decision.nextDifficulty, equals(3)); // Demoted from 4 to 3
    });

    test('8. Missing metrics & Single session: cold start without historical scores', () {
      const coldStartInput = DifficultyEvaluationInput(
        currentDifficulty: 2,
        accuracy: 0.85,
        averageResponseTime: 2000.0,
        hesitationTime: 400.0,
        errorCount: 1,
        // recentSessionPerformance is omitted (empty)
      );

      final decision = engine.evaluateDifficulty(coldStartInput);
      expect(decision.rollingPerformanceScore, equals(decision.singleSessionScore));
      expect(decision.confidence, equals(0.55)); // Baseline confidence for 0 history
      expect(decision.nextDifficulty, equals(2)); // Maintained on cold start
    });

    test('9. Confidence increases with number of observed sessions', () {
      const input0History = DifficultyEvaluationInput(
        currentDifficulty: 2,
        accuracy: 0.80,
        recentSessionPerformance: [],
      );
      const input1History = DifficultyEvaluationInput(
        currentDifficulty: 2,
        accuracy: 0.80,
        recentSessionPerformance: [0.78],
      );
      const input2History = DifficultyEvaluationInput(
        currentDifficulty: 2,
        accuracy: 0.80,
        recentSessionPerformance: [0.75, 0.79],
      );
      const input3History = DifficultyEvaluationInput(
        currentDifficulty: 2,
        accuracy: 0.80,
        recentSessionPerformance: [0.75, 0.78, 0.80],
      );

      final d0 = engine.evaluateDifficulty(input0History);
      final d1 = engine.evaluateDifficulty(input1History);
      final d2 = engine.evaluateDifficulty(input2History);
      final d3 = engine.evaluateDifficulty(input3History);

      expect(d0.confidence, lessThan(d1.confidence));
      expect(d1.confidence, lessThan(d2.confidence));
      expect(d2.confidence, lessThan(d3.confidence));
      expect(d3.confidence, greaterThanOrEqualTo(0.90));
    });

    test('10. Difficulty configuration output produces valid parameters for levels 1 to 5', () {
      for (int lvl = 1; lvl <= 5; lvl++) {
        final config = engine.getDifficultyConfiguration(lvl);
        expect(config['level'], equals(lvl));
        expect(config['choicesCount'], greaterThanOrEqualTo(2));
        expect(config['sequenceLength'], greaterThanOrEqualTo(3));
        expect(config.containsKey('guidanceLevel'), isTrue);
        expect(config.containsKey('targetResponseSec'), isTrue);
      }
    });

    test('11. Determinism: identical inputs always yield identical decisions', () {
      const input = DifficultyEvaluationInput(
        currentDifficulty: 2,
        accuracy: 0.90,
        averageResponseTime: 1800.0,
        hesitationTime: 400.0,
        errorCount: 1,
        recentSessionPerformance: [0.85, 0.88],
      );

      final d1 = engine.evaluateDifficulty(input);
      final d2 = engine.evaluateDifficulty(input);
      final d3 = engine.evaluateDifficulty(input);

      expect(d1.nextDifficulty, equals(d2.nextDifficulty));
      expect(d2.nextDifficulty, equals(d3.nextDifficulty));
      expect(d1.singleSessionScore, equals(d2.singleSessionScore));
      expect(d1.rollingPerformanceScore, equals(d2.rollingPerformanceScore));
      expect(d1.confidence, equals(d2.confidence));
      expect(d1.reasonCode, equals(d2.reasonCode));
    });

    test('12. Out-of-bounds currentDifficulty input is safely clamped to 1..5', () {
      const negativeLevelInput = DifficultyEvaluationInput(
        currentDifficulty: -99,
        accuracy: 0.50,
      );
      final decisionNeg = engine.evaluateDifficulty(negativeLevelInput);
      expect(decisionNeg.previousDifficulty, equals(1));
      expect(decisionNeg.nextDifficulty, greaterThanOrEqualTo(1));

      const giantLevelInput = DifficultyEvaluationInput(
        currentDifficulty: 999,
        accuracy: 0.50,
      );
      final decisionGiant = engine.evaluateDifficulty(giantLevelInput);
      expect(decisionGiant.previousDifficulty, equals(5));
      expect(decisionGiant.nextDifficulty, lessThanOrEqualTo(5));
    });
  });
}
