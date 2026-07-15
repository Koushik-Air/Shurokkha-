import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shurokkha/features/auth/domain/user_model.dart';
import 'package:shurokkha/features/contacts/domain/contact_model.dart';
import 'package:shurokkha/features/disguise/presentation/calculator_disguise_screen.dart';
import 'package:shurokkha/core/localization/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('Domain Models Unit Tests', () {
    test('UserModel map conversion', () {
      final user = UserModel(
        uid: 'user123',
        email: 'test@shurokkha.com',
        phoneNumber: '01700000000',
        displayName: 'Test User',
      );

      final map = user.toMap();
      expect(map['uid'], 'user123');
      expect(map['email'], 'test@shurokkha.com');

      final fromMap = UserModel.fromMap(map);
      expect(fromMap.displayName, 'Test User');
    });

    test('EmergencyContact map conversion', () {
      final contact = EmergencyContact(
        id: 'contact1',
        name: 'Father',
        relationship: 'Father',
        phoneNumber: '01800000000',
        email: 'father@gmail.com',
      );

      final map = contact.toMap();
      expect(map['id'], 'contact1');
      expect(map['relationship'], 'Father');

      final fromMap = EmergencyContact.fromMap(map);
      expect(fromMap.phoneNumber, '01800000000');
    });
  });

  group('Calculator Disguise Widget Tests', () {
    testWidgets('Unlocks secure content on secret code 9876=', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const CalculatorDisguiseScreen(
            child: Text('SECURE_DASHBOARD'),
          ),
        ),
      );

      // Verify calculator is shown, and secure dashboard is hidden
      expect(find.text('SECURE_DASHBOARD'), findsNothing);
      expect(find.text('C'), findsOneWidget);

      // Type secret code 9876 and press =
      await tester.tap(find.text('9'));
      await tester.pump();
      await tester.tap(find.text('8'));
      await tester.pump();
      await tester.tap(find.text('7'));
      await tester.pump();
      await tester.tap(find.text('6'));
      await tester.pump();
      await tester.tap(find.text('='));
      await tester.pump();

      // Verify dashboard is now unlocked and visible
      expect(find.text('SECURE_DASHBOARD'), findsOneWidget);
    });
  });
}
