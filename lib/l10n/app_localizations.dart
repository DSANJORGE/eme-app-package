import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @catalogDashboard.
  ///
  /// In en, this message translates to:
  /// **'Catalog / Dashboard'**
  String get catalogDashboard;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profile;

  /// No description provided for @overallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get overallProgress;

  /// No description provided for @overallPerformance.
  ///
  /// In en, this message translates to:
  /// **'Overall Performance'**
  String get overallPerformance;

  /// No description provided for @topics.
  ///
  /// In en, this message translates to:
  /// **'TOPICS'**
  String get topics;

  /// No description provided for @workspace.
  ///
  /// In en, this message translates to:
  /// **'WORKSPACE'**
  String get workspace;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'LOGOUT'**
  String get logout;

  /// No description provided for @poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by eMe.world'**
  String get poweredBy;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @newTutorials.
  ///
  /// In en, this message translates to:
  /// **'3 New'**
  String get newTutorials;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level 10'**
  String get level;

  /// No description provided for @avgSuffix.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get avgSuffix;

  /// No description provided for @newTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'New Tutorial Available'**
  String get newTutorialTitle;

  /// No description provided for @newTutorialBody.
  ///
  /// In en, this message translates to:
  /// **'Mathematical Competence 2 has been unlocked.'**
  String get newTutorialBody;

  /// No description provided for @achievementTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked'**
  String get achievementTitle;

  /// No description provided for @achievementBody.
  ///
  /// In en, this message translates to:
  /// **'You completed 3 subject diagnostic tests.'**
  String get achievementBody;

  /// No description provided for @time5m.
  ///
  /// In en, this message translates to:
  /// **'5m ago'**
  String get time5m;

  /// No description provided for @time2h.
  ///
  /// In en, this message translates to:
  /// **'2h ago'**
  String get time2h;

  /// No description provided for @tutorialsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tutorials'**
  String tutorialsCount(String count);

  /// No description provided for @daysToGo.
  ///
  /// In en, this message translates to:
  /// **'days to go'**
  String get daysToGo;

  /// No description provided for @efficiency.
  ///
  /// In en, this message translates to:
  /// **'efficiency'**
  String get efficiency;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String lastUpdated(String date);

  /// No description provided for @tutorials.
  ///
  /// In en, this message translates to:
  /// **'Tutorials'**
  String get tutorials;

  /// No description provided for @totalTutorials.
  ///
  /// In en, this message translates to:
  /// **'TOTAL TUTORIALS'**
  String get totalTutorials;

  /// No description provided for @activeTutorials.
  ///
  /// In en, this message translates to:
  /// **'{count} Active Tutorials'**
  String activeTutorials(String count);

  /// No description provided for @testsPerformance.
  ///
  /// In en, this message translates to:
  /// **'TESTS PERFORMANCE'**
  String get testsPerformance;

  /// No description provided for @averageScore.
  ///
  /// In en, this message translates to:
  /// **'{progress}% Average Score'**
  String averageScore(String progress);

  /// No description provided for @overallTopicProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall Topic Progress'**
  String get overallTopicProgress;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Finished'**
  String finished(String percent);

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @competent.
  ///
  /// In en, this message translates to:
  /// **'Competent'**
  String get competent;

  /// No description provided for @expert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get expert;

  /// No description provided for @topicsYouExcelAt.
  ///
  /// In en, this message translates to:
  /// **'Topics you excel at'**
  String get topicsYouExcelAt;

  /// No description provided for @averageRank.
  ///
  /// In en, this message translates to:
  /// **'Average Rank'**
  String get averageRank;

  /// No description provided for @nextRankUp.
  ///
  /// In en, this message translates to:
  /// **'Average Score'**
  String get nextRankUp;

  /// No description provided for @improve.
  ///
  /// In en, this message translates to:
  /// **'Improve'**
  String get improve;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @lastReviewed.
  ///
  /// In en, this message translates to:
  /// **'Last reviewed {d} days ago'**
  String lastReviewed(String d);

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @appCompliance.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get appCompliance;

  /// No description provided for @dataConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Collection Disclosure & Consent'**
  String get dataConsentTitle;

  /// No description provided for @dataConsentBody.
  ///
  /// In en, this message translates to:
  /// **'We value your privacy. We collect account details (email, name), chat interactions, and learning progress to provide personalized AI tutoring. All data is transmitted securely over HTTPS and stored safely. We do not sell your personal data.'**
  String get dataConsentBody;

  /// No description provided for @acceptConsent.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptConsent;

  /// No description provided for @declineConsent.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineConsent;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action is permanent and will erase your credentials, history, and profile data.'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteData.
  ///
  /// In en, this message translates to:
  /// **'Delete Collected Data'**
  String get deleteData;

  /// No description provided for @deleteDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all collected learning and chat data? This cannot be undone.'**
  String get deleteDataConfirm;

  /// No description provided for @aiGenerated.
  ///
  /// In en, this message translates to:
  /// **'AI Generated'**
  String get aiGenerated;

  /// No description provided for @reportAi.
  ///
  /// In en, this message translates to:
  /// **'Report AI Response'**
  String get reportAi;

  /// No description provided for @reportAiSuccess.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your report has been submitted for review.'**
  String get reportAiSuccess;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @reasonHallucination.
  ///
  /// In en, this message translates to:
  /// **'Hallucination / Inaccurate Information'**
  String get reasonHallucination;

  /// No description provided for @reasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate Content'**
  String get reasonInappropriate;

  /// No description provided for @reasonOffensive.
  ///
  /// In en, this message translates to:
  /// **'Offensive Language'**
  String get reasonOffensive;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other Issue'**
  String get reasonOther;

  /// No description provided for @accountManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Account & Data Management'**
  String get accountManagementTitle;

  /// No description provided for @accountManagementBody.
  ///
  /// In en, this message translates to:
  /// **'You have full control over your data. You can erase your collected data or permanently delete your account at any time.'**
  String get accountManagementBody;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
