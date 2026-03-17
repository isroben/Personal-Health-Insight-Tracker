import 'package:flutter_test/flutter_test.dart';
import 'package:health_insight_tracker/utils/math_utils.dart';

void main() {
  group('MathUtils.pearsonCorrelation Tests', () {
    test('Perfect positive correlation (1.0)', () {
      final x = [1, 2, 3, 4, 5];
      final y = [2, 4, 6, 8, 10];
      final r = MathUtils.pearsonCorrelation(x, y);
      expect(r, closeTo(1.0, 0.0001));
    });

    test('Perfect negative correlation (-1.0)', () {
      final x = [1, 2, 3, 4, 5];
      final y = [10, 8, 6, 4, 2];
      final r = MathUtils.pearsonCorrelation(x, y);
      expect(r, closeTo(-1.0, 0.0001));
    });

    test('No correlation (0.0)', () {
      final x = [1, 2, 3, 4, 5];
      final y = [1, 0, 1, 0, 1]; // Fluctuating
      final r = MathUtils.pearsonCorrelation(x, y);
      // Small datasets might not be exactly zero, but should be low
      expect(r.abs(), lessThan(0.5));
    });

    test('Zero variance should return 0 (avoid div by zero)', () {
      final x = [1, 1, 1, 1, 1];
      final y = [1, 2, 3, 4, 5];
      final r = MathUtils.pearsonCorrelation(x, y);
      expect(r, 0.0);
    });

    test('Mismatched lengths should return 0', () {
      final x = [1, 2];
      final y = [1, 2, 3];
      final r = MathUtils.pearsonCorrelation(x, y);
      expect(r, 0.0);
    });

    test('Empty lists should return 0', () {
      final r = MathUtils.pearsonCorrelation([], []);
      expect(r, 0.0);
    });
  });
}
