import 'package:flutter/material.dart';
import 'package:eme_app_package/l10n/app_localizations.dart';
import 'package:eme_app_package/models/daily_challenge.dart';
import 'package:eme_app_package/widgets/daily_challenge_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyChallenge and Mistakes Tests', () {
    test('DailyChallengeItem calculation and completion', () {
      final item = DailyChallengeItem(
        id: 'day-1',
        date: DateTime.now(),
        dayLabel: 'Mon',
        dateLabel: '8/25',
        title: 'Daily Practice',
        totalQuestions: 5,
        completedQuestions: 3,
      );

      expect(item.progress, 0.6);
      expect(item.isCompleted, false);

      item.complete();
      expect(item.completedQuestions, 5);
      expect(item.progress, 1.0);
      expect(item.isCompleted, true);
    });

    testWidgets('DailyChallengeSection renders today and past days correctly', (
      tester,
    ) async {
      final challenges = [
        DailyChallengeItem(
          id: 'past-1',
          date: DateTime.now().subtract(const Duration(days: 1)),
          dayLabel: 'Wed',
          dateLabel: '8/26',
          title: 'Sunday, August 24',
          totalQuestions: 20,
          completedQuestions: 5,
          isToday: false,
        ),
        DailyChallengeItem(
          id: 'today',
          date: DateTime.now(),
          dayLabel: 'Today',
          dateLabel: '8/27',
          title: 'Sunday, August 25',
          totalQuestions: 20,
          completedQuestions: 3,
          isToday: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: DailyChallengeSection(
                challenges: challenges,
                onChallengeCompleted: (item) {
                  item.complete();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DAILY CHALLENGE'), findsOneWidget);
      expect(find.text('Sunday, August 25'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
    });
  });
}
