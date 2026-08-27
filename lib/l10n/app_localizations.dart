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

  /// Toast message when OTP code is sent to user email
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to your email!'**
  String get verificationCodeSent;

  /// Toast message when OTP code is resent
  ///
  /// In en, this message translates to:
  /// **'Verification code resent to your email!'**
  String get verificationCodeResent;

  /// Error message shown when email is not found in system
  ///
  /// In en, this message translates to:
  /// **'User does not exist.'**
  String get userDoesNotExist;

  /// Error message when sending verification code fails
  ///
  /// In en, this message translates to:
  /// **'Failed to send code'**
  String get failedToSendCode;

  /// Validation error for OTP length
  ///
  /// In en, this message translates to:
  /// **'Please enter all 6 digits'**
  String get pleaseEnterAll6Digits;

  /// Error when OTP code is incorrect
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code. Please try again.'**
  String get invalidVerificationCode;

  /// Title for account registration form
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Button to go back and edit the entered email address
  ///
  /// In en, this message translates to:
  /// **'Edit Email'**
  String get editEmail;

  /// Instructional message when user account is not found
  ///
  /// In en, this message translates to:
  /// **'No account found for {email}. Please enter your details to register.'**
  String noAccountFoundRegister(String email);

  /// Label for first name input field
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// Placeholder hint for first name
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get enterFirstName;

  /// Validation error when first name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get pleaseEnterFirstName;

  /// Label for last name input field
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// Placeholder hint for last name
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get enterLastName;

  /// Validation error when last name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get pleaseEnterLastName;

  /// Label for email address field
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// Placeholder hint for email input
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Validation error when email is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// Validation error when email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// Label for OTP input section
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// Subheading showing which email address received the code
  ///
  /// In en, this message translates to:
  /// **'Sent to {email}'**
  String sentToEmail(String email);

  /// Label displaying currently selected workspace
  ///
  /// In en, this message translates to:
  /// **'Workspace: {name}'**
  String workspacePrefix(String name);

  /// Timer label counting down until OTP resend is allowed
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(String seconds);

  /// Prompt asking user if OTP was received
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? '**
  String get didntReceiveCode;

  /// Button to request a new OTP code
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// Button action to register and send OTP
  ///
  /// In en, this message translates to:
  /// **'Register & Send Code'**
  String get registerAndSendCode;

  /// Button action to submit OTP and login
  ///
  /// In en, this message translates to:
  /// **'Verify & Sign In'**
  String get verifyAndSignIn;

  /// Button action to request initial OTP
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendVerificationCode;

  /// Title for workspace selector dialog/screen
  ///
  /// In en, this message translates to:
  /// **'Select Workspace'**
  String get selectWorkspace;

  /// Toast confirming workspace removal
  ///
  /// In en, this message translates to:
  /// **'Workspace removed'**
  String get workspaceRemoved;

  /// Error message when workspace removal fails
  ///
  /// In en, this message translates to:
  /// **'Failed to remove workspace'**
  String get failedToRemoveWorkspace;

  /// Title of delete workspace confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Workspace'**
  String get deleteWorkspace;

  /// Confirmation prompt before deleting a workspace
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete workspace \"{name}\" ({root})?'**
  String deleteWorkspaceConfirm(String name, String root);

  /// Delete action button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Toast message when user accepts data collection
  ///
  /// In en, this message translates to:
  /// **'Data collection consent updated to Accepted.'**
  String get consentUpdatedAccepted;

  /// Toast message when user limits data collection to essentials
  ///
  /// In en, this message translates to:
  /// **'Data collection consent updated to Essential-only.'**
  String get consentUpdatedEssential;

  /// Error message when updating consent setting fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update consent preference'**
  String get failedToUpdateConsent;

  /// Confirmation toast after requesting personal data deletion
  ///
  /// In en, this message translates to:
  /// **'Personal collected data deletion has been requested.'**
  String get dataDeletionRequested;

  /// Error message when requesting data deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to request data deletion'**
  String get failedToRequestDataDeletion;

  /// Section title in compliance screen
  ///
  /// In en, this message translates to:
  /// **'Data Collection Consent Status'**
  String get dataCollectionConsentStatus;

  /// Disclosure category title for account info
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInfoTitle;

  /// Disclosure description for account info
  ///
  /// In en, this message translates to:
  /// **'Name, email address, and authentication credentials.'**
  String get accountInfoSubtitle;

  /// Disclosure category title for chat and learning data
  ///
  /// In en, this message translates to:
  /// **'Interactive Chat & Learning Data'**
  String get interactiveChatLearningTitle;

  /// Disclosure description for chat and learning data
  ///
  /// In en, this message translates to:
  /// **'Prompts, responses, diagnostic test scores & progress.'**
  String get interactiveChatLearningSubtitle;

  /// Disclosure category title for security and encryption
  ///
  /// In en, this message translates to:
  /// **'Data Protection & Encryption'**
  String get dataProtectionTitle;

  /// Disclosure description for security and encryption
  ///
  /// In en, this message translates to:
  /// **'HTTPS transmission and secure cloud storage.'**
  String get dataProtectionSubtitle;

  /// Error message when topics cannot be fetched
  ///
  /// In en, this message translates to:
  /// **'Failed to load topics: {error}'**
  String failedToLoadTopics(String error);

  /// Button label to retry an operation
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Empty state text when no topics are available
  ///
  /// In en, this message translates to:
  /// **'No topics available.'**
  String get noTopicsAvailable;

  /// Tooltip or link to open user profile
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// Tab or menu label for catalog section
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalog;

  /// Error when a web link cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open link: {url}'**
  String couldNotOpenLink(String url);

  /// Error message when tutorials fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load tutorials: {error}'**
  String failedToLoadTutorials(String error);

  /// Empty state text when no tutorials are present
  ///
  /// In en, this message translates to:
  /// **'No tutorials available.'**
  String get noTutorialsAvailable;

  /// Error message when image picker fails
  ///
  /// In en, this message translates to:
  /// **'Failed to select image'**
  String get failedToSelectImage;

  /// Success toast after saving profile changes
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// Error message when profile save fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// Title of the edit profile screen/action
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Label for email field in profile screen
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Button label to commit edits
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Validation error template for mandatory fields
  ///
  /// In en, this message translates to:
  /// **'{label} is required'**
  String fieldIsRequired(String label);

  /// Toast after user data is cleared
  ///
  /// In en, this message translates to:
  /// **'Account data cleared successfully.'**
  String get accountDataCleared;

  /// Error message when clearing user data fails
  ///
  /// In en, this message translates to:
  /// **'Failed to clear account data'**
  String get failedToClearAccountData;

  /// Badge showing count of remaining items
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String plusMoreCount(String count);

  /// User skill rank level
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// Error message when starting a tutorial session fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load tutorial session'**
  String get failedToLoadTutorialSession;

  /// Error message when submitting an answer fails
  ///
  /// In en, this message translates to:
  /// **'Failed to submit answer'**
  String get failedToSubmitAnswer;

  /// Error message when sending a follow up question fails
  ///
  /// In en, this message translates to:
  /// **'Failed to send follow up'**
  String get failedToSendFollowUp;

  /// Error message when advancing tutorial fails
  ///
  /// In en, this message translates to:
  /// **'Failed to continue tutorial'**
  String get failedToContinueTutorial;

  /// Header description in AI response report dialog
  ///
  /// In en, this message translates to:
  /// **'Report hallucination, inaccurate information, or inappropriate AI response:'**
  String get reportDetailsPrompt;

  /// Hint text for additional comments in report dialog
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)...'**
  String get additionalDetailsOptional;

  /// Button label to submit a report
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// Feedback shown when answer is correct
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correct;

  /// Feedback shown when answer is incorrect
  ///
  /// In en, this message translates to:
  /// **'Incorrect.'**
  String get incorrect;

  /// Error message shown when tutor chat fails to load
  ///
  /// In en, this message translates to:
  /// **'An error occured while loading the chat.'**
  String get errorLoadingChat;

  /// Button label to retry loading chat or session
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Button label to start a tutorial
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Hint text in chat input field
  ///
  /// In en, this message translates to:
  /// **'Ask a follow-up question...'**
  String get askFollowUpHint;

  /// Button label to send chat message
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Button label to continue tutorial
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Prompt header for confidence rating
  ///
  /// In en, this message translates to:
  /// **'HOW CONFIDENT ARE YOU IN THIS ANSWER?'**
  String get howConfidentQuestion;

  /// Button label to submit quiz answer
  ///
  /// In en, this message translates to:
  /// **'Submit Answer'**
  String get submitAnswer;

  /// Status banner while WebSocket / tutor session connects
  ///
  /// In en, this message translates to:
  /// **'Connecting to tutor session...'**
  String get connectingToTutorSession;

  /// Header celebration text when quiz is completed
  ///
  /// In en, this message translates to:
  /// **'Quiz Completed! 🎉'**
  String get quizCompleted;

  /// Button label to exit quiz and go back to topics
  ///
  /// In en, this message translates to:
  /// **'Go Back!'**
  String get goBack;

  /// Error state when image fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// Button to open asset in external browser
  ///
  /// In en, this message translates to:
  /// **'Open in Browser'**
  String get openInBrowser;

  /// Error state when video player fails
  ///
  /// In en, this message translates to:
  /// **'Failed to play video'**
  String get failedToPlayVideo;

  /// Button to open video URL externally
  ///
  /// In en, this message translates to:
  /// **'Open Video Externally'**
  String get openVideoExternally;

  /// Error state when audio player fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load audio'**
  String get failedToLoadAudio;

  /// Button to open audio URL externally
  ///
  /// In en, this message translates to:
  /// **'Open Audio Link'**
  String get openAudioLink;

  /// Status text while loading PDF document
  ///
  /// In en, this message translates to:
  /// **'Loading document...'**
  String get loadingDocument;

  /// Error state when PDF viewer fails
  ///
  /// In en, this message translates to:
  /// **'Failed to display PDF document'**
  String get failedToDisplayPdf;

  /// Button to open PDF in external browser
  ///
  /// In en, this message translates to:
  /// **'Open PDF in Browser'**
  String get openPdfInBrowser;

  /// PDF page indicator
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageOfTotal(String current, String total);

  /// Tooltip for entering picture-in-picture mode
  ///
  /// In en, this message translates to:
  /// **'Picture in Picture'**
  String get pictureInPicture;

  /// Tooltip for opening external link
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get openLink;

  /// Header title for media viewer screen
  ///
  /// In en, this message translates to:
  /// **'Media Viewer'**
  String get mediaViewer;

  /// Error message when opening media URL fails
  ///
  /// In en, this message translates to:
  /// **'Could not launch media URL'**
  String get couldNotLaunchMediaUrl;

  /// Title for media preview widget
  ///
  /// In en, this message translates to:
  /// **'Media Preview'**
  String get mediaPreview;

  /// Title for video preview widget
  ///
  /// In en, this message translates to:
  /// **'Video Preview'**
  String get videoPreview;

  /// Error message when video cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Failed to load video'**
  String get failedToLoadVideo;

  /// Button label to open resource in external application
  ///
  /// In en, this message translates to:
  /// **'Open External'**
  String get openExternal;

  /// Tooltip for entering fullscreen
  ///
  /// In en, this message translates to:
  /// **'Full Screen'**
  String get fullScreen;

  /// Default title for picture-in-picture overlay
  ///
  /// In en, this message translates to:
  /// **'PiP Video'**
  String get pipVideo;

  /// Summary sentence of forgotten answers over period
  ///
  /// In en, this message translates to:
  /// **'An average of {percent}% answers forgotten over {days} days'**
  String answersForgottenSummary(String percent, String days);
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
