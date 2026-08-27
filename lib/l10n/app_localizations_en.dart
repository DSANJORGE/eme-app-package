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

  @override
  String get verificationCodeSent => 'Verification code sent to your email!';

  @override
  String get verificationCodeResent => 'Verification code resent to your email!';

  @override
  String get userDoesNotExist => 'User does not exist.';

  @override
  String get failedToSendCode => 'Failed to send code';

  @override
  String get pleaseEnterAll6Digits => 'Please enter all 6 digits';

  @override
  String get invalidVerificationCode => 'Invalid verification code. Please try again.';

  @override
  String get createAccount => 'Create Account';

  @override
  String get editEmail => 'Edit Email';

  @override
  String noAccountFoundRegister(String email) {
    return 'No account found for $email. Please enter your details to register.';
  }

  @override
  String get firstName => 'First Name';

  @override
  String get enterFirstName => 'Enter your first name';

  @override
  String get pleaseEnterFirstName => 'Please enter your first name';

  @override
  String get lastName => 'Last Name';

  @override
  String get enterLastName => 'Enter your last name';

  @override
  String get pleaseEnterLastName => 'Please enter your last name';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String sentToEmail(String email) {
    return 'Sent to $email';
  }

  @override
  String workspacePrefix(String name) {
    return 'Workspace: $name';
  }

  @override
  String resendCodeIn(String seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get didntReceiveCode => 'Didn\'t receive the code? ';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get registerAndSendCode => 'Register & Send Code';

  @override
  String get verifyAndSignIn => 'Verify & Sign In';

  @override
  String get sendVerificationCode => 'Send Verification Code';

  @override
  String get selectWorkspace => 'Select Workspace';

  @override
  String get workspaceRemoved => 'Workspace removed';

  @override
  String get failedToRemoveWorkspace => 'Failed to remove workspace';

  @override
  String get deleteWorkspace => 'Delete Workspace';

  @override
  String deleteWorkspaceConfirm(String name, String root) {
    return 'Are you sure you want to delete workspace \"$name\" ($root)?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get consentUpdatedAccepted => 'Data collection consent updated to Accepted.';

  @override
  String get consentUpdatedEssential => 'Data collection consent updated to Essential-only.';

  @override
  String get failedToUpdateConsent => 'Failed to update consent preference';

  @override
  String get dataDeletionRequested => 'Personal collected data deletion has been requested.';

  @override
  String get failedToRequestDataDeletion => 'Failed to request data deletion';

  @override
  String get dataCollectionConsentStatus => 'Data Collection Consent Status';

  @override
  String get accountInfoTitle => 'Account Information';

  @override
  String get accountInfoSubtitle => 'Name, email address, and authentication credentials.';

  @override
  String get interactiveChatLearningTitle => 'Interactive Chat & Learning Data';

  @override
  String get interactiveChatLearningSubtitle => 'Prompts, responses, diagnostic test scores & progress.';

  @override
  String get dataProtectionTitle => 'Data Protection & Encryption';

  @override
  String get dataProtectionSubtitle => 'HTTPS transmission and secure cloud storage.';

  @override
  String failedToLoadTopics(String error) {
    return 'Failed to load topics: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get noTopicsAvailable => 'No topics available.';

  @override
  String get viewProfile => 'View profile';

  @override
  String get catalog => 'Catalog';

  @override
  String couldNotOpenLink(String url) {
    return 'Could not open link: $url';
  }

  @override
  String failedToLoadTutorials(String error) {
    return 'Failed to load tutorials: $error';
  }

  @override
  String get noTutorialsAvailable => 'No tutorials available.';

  @override
  String get failedToSelectImage => 'Failed to select image';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String get failedToUpdateProfile => 'Failed to update profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get email => 'Email';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String fieldIsRequired(String label) {
    return '$label is required';
  }

  @override
  String get accountDataCleared => 'Account data cleared successfully.';

  @override
  String get failedToClearAccountData => 'Failed to clear account data';

  @override
  String plusMoreCount(String count) {
    return '+$count more';
  }

  @override
  String get intermediate => 'Intermediate';

  @override
  String get failedToLoadTutorialSession => 'Failed to load tutorial session';

  @override
  String get failedToSubmitAnswer => 'Failed to submit answer';

  @override
  String get failedToSendFollowUp => 'Failed to send follow up';

  @override
  String get failedToContinueTutorial => 'Failed to continue tutorial';

  @override
  String get reportDetailsPrompt => 'Report hallucination, inaccurate information, or inappropriate AI response:';

  @override
  String get additionalDetailsOptional => 'Additional details (optional)...';

  @override
  String get report => 'Report';

  @override
  String get correct => 'Correct!';

  @override
  String get incorrect => 'Incorrect.';

  @override
  String get errorLoadingChat => 'An error occured while loading the chat.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get start => 'Start';

  @override
  String get askFollowUpHint => 'Ask a follow-up question...';

  @override
  String get send => 'Send';

  @override
  String get continueButton => 'Continue';

  @override
  String get howConfidentQuestion => 'HOW CONFIDENT ARE YOU IN THIS ANSWER?';

  @override
  String get submitAnswer => 'Submit Answer';

  @override
  String get connectingToTutorSession => 'Connecting to tutor session...';

  @override
  String get quizCompleted => 'Quiz Completed! 🎉';

  @override
  String get goBack => 'Go Back!';

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String get openInBrowser => 'Open in Browser';

  @override
  String get failedToPlayVideo => 'Failed to play video';

  @override
  String get openVideoExternally => 'Open Video Externally';

  @override
  String get failedToLoadAudio => 'Failed to load audio';

  @override
  String get openAudioLink => 'Open Audio Link';

  @override
  String get loadingDocument => 'Loading document...';

  @override
  String get failedToDisplayPdf => 'Failed to display PDF document';

  @override
  String get openPdfInBrowser => 'Open PDF in Browser';

  @override
  String pageOfTotal(String current, String total) {
    return 'Page $current of $total';
  }

  @override
  String get pictureInPicture => 'Picture in Picture';

  @override
  String get openLink => 'Open link';

  @override
  String get mediaViewer => 'Media Viewer';

  @override
  String get couldNotLaunchMediaUrl => 'Could not launch media URL';

  @override
  String get mediaPreview => 'Media Preview';

  @override
  String get videoPreview => 'Video Preview';

  @override
  String get failedToLoadVideo => 'Failed to load video';

  @override
  String get openExternal => 'Open External';

  @override
  String get fullScreen => 'Full Screen';

  @override
  String get pipVideo => 'PiP Video';

  @override
  String answersForgottenSummary(String percent, String days) {
    return 'An average of $percent% answers forgotten over $days days';
  }
}
