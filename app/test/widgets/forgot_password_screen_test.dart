import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisaab_app/features/auth/forgot_password_screen.dart';

void main() {
  testWidgets('ForgotPasswordScreen shows email input, validates email format and empty field', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title and label
    expect(find.text('FORGOT PASSWORD'), findsOneWidget);
    expect(find.text('Password Reset Karein'), findsOneWidget);
    expect(find.text('REGISTERED EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('OTP BHEJEIN (SEND OTP)'), findsOneWidget);

    // Tap OTP BHEJEIN while empty
    await tester.tap(find.text('OTP BHEJEIN (SEND OTP)'));
    await tester.pump();
    expect(find.text('Kripya email address darj karein'), findsOneWidget);

    // Enter invalid email
    final emailField = find.byType(TextFormField);
    await tester.enterText(emailField, 'notanemail');
    await tester.tap(find.text('OTP BHEJEIN (SEND OTP)'));
    await tester.pump();
    expect(find.text('Kripya ek maanya email address darj karein (e.g. name@gmail.com)'), findsOneWidget);

    // Enter valid email
    await tester.enterText(emailField, 'user@example.com');
    await tester.pump();
    expect(find.text('user@example.com'), findsOneWidget);
  });
}
