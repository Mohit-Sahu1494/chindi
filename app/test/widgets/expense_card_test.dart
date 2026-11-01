import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab_app/core/theme/app_theme.dart';
import 'package:hisaab_app/core/widgets/expense_card.dart';
import 'package:hisaab_app/data/models/expense_model.dart';
import 'package:hisaab_app/data/models/user_model.dart';

void main() {
  testWidgets('ExpenseCard renders amount, description, payer, and share correctly', (tester) async {
    const ramesh = UserModel(id: 'u1', name: 'Ramesh Kumar', emailOrMobile: 'ramesh@hisaab.app');
    const suresh = UserModel(id: 'u2', name: 'Suresh Sharma', emailOrMobile: 'suresh@hisaab.app');
    const amit = UserModel(id: 'u3', name: 'Amit Verma', emailOrMobile: 'amit@hisaab.app');
    const priya = UserModel(id: 'u4', name: 'Priya Singh', emailOrMobile: 'priya@hisaab.app');

    // Ramesh paid ₹145 for Chai, Suresh and Amit are excluded -> Priya and Ramesh share
    final expense = ExpenseModel(
      id: 'exp1',
      group: 'grp1',
      cycle: 'cyc1',
      paidBy: ramesh,
      amountPaise: 14500, // ₹145
      description: 'Chai aur Samosa',
      excludedMembers: [suresh, amit],
      participants: [ramesh, priya],
      shares: [
        const ExpenseShareModel(user: ramesh, amountPaise: 7250),
        const ExpenseShareModel(user: priya, amountPaise: 7250),
      ],
      isDeleted: false,
      createdAt: DateTime(2026, 11, 1, 10, 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: ExpenseCard(
            expense: expense,
            currentUserId: 'u1', // Ramesh is viewing
          ),
        ),
      ),
    );

    // Verify amount is rendered
    expect(find.text('₹145.00'), findsOneWidget);

    // Verify description is rendered
    expect(find.text('Chai aur Samosa'), findsOneWidget);

    // Verify payer text says "Aap ne diya" because current user is Ramesh
    expect(find.text('Aap ne diya'), findsOneWidget);

    // Verify excluded members are shown
    expect(find.textContaining('Bahar: Suresh Sharma, Amit Verma'), findsOneWidget);

    // Verify individual share is displayed
    expect(find.textContaining('₹72.50 / vyakti'), findsOneWidget);
  });
}
