import 'dart:math' as math;

/// ==========================================================================
/// math_utils.dart — Statistical Analysis Utilities
/// ==========================================================================
/// Provides pure mathematical functions for data correlation.
/// Used by AIInsightService to perform baseline statistical analysis
/// before passing refined data to the LLM.
/// ==========================================================================

class MathUtils {
  /// Computes the Pearson Correlation Coefficient (r) between two datasets.
  /// 
  /// Result is between -1.0 and 1.0:
  ///   - 1.0: Perfect positive correlation
  ///   - 0.0: No correlation
  ///   - -1.0: Perfect negative correlation
  ///
  /// Requirements: Both lists must have equal length.
  static double pearsonCorrelation(List<num> x, List<num> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;

    int n = x.length;
    num sumX = 0, sumY = 0, sumXY = 0;
    num sumX2 = 0, sumY2 = 0;

    for (int i = 0; i < n; i++) {
      sumX += x[i];
      sumY += y[i];
      sumXY += x[i] * y[i];
      sumX2 += x[i] * x[i];
      sumY2 += y[i] * y[i];
    }

    num numerator = (n * sumXY) - (sumX * sumY);
    num denominator = math.sqrt(
      ((n * sumX2) - (sumX * sumX)) * ((n * sumY2) - (sumY * sumY)),
    );

    if (denominator == 0) return 0.0;
    return numerator / denominator;
  }
}
