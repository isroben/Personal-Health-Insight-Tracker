import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gamification_service.dart';

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService();
});

final wellnessScoreProvider = FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.calculateWellnessScore(userId);
});

final streakProvider = FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.calculateCurrentStreak(userId);
});
