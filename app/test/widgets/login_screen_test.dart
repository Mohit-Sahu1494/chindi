import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisaab_app/features/auth/login_screen.dart';

void main() {
  testWidgets('LoginScreen inputs are responsive, validate properly, and allow typing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify logo and title exist
    expect(find.text('CHINDI'), findsOneWidget);
    expect(find.text('CHINDI MEIN LOGIN KAREIN'), findsOneWidget);

    // Verify two TextFormFields exist
    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    // Tap login while empty to trigger form validation
    final loginButton = find.text('CHINDI MEIN LOGIN KAREIN');
    await tester.tap(loginButton);
    await tester.pump();

    // Form validation messages should appear
    expect(find.text('Kripya email darj karein'), findsOneWidget);
    expect(find.text('Kripya password darj karein'), findsOneWidget);
    expect(find.text('Password bhool gaye?'), findsOneWidget);

    // Enter email
    await tester.enterText(textFields.first, 'ramesh@hisaab.app');
    await tester.pump();
    expect(find.text('ramesh@hisaab.app'), findsOneWidget);

    // Enter password
    await tester.enterText(textFields.last, 'secret123');
    await tester.pump();
    expect(find.text('secret123'), findsOneWidget);

    // Password visibility toggle test
    final visibilityIcon = find.byIcon(Icons.visibility_outlined);
    expect(visibilityIcon, findsOneWidget);
    await tester.tap(visibilityIcon);
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    // Re-tap visibility toggle
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    // Screen remains stable and completely interactive
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
