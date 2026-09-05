import 'package:flutter/material.dart';
import 'package:eme_app_package/l10n/app_localizations.dart';
import 'package:eme_app_package/screens/daily_challenge_screen.dart';
import 'package:eme_app_package/widgets/daily_challenge_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyChallenge Tests', () {
    testWidgets('DailyChallengeSection renders simplified card correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: DailyChallengeSection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DAILY CHALLENGE'), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('DailyChallengeSection tap navigates to DailyChallengeScreen', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: DailyChallengeSection(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap card
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Expect DailyChallengeScreen to be pushed
      expect(find.byType(DailyChallengeScreen), findsOneWidget);
    });

    testWidgets('DailyChallengeScreen renders header with calendar icon', (
      tester,
    ) async {
      final challengeDate = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DailyChallengeScreen(challengeDate: challengeDate),
          ),
        ),
      );
      await tester.pump();

      // Verify header components
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
      expect(find.text('DAILY CHALLENGE'), findsOneWidget);
    });

    testWidgets('Tapping calendar icon opens calendar history sheet', (
      tester,
    ) async {
      final challengeDate = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DailyChallengeScreen(challengeDate: challengeDate),
          ),
        ),
      );
      await tester.pump();

      // Tap calendar icon
      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify calendar history sheet opened
      expect(find.text('Daily Challenge History'), findsOneWidget);
      expect(find.text('Previous Challenges'), findsOneWidget);
    });

    testWidgets(
      'DailyChallengeScreen renders no challenge message when activeChannel and currentchannel are not present',
      (tester) async {
        final challengeDate = DateTime(2026, 1, 1);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DailyChallengeScreen(challengeDate: challengeDate),
            ),
          ),
        );
        await tester.pump();

        // When no channel exists
        expect(find.byIcon(Icons.event_busy_rounded), findsOneWidget);
        expect(find.text('No Daily Challenge Available'), findsOneWidget);
        expect(
          find.text('There is no challenge available for this date.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('DailyChallengeScreen hides input when challenge is finished', (
      tester,
    ) async {
      final challengeDate = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DailyChallengeScreen(challengeDate: challengeDate),
          ),
        ),
      );
      await tester.pump();

      // Ensure follow-up TextField is not displayed when in finished/no-active state
      expect(find.byType(TextField), findsNothing);
    });
  });
}
