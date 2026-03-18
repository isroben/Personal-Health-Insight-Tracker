import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the current index of the bottom navigation bar.
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
