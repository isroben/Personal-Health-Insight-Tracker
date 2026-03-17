/// ==========================================================================
/// lifestyle_provider.dart — Lifestyle Entry State Provider (Riverpod)
/// ==========================================================================
/// Manages the list of lifestyle entries for the current user.
/// Provides:
/// - Fetching lifestyle entries from Firestore
/// - Adding/updating a lifestyle entry (one per day)
///
/// Depends on: DatabaseService
/// ==========================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lifestyle_entry.dart';
import '../services/database_service.dart';
import 'symptom_provider.dart'; // re-use databaseServiceProvider

/// Provides the list of lifestyle entries for the current user.
final lifestyleEntriesProvider = StateNotifierProvider<
    LifestyleEntriesNotifier, AsyncValue<List<LifestyleEntry>>>((ref) {
  return LifestyleEntriesNotifier(ref.read(databaseServiceProvider));
});

class LifestyleEntriesNotifier
    extends StateNotifier<AsyncValue<List<LifestyleEntry>>> {
  final DatabaseService _db;

  LifestyleEntriesNotifier(this._db) : super(const AsyncLoading());

  /// Fetches all lifestyle entries for the given user.
  Future<void> fetchEntries(String userId) async {
    state = const AsyncLoading();
    try {
      final entries = await _db.getLifestyleEntries(userId);
      state = AsyncData(entries);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Adds or updates a lifestyle entry and refreshes the list.
  Future<void> addEntry(LifestyleEntry entry) async {
    try {
      await _db.addLifestyleEntry(entry);
      state.whenData((entries) {
        // Replace existing entry for the same day, or add new
        final updated = entries
            .where((e) =>
                e.date.year != entry.date.year ||
                e.date.month != entry.date.month ||
                e.date.day != entry.date.day)
            .toList();
        state = AsyncData([entry, ...updated]);
      });
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
