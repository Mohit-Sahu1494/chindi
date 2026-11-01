import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab_app/core/theme/app_theme.dart';
import 'package:hisaab_app/core/widgets/chip_selector.dart';
import 'package:hisaab_app/data/models/user_model.dart';

void main() {
  testWidgets('ChipSelector renders member chips and toggles excluded members', (tester) async {
    const members = [
      UserModel(id: 'u1', name: 'Ramesh', emailOrMobile: 'ramesh@hisaab.app'),
      UserModel(id: 'u2', name: 'Suresh', emailOrMobile: 'suresh@hisaab.app'),
      UserModel(id: 'u3', name: 'Amit', emailOrMobile: 'amit@hisaab.app'),
    ];

    final excluded = <String>{'u2'};
    String? toggledMember;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SizedBox(
            width: 390, // 390px mobile phone width
            child: ChipSelector(
              members: members,
              excludedMemberIds: excluded,
              onToggleMember: (id) {
                toggledMember = id;
              },
              currentUserId: 'u1',
            ),
          ),
        ),
      ),
    );

    // Verify chips exist
    expect(find.text('Ramesh (Aap)'), findsOneWidget);
    expect(find.text('Suresh'), findsOneWidget);
    expect(find.text('Amit'), findsOneWidget);

    // Verify "1 bahar" badge
    expect(find.text('1 bahar'), findsOneWidget);

    // Tap Amit chip to toggle
    await tester.tap(find.byType(FilterChip).last, warnIfMissed: false);
    await tester.pump();

    expect(toggledMember, 'u3');
  });
}
