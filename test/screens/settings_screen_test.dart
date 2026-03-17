import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_insight_tracker/screens/settings_screen.dart';
import 'package:health_insight_tracker/providers/auth_provider.dart';
import 'package:health_insight_tracker/models/user_model.dart';
import 'dart:async';

void main() {
  testWidgets('SettingsScreen displays user info and Premium banner when free', (tester) async {
    final mockUser = UserModel(
      id: '1',
      name: 'Test Pilot',
      email: 'pilot@test.com',
      subscription: SubscriptionTier.free,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(mockUser)),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Name & Email
    expect(find.text('Test Pilot'), findsOneWidget);
    expect(find.text('pilot@test.com'), findsOneWidget);

    // Verify Premium Banner existence (upsell)
    expect(find.text('Upgrade to Premium'), findsOneWidget);
    expect(find.text('Upgrade'), findsOneWidget);
  });

  testWidgets('SettingsScreen shows PREMIUM badge when user is premium', (tester) async {
    final mockUser = UserModel(
      id: '1',
      name: 'Gold User',
      email: 'gold@test.com',
      subscription: SubscriptionTier.premium,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(mockUser)),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Premium Badge text
    expect(find.text('PREMIUM'), findsOneWidget);
    
    // Verify Premium Banner (Upsell) is NOT shown
    expect(find.text('Upgrade to Premium'), findsNothing);
  });
}
