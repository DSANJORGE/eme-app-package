import 'package:flutter/material.dart';
import 'package:eme_app_package/l10n/app_localizations.dart';
import 'package:eme_app_package/models/daily_challenge.dart';
import 'package:eme_app_package/models/mistake_item.dart';
import 'package:eme_app_package/widgets/daily_challenge_section.dart';
import 'package:eme_app_package/widgets/mistakes_section.dart';
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

    test('MistakeItem state management', () {
      final mistake = MistakeItem(
        id: 'm1',
        topicTitle: 'Math',
        question: '2 + 2 = ?',
        options: ['3', '4', '5'],
        correctOptionIndex: 1,
        explanation: '2 + 2 equals 4',
      );

      expect(mistake.isResolved, false);
      final resolved = mistake.copyWith(isResolved: true);
      expect(resolved.isResolved, true);
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

    testWidgets(
      'MistakesSection renders unresolved mistakes and allows practice',
      (tester) async {
        final mistakes = [
          MistakeItem(
            id: 'm1',
            topicTitle: 'Physics',
            question: 'What is unit of Force?',
            options: ['Newton', 'Joule', 'Watt'],
            correctOptionIndex: 0,
            explanation: 'Force is measured in Newtons (N).',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: MistakesSection(
                  mistakes: mistakes,
                  onMistakeResolved: (m) => m.isResolved = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('MISTAKES'), findsOneWidget);
        expect(find.text('Redo Mistakes'), findsOneWidget);
        expect(find.text('1 to redo'), findsOneWidget);
      },
    );
  });
}
