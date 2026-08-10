// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get catalogDashboard => 'Catalog / Dashboard';

  @override
  String get profile => 'PROFILE';

  @override
  String get overallProgress => 'Overall Progress';

  @override
  String get overallPerformance => 'Overall Performance';

  @override
  String get topics => 'TOPICS';

  @override
  String get workspace => 'WORKSPACE';

  @override
  String get language => 'LANGUAGE';

  @override
  String get logout => 'LOGOUT';

  @override
  String get poweredBy => 'Powered by eMe.world';

  @override
  String get notifications => 'Notifications';

  @override
  String get newTutorials => '3 New';

  @override
  String get level => 'Level 10';

  @override
  String get avgSuffix => 'Avg';

  @override
  String get newTutorialTitle => 'New Tutorial Available';

  @override
  String get newTutorialBody => 'Mathematical Competence 2 has been unlocked.';

  @override
  String get achievementTitle => 'Achievement Unlocked';

  @override
  String get achievementBody => 'You completed 3 subject diagnostic tests.';

  @override
  String get time5m => '5m ago';

  @override
  String get time2h => '2h ago';

  @override
  String tutorialsCount(String count) {
    return '$count tutorials';
  }

  @override
  String get daysToGo => 'days to go';

  @override
  String get efficiency => 'efficiency';

  @override
  String get moderate => 'Moderate';

  @override
  String lastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get tutorials => 'Tutorials';

  @override
  String get totalTutorials => 'TOTAL TUTORIALS';

  @override
  String activeTutorials(String count) {
    return '$count Active Tutorials';
  }

  @override
  String get testsPerformance => 'TESTS PERFORMANCE';

  @override
  String averageScore(String progress) {
    return '$progress% Average Score';
  }

  @override
  String get overallTopicProgress => 'Overall Topic Progress';

  @override
  String finished(String percent) {
    return '$percent% Finished';
  }

  @override
  String get beginner => 'Beginner';

  @override
  String get competent => 'Competent';

  @override
  String get expert => 'Expert';

  @override
  String get topicsYouExcelAt => 'Topics you excel at';

  @override
  String get averageRank => 'Average Rank';

  @override
  String get nextRankUp => 'Average Score';

  @override
  String get improve => 'Improve';

  @override
  String get refresh => 'Refresh';

  @override
  String lastReviewed(String d) {
    return 'Last reviewed $d days ago';
  }

  @override
  String get confidence => 'Confidence';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get appCompliance => 'Privacy & Data';

  @override
  String get dataConsentTitle => 'Data Collection Disclosure & Consent';

  @override
  String get dataConsentBody => 'We value your privacy. We collect account details (email, name), chat interactions, and learning progress to provide personalized AI tutoring. All data is transmitted securely over HTTPS and stored safely. We do not sell your personal data.';

  @override
  String get acceptConsent => 'Accept';

  @override
  String get declineConsent => 'Decline';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirm => 'Are you sure you want to delete your account? This action is permanent and will erase your credentials, history, and profile data.';

  @override
  String get deleteData => 'Delete Collected Data';

  @override
  String get deleteDataConfirm => 'Are you sure you want to delete all collected learning and chat data? This cannot be undone.';

  @override
  String get aiGenerated => 'AI Generated';

  @override
  String get reportAi => 'Report AI Response';

  @override
  String get reportAiSuccess => 'Thank you! Your report has been submitted for review.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get reasonHallucination => 'Hallucination / Inaccurate Information';

  @override
  String get reasonInappropriate => 'Inappropriate Content';

  @override
  String get reasonOffensive => 'Offensive Language';

  @override
  String get reasonOther => 'Other Issue';

  @override
  String get accountManagementTitle => 'Account & Data Management';

  @override
  String get accountManagementBody => 'You have full control over your data. You can erase your collected data or permanently delete your account at any time.';
}
