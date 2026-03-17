import 'package:flutter_test/flutter_test.dart';
import 'package:health_insight_tracker/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('Should create UserModel from Map', () {
      final map = {
        'id': 'user_123',
        'name': 'Test User',
        'email': 'test@example.com',
        'subscription': 'premium',
        'createdAt': '2024-03-14T12:00:00Z',
        'updatedAt': '2024-03-14T12:30:00Z',
      };

      final user = UserModel.fromMap(map);

      expect(user.id, 'user_123');
      expect(user.subscription, SubscriptionTier.premium);
      expect(user.name, 'Test User');
    });

    test('Should convert UserModel to Map (ISO strings)', () {
      final user = UserModel(
        id: 'user_456',
        name: 'Jane Doe',
        email: 'jane@example.com',
        subscription: SubscriptionTier.free,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final map = user.toMap();

      expect(map['id'], 'user_456');
      expect(map['subscription'], 'free');
      expect(map['createdAt'], isA<String>());
    });

    test('copyWith should only update specified fields', () {
      final user = UserModel(
        id: '1',
        name: 'Original',
        email: 'orig@email.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = user.copyWith(name: 'Updated');

      expect(updated.name, 'Updated');
      expect(updated.id, '1');
      expect(updated.email, 'orig@email.com');
    });
   group('Date Parsing Helper', () {
      test('Should parse ISO 8601 string', () {
        // Since _parseDate is private, we test it through fromMap
        final map = {
          'id': '1', 'name': 'N', 'email': 'E',
          'createdAt': '2024-05-20T10:00:00Z',
          'updatedAt': '2024-05-20T10:00:00Z',
        };
        final user = UserModel.fromMap(map);
        expect(user.createdAt.year, 2024);
      });
    });
  });
}
