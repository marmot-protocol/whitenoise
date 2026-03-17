import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
  ];

  /// Label shown in chat list when the last message contains photos
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Photo} other{Photos}}'**
  String photoCount(int count);

  /// The application title displayed on home screen
  ///
  /// In en, this message translates to:
  /// **'White Noise'**
  String get appTitle;

  /// First slogan word on home screen
  ///
  /// In en, this message translates to:
  /// **'Decentralized'**
  String get sloganDecentralized;

  /// Second slogan word on home screen
  ///
  /// In en, this message translates to:
  /// **'Uncensorable'**
  String get sloganUncensorable;

  /// Third slogan word on home screen
  ///
  /// In en, this message translates to:
  /// **'Secure Messaging'**
  String get sloganSecureMessaging;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Sign up button text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Title on login screen
  ///
  /// In en, this message translates to:
  /// **'Enter your private key'**
  String get loginTitle;

  /// Label for private key input field
  ///
  /// In en, this message translates to:
  /// **'Enter your private key'**
  String get enterPrivateKey;

  /// Placeholder text for nsec input
  ///
  /// In en, this message translates to:
  /// **'nsec...'**
  String get nsecPlaceholder;

  /// Title on signup screen
  ///
  /// In en, this message translates to:
  /// **'Setup profile'**
  String get setupProfile;

  /// Label for name input field
  ///
  /// In en, this message translates to:
  /// **'Choose a name'**
  String get chooseName;

  /// Placeholder for name input
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// Label for bio input field
  ///
  /// In en, this message translates to:
  /// **'Introduce yourself'**
  String get introduceYourself;

  /// Placeholder for bio input
  ///
  /// In en, this message translates to:
  /// **'Write something about yourself'**
  String get writeSomethingAboutYourself;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Title on onboarding screen after signup
  ///
  /// In en, this message translates to:
  /// **'Your profile is ready!'**
  String get profileReady;

  /// Hint text on onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Start a conversation by adding friends or sharing your profile.'**
  String get startConversationHint;

  /// Generic share text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Button text to share profile
  ///
  /// In en, this message translates to:
  /// **'Share your profile'**
  String get shareYourProfile;

  /// Button text to start a new chat
  ///
  /// In en, this message translates to:
  /// **'Start a chat'**
  String get startChat;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Button to share profile and connect with others
  ///
  /// In en, this message translates to:
  /// **'Share & connect'**
  String get shareAndConnect;

  /// Button to switch between profiles
  ///
  /// In en, this message translates to:
  /// **'Switch profile'**
  String get switchProfile;

  /// Title for add profile screen
  ///
  /// In en, this message translates to:
  /// **'Add a new profile'**
  String get addNewProfile;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Profile keys'**
  String get profileKeys;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Network relays'**
  String get networkRelays;

  /// Settings menu item for appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Settings menu item for privacy and security
  ///
  /// In en, this message translates to:
  /// **'Privacy & security'**
  String get privacySecurity;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Donate to White Noise'**
  String get donateToWhiteNoise;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Developer settings'**
  String get developerSettings;

  /// Settings menu item and button
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Appearance screen title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// Privacy and security screen title
  ///
  /// In en, this message translates to:
  /// **'Privacy & security'**
  String get privacySecurityTitle;

  /// Section title for delete all app data
  ///
  /// In en, this message translates to:
  /// **'Delete All App Data'**
  String get deleteAllAppData;

  /// Button text to delete all app data
  ///
  /// In en, this message translates to:
  /// **'Delete app data'**
  String get deleteAppData;

  /// Description for delete all app data action
  ///
  /// In en, this message translates to:
  /// **'Erase every profile, key, chat, and local file from this device.'**
  String get deleteAllAppDataDescription;

  /// Confirmation dialog title for deleting all app data
  ///
  /// In en, this message translates to:
  /// **'Delete all app data?'**
  String get deleteAllAppDataConfirmation;

  /// Warning message in delete all app data confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This will erase every profile, key, chat, and local file from this device. This cannot be undone.'**
  String get deleteAllAppDataWarning;

  /// Theme selector label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Profile keys screen title
  ///
  /// In en, this message translates to:
  /// **'Profile keys'**
  String get profileKeysTitle;

  /// Public key label
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get publicKey;

  /// System notice message when public key is copied
  ///
  /// In en, this message translates to:
  /// **'Public key copied to clipboard'**
  String get publicKeyCopied;

  /// Description of public key
  ///
  /// In en, this message translates to:
  /// **'Your public key is your identifier on Nostr. Share it so others can find, recognize, and connect with you.'**
  String get publicKeyDescription;

  /// Private key label
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get privateKey;

  /// System notice message when private key is copied
  ///
  /// In en, this message translates to:
  /// **'Private key copied to clipboard'**
  String get privateKeyCopied;

  /// Description of private key
  ///
  /// In en, this message translates to:
  /// **'Your private key works like a secret password that grants access to your Nostr identity.'**
  String get privateKeyDescription;

  /// Warning box title for private key
  ///
  /// In en, this message translates to:
  /// **'Keep your private key safe!'**
  String get keepPrivateKeySecure;

  /// Warning message about private key
  ///
  /// In en, this message translates to:
  /// **'Don\'t share your private key publicly, and use it only to log in to other Nostr apps.'**
  String get privateKeyWarning;

  /// Title when private key is on external signer
  ///
  /// In en, this message translates to:
  /// **'Private key is stored in external signer'**
  String get nsecOnExternalSigner;

  /// Description when private key is on external signer
  ///
  /// In en, this message translates to:
  /// **'Your private key isn\'t available in White Noise. Open your signer to view or manage it.'**
  String get nsecOnExternalSignerDescription;

  /// Edit profile screen title
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// Profile name input label
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get profileName;

  /// Nostr address input label
  ///
  /// In en, this message translates to:
  /// **'Nostr address'**
  String get nostrAddress;

  /// Placeholder for Nostr address
  ///
  /// In en, this message translates to:
  /// **'example@whitenoise.chat'**
  String get nostrAddressPlaceholder;

  /// About input label
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get aboutYou;

  /// Warning box title for public profile
  ///
  /// In en, this message translates to:
  /// **'Profile is public'**
  String get profileIsPublic;

  /// Description about public profile visibility
  ///
  /// In en, this message translates to:
  /// **'Your profile information will be visible to everyone on the network.'**
  String get profilePublicDescription;

  /// Discard button text
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Discard changes button text
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get discardChanges;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// System notice message when profile is updated
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// Error message when profile fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading profile: {error}'**
  String errorLoadingProfile(String error);

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(String error);

  /// User-friendly error when profile fails to load
  ///
  /// In en, this message translates to:
  /// **'Unable to load profile. Please try again.'**
  String get profileLoadError;

  /// User-friendly error when nsec/private key fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load private key. Please try again.'**
  String get failedToLoadPrivateKey;

  /// User-friendly error when profile fails to save
  ///
  /// In en, this message translates to:
  /// **'Unable to save profile. Please try again.'**
  String get profileSaveError;

  /// Network relays screen title
  ///
  /// In en, this message translates to:
  /// **'Network Relays'**
  String get networkRelaysTitle;

  /// My relays section header
  ///
  /// In en, this message translates to:
  /// **'My Relays'**
  String get myRelays;

  /// Help text for my relays
  ///
  /// In en, this message translates to:
  /// **'Relays you have defined for use across all your Nostr applications.'**
  String get myRelaysHelp;

  /// Inbox relays section header
  ///
  /// In en, this message translates to:
  /// **'Inbox Relays'**
  String get inboxRelays;

  /// Help text for inbox relays
  ///
  /// In en, this message translates to:
  /// **'Relays used to receive invitations and start secure conversations with new users.'**
  String get inboxRelaysHelp;

  /// Key package relays section header
  ///
  /// In en, this message translates to:
  /// **'Key Package Relays'**
  String get keyPackageRelays;

  /// Help text for key package relays
  ///
  /// In en, this message translates to:
  /// **'Relays that store your secure key so others can invite you to encrypted conversations.'**
  String get keyPackageRelaysHelp;

  /// Error message when relays fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading relays'**
  String get errorLoadingRelays;

  /// Message when no relays are configured
  ///
  /// In en, this message translates to:
  /// **'No relays configured'**
  String get noRelaysConfigured;

  /// Donate screen title
  ///
  /// In en, this message translates to:
  /// **'Donate to White Noise'**
  String get donateTitle;

  /// Donate screen description
  ///
  /// In en, this message translates to:
  /// **'As a 501(c)3 non-profit, White Noise exists solely for your privacy and freedom, not for profit. Your support keeps us independent and uncompromised.'**
  String get donateDescription;

  /// Donate screen contribution acknowledgement text
  ///
  /// In en, this message translates to:
  /// **'If you need a contribution acknowledgement letter for a donation, get in touch with us at info@ipf.dev'**
  String get donateContributionLetter;

  /// Lightning address label
  ///
  /// In en, this message translates to:
  /// **'Lightning Address'**
  String get lightningAddress;

  /// Bitcoin silent payment label
  ///
  /// In en, this message translates to:
  /// **'Bitcoin Silent Payment'**
  String get bitcoinSilentPayment;

  /// System notice message when donation address is copied
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard. Thank you!'**
  String get copiedToClipboardThankYou;

  /// Share profile screen title
  ///
  /// In en, this message translates to:
  /// **'Share profile'**
  String get shareProfileTitle;

  /// Text below QR code
  ///
  /// In en, this message translates to:
  /// **'Scan to connect'**
  String get scanToConnect;

  /// Sign out screen title
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutTitle;

  /// Sign out confirmation title
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmation;

  /// Sign out warning first paragraph (chats deleted)
  ///
  /// In en, this message translates to:
  /// **'When you sign out of White Noise, your chats will be deleted from this device and cannot be restored on another device.'**
  String get signOutWarning;

  /// Sign out warning second paragraph (back up key, shown only for local storage)
  ///
  /// In en, this message translates to:
  /// **'If you haven\'t backed up your private key, you won\'t be able to use this profile on any other Nostr service.'**
  String get signOutWarningBackupKey;

  /// Back up private key section title
  ///
  /// In en, this message translates to:
  /// **'Back up your private key'**
  String get backUpPrivateKey;

  /// Hint for copying private key
  ///
  /// In en, this message translates to:
  /// **'Copy your private key to restore your account on another device.'**
  String get copyPrivateKeyHint;

  /// Error message when copying public key (npub) to clipboard fails
  ///
  /// In en, this message translates to:
  /// **'Failed to copy public key. Please try again.'**
  String get publicKeyCopyError;

  /// Empty state title for chat list
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noChatsYet;

  /// Empty state subtitle for chat list
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get startConversation;

  /// Title for welcome notice shown on empty chat list after signup
  ///
  /// In en, this message translates to:
  /// **'Your profile is ready'**
  String get welcomeNoticeTitle;

  /// Description for welcome notice shown on empty chat list
  ///
  /// In en, this message translates to:
  /// **'Tap {findPeople} to find your friends. {shareProfile} to connect with people you know, or {startANewChat} using the chat plus icon.'**
  String welcomeNoticeDescription(String findPeople, String shareProfile, String startANewChat);

  /// Button text to find/search for people
  ///
  /// In en, this message translates to:
  /// **'Find people'**
  String get findPeople;

  /// Text for starting a new chat action
  ///
  /// In en, this message translates to:
  /// **'start a new chat'**
  String get startANewChat;

  /// Empty state for chat screen
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// Placeholder for message input
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messagePlaceholder;

  /// Error message when sending message fails
  ///
  /// In en, this message translates to:
  /// **'Failed to send message. Please try again.'**
  String get failedToSendMessage;

  /// Message when invited to a chat
  ///
  /// In en, this message translates to:
  /// **'You are invited to a secure chat'**
  String get invitedToSecureChat;

  /// Suffix for system message showing who invited the user to chat (preceded by bold name)
  ///
  /// In en, this message translates to:
  /// **' invited you to chat'**
  String get invitedYouToChatSuffix;

  /// Decline button text
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// Accept button text
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// Error when accepting invitation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to accept invitation. Please try again.'**
  String get failedToAcceptInvitation;

  /// Error when declining invitation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to decline invitation. Please try again.'**
  String get failedToDeclineInvitation;

  /// User search screen title
  ///
  /// In en, this message translates to:
  /// **'Start new chat'**
  String get startNewChat;

  /// Empty search results message
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// Message when user has no follows
  ///
  /// In en, this message translates to:
  /// **'No follows yet'**
  String get noFollowsYet;

  /// User search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Name or npub1...'**
  String get searchByNameOrNpub;

  /// Developer settings screen title
  ///
  /// In en, this message translates to:
  /// **'Developer Settings'**
  String get developerSettingsTitle;

  /// Key package management screen title and row label
  ///
  /// In en, this message translates to:
  /// **'Key Package Management'**
  String get keyPackageManagementTitle;

  /// Developer settings row description for key package management
  ///
  /// In en, this message translates to:
  /// **'Publish, refresh, and delete account key packages'**
  String get keyPackageManagementDescription;

  /// Developer settings row label and relay state screen title
  ///
  /// In en, this message translates to:
  /// **'Relay State'**
  String get relayStateTitle;

  /// Developer settings row description for relay state
  ///
  /// In en, this message translates to:
  /// **'Inspect the live relay control planes'**
  String get relayStateDescription;

  /// Technical label shown above the relay control state dump
  ///
  /// In en, this message translates to:
  /// **'debug_relay_control_state:'**
  String get relayControlStateDumpLabel;

  /// Description shown above the relay control state dump
  ///
  /// In en, this message translates to:
  /// **'Snapshot of the live relay discovery, inbox, and group planes.'**
  String get relayControlStateSnapshotDescription;

  /// Button label shown while the relay control state dump is loading
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get relayControlStateLoading;

  /// Button label to refresh the relay control state dump
  ///
  /// In en, this message translates to:
  /// **'Refresh Dump'**
  String get relayControlStateRefreshButton;

  /// Button label to copy the relay control state dump
  ///
  /// In en, this message translates to:
  /// **'Copy Dump'**
  String get relayControlStateCopyButton;

  /// Button to publish new key package
  ///
  /// In en, this message translates to:
  /// **'Publish New Key Package'**
  String get publishNewKeyPackage;

  /// Button to refresh key packages
  ///
  /// In en, this message translates to:
  /// **'Refresh Key Packages'**
  String get refreshKeyPackages;

  /// Button to delete all key packages
  ///
  /// In en, this message translates to:
  /// **'Delete All Key Packages'**
  String get deleteAllKeyPackages;

  /// Key packages count header
  ///
  /// In en, this message translates to:
  /// **'Key Packages ({count})'**
  String keyPackagesCount(int count);

  /// Message when no key packages exist
  ///
  /// In en, this message translates to:
  /// **'No key packages found'**
  String get noKeyPackagesFound;

  /// Success message when key package is published
  ///
  /// In en, this message translates to:
  /// **'Key package published'**
  String get keyPackagePublished;

  /// Success message when key packages are refreshed
  ///
  /// In en, this message translates to:
  /// **'Key packages refreshed'**
  String get keyPackagesRefreshed;

  /// Success message when all key packages are deleted
  ///
  /// In en, this message translates to:
  /// **'All key packages deleted'**
  String get keyPackagesDeleted;

  /// Success message when a key package is deleted
  ///
  /// In en, this message translates to:
  /// **'Key package deleted'**
  String get keyPackageDeleted;

  /// Error message when fetching key packages fails
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh key packages. Please try again.'**
  String get keyPackageFetchFailed;

  /// Error message when publishing a key package fails
  ///
  /// In en, this message translates to:
  /// **'Failed to publish key package. Please try again.'**
  String get keyPackagePublishFailed;

  /// Error message when deleting a key package fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete key package. Please try again.'**
  String get keyPackageDeleteFailed;

  /// Error message when deleting all key packages fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete all key packages. Please try again.'**
  String get keyPackageDeleteAllFailed;

  /// Key package item title
  ///
  /// In en, this message translates to:
  /// **'Package {number}'**
  String packageNumber(int number);

  /// Go back button text
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// Create group button text
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroup;

  /// Menu item text to start a new group chat
  ///
  /// In en, this message translates to:
  /// **'New group chat'**
  String get newGroupChat;

  /// User selection screen title
  ///
  /// In en, this message translates to:
  /// **'Select Members'**
  String get selectMembers;

  /// Number of selected users
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// Clear selection button text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSelection;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Set up group screen title
  ///
  /// In en, this message translates to:
  /// **'Set up group'**
  String get setUpGroup;

  /// Group name label
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// Group name input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter group name'**
  String get groupNamePlaceholder;

  /// Group description label
  ///
  /// In en, this message translates to:
  /// **'Group Description'**
  String get groupDescription;

  /// Generic description label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Group description input placeholder
  ///
  /// In en, this message translates to:
  /// **'What is this group for?'**
  String get groupDescriptionPlaceholder;

  /// Number of members
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String members(int count);

  /// Label for inviting members in group setup
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Inviting member:} other{Inviting members:}}'**
  String invitingMembers(int count);

  /// Message for users without key packages
  ///
  /// In en, this message translates to:
  /// **'Users without key packages (cannot be added)'**
  String get usersWithoutKeyPackages;

  /// Title for users without key packages
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This user is not on White Noise} other{These users are not on White Noise}}'**
  String usersNotOnWhiteNoise(int count);

  /// Description for users without key packages
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This user cannot be added to the group because they don\'t have White Noise installed or haven\'t published their key package yet.} other{These users cannot be added to the group because they don\'t have White Noise installed or haven\'t published their key packages yet.}}'**
  String usersNotOnWhiteNoiseDescription(int count);

  /// Uploading image status
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get uploadingImage;

  /// Creating group status
  ///
  /// In en, this message translates to:
  /// **'Creating group...'**
  String get creatingGroup;

  /// Error message when group name is empty
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get groupNameRequired;

  /// Error message when no users have key packages
  ///
  /// In en, this message translates to:
  /// **'No users with key packages to add'**
  String get noUsersWithKeyPackages;

  /// Error message when group creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create group'**
  String get createGroupFailed;

  /// Report error button text
  ///
  /// In en, this message translates to:
  /// **'Report error'**
  String get reportError;

  /// WIP screen message
  ///
  /// In en, this message translates to:
  /// **'We\'re working on this feature. To support development, please donate to White Noise'**
  String get wipMessage;

  /// Donate button text
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donate;

  /// Settings menu item to open support chat
  ///
  /// In en, this message translates to:
  /// **'Chat with support'**
  String get chatWithSupport;

  /// Initial welcome message shown in support chat
  ///
  /// In en, this message translates to:
  /// **'Hi! Tell us what\'s on your mind - questions, bugs, or feedback. We usually reply within a few hours.'**
  String get supportChatWelcomeMessage;

  /// Add relay sheet title and button
  ///
  /// In en, this message translates to:
  /// **'Add Relay'**
  String get addRelay;

  /// Label for relay address input
  ///
  /// In en, this message translates to:
  /// **'Enter relay address'**
  String get enterRelayAddress;

  /// Placeholder for relay address input
  ///
  /// In en, this message translates to:
  /// **'wss://relay.example.com'**
  String get relayAddressPlaceholder;

  /// Remove relay confirmation title
  ///
  /// In en, this message translates to:
  /// **'Remove Relay?'**
  String get removeRelay;

  /// Remove relay confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this relay? This action cannot be undone.'**
  String get removeRelayConfirmation;

  /// Remove button text
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Message menu title
  ///
  /// In en, this message translates to:
  /// **'Message actions'**
  String get messageActions;

  /// Reply button text
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// Copy message button text
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyMessage;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Error when deleting message fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete message. Please try again.'**
  String get failedToDeleteMessage;

  /// Error when sending reaction fails
  ///
  /// In en, this message translates to:
  /// **'Failed to send reaction. Please try again.'**
  String get failedToSendReaction;

  /// Error when removing reaction fails
  ///
  /// In en, this message translates to:
  /// **'Failed to remove reaction. Please try again.'**
  String get failedToRemoveReaction;

  /// Fallback name for unknown user
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUser;

  /// Placeholder shown when a user has no display name set
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get noName;

  /// Fallback name for unknown group
  ///
  /// In en, this message translates to:
  /// **'Unknown group'**
  String get unknownGroup;

  /// Invitation subtitle in chat list
  ///
  /// In en, this message translates to:
  /// **'Has invited you to a secure chat'**
  String get hasInvitedYouToSecureChat;

  /// Invitation subtitle with user name
  ///
  /// In en, this message translates to:
  /// **'{name} has invited you to a secure chat'**
  String userInvitedYouToSecureChat(String name);

  /// Generic invitation subtitle
  ///
  /// In en, this message translates to:
  /// **'You have been invited to a secure chat'**
  String get youHaveBeenInvitedToSecureChat;

  /// Language selector label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// System language option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// Error message when language update fails to persist
  ///
  /// In en, this message translates to:
  /// **'Failed to save language preference. Please try again.'**
  String get languageUpdateFailed;

  /// Relative time for events that happened moments ago
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// Relative time for minutes ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String timeMinutesAgo(int count);

  /// Relative time for hours ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String timeHoursAgo(int count);

  /// Relative time for days ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{yesterday} other{{count} days ago}}'**
  String timeDaysAgo(int count);

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Follow button text
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// Unfollow button text
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// Search match count indicator, e.g. '1 of 3 matches'
  ///
  /// In en, this message translates to:
  /// **'{current} of {total, plural, =1{1 match} other{{total} matches}}'**
  String chatSearchMatchCount(int current, int total);

  /// Error when starting chat fails
  ///
  /// In en, this message translates to:
  /// **'Failed to start chat. Please try again.'**
  String get failedToStartChat;

  /// Callout title when user is not on White Noise
  ///
  /// In en, this message translates to:
  /// **'Invite to White Noise'**
  String get inviteToWhiteNoise;

  /// Callout description when user is not on White Noise
  ///
  /// In en, this message translates to:
  /// **'{name} isn\'t on White Noise yet. Share the app to start a secure chat.'**
  String inviteToWhiteNoiseDescription(String name);

  /// Text shared with users who haven't installed White Noise yet
  ///
  /// In en, this message translates to:
  /// **'Join me on White Noise. No phone number. No surveillance. Just real privacy. Download it here: https://www.whitenoise.chat/download'**
  String get inviteMessage;

  /// Error when follow or unfollow action fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update follow status. Please try again.'**
  String get failedToUpdateFollow;

  /// Error message when image picker fails
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image. Please try again.'**
  String get imagePickerError;

  /// Title for scan nsec screen
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanNsec;

  /// Hint text on scan nsec screen
  ///
  /// In en, this message translates to:
  /// **'Scan your private key QR code to login.'**
  String get scanNsecHint;

  /// Error message when camera permission is denied
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get cameraPermissionDenied;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Title for scan npub screen
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanNpub;

  /// Hint text on scan npub screen
  ///
  /// In en, this message translates to:
  /// **'Scan a contact\'s QR code.'**
  String get scanNpubHint;

  /// Error message when scanned npub is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid public key. Please try again.'**
  String get invalidNpub;

  /// Prefix for messages sent by the user
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Timestamp for events less than 60 seconds ago
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get timestampNow;

  /// Timestamp for events 1-59 minutes ago
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String timestampMinutes(int count);

  /// Timestamp for events 1-12 hours ago
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String timestampHours(int count);

  /// Timestamp for events from yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timestampYesterday;

  /// Monday weekday name
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMonday;

  /// Tuesday weekday name
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTuesday;

  /// Wednesday weekday name
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWednesday;

  /// Thursday weekday name
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThursday;

  /// Friday weekday name
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFriday;

  /// Saturday weekday name
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySaturday;

  /// Sunday weekday name
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySunday;

  /// January short name
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJanShort;

  /// February short name
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFebShort;

  /// March short name
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMarShort;

  /// April short name
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthAprShort;

  /// May short name
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMayShort;

  /// June short name
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJunShort;

  /// July short name
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJulShort;

  /// August short name
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAugShort;

  /// September short name
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSepShort;

  /// October short name
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOctShort;

  /// November short name
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNovShort;

  /// December short name
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDecShort;

  /// Button text to login using the Amber signer app (Android only)
  ///
  /// In en, this message translates to:
  /// **'Login with Amber'**
  String get loginWithAmber;

  /// Error message when connection to external signer fails
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to signer. Please try again.'**
  String get signerConnectionError;

  /// Search placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Chat list filter chip for chats
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get filterChats;

  /// Chat list filter chip for archived chats
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get filterArchive;

  /// Android signer error when user rejects the request
  ///
  /// In en, this message translates to:
  /// **'Login cancelled'**
  String get signerErrorUserRejected;

  /// Android signer error when not connected
  ///
  /// In en, this message translates to:
  /// **'Not connected to signer. Please try again.'**
  String get signerErrorNotConnected;

  /// Android signer error when no signer app is installed
  ///
  /// In en, this message translates to:
  /// **'No signer app found. Please install a NIP-55 compatible signer.'**
  String get signerErrorNoSigner;

  /// Android signer error when signer does not respond
  ///
  /// In en, this message translates to:
  /// **'No response from signer. Please try again.'**
  String get signerErrorNoResponse;

  /// Android signer error when public key is not returned
  ///
  /// In en, this message translates to:
  /// **'Unable to get public key from signer.'**
  String get signerErrorNoPubkey;

  /// Android signer error when signer returns no result
  ///
  /// In en, this message translates to:
  /// **'Signer did not return a result.'**
  String get signerErrorNoResult;

  /// Android signer error when signed event is not returned
  ///
  /// In en, this message translates to:
  /// **'Signer did not return a signed event.'**
  String get signerErrorNoEvent;

  /// Android signer error when a request is already in progress
  ///
  /// In en, this message translates to:
  /// **'Another request is in progress. Please wait.'**
  String get signerErrorRequestInProgress;

  /// Android signer error when signer cannot be launched
  ///
  /// In en, this message translates to:
  /// **'Unable to launch signer. Please try again.'**
  String get signerErrorNoActivity;

  /// Android signer error when launch fails
  ///
  /// In en, this message translates to:
  /// **'Failed to launch signer app.'**
  String get signerErrorLaunchError;

  /// Android signer generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred with the signer. Please try again.'**
  String get signerErrorUnknown;

  /// Text shown in reply preview when the original message is deleted or not available
  ///
  /// In en, this message translates to:
  /// **'Message not found'**
  String get messageNotFound;

  /// Pin chat context menu action
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// Unpin chat context menu action
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// Mute chat context menu action
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// Archive chat context menu action
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// Error message when pin/unpin operation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update pin. Please try again.'**
  String get failedToPinChat;

  /// Login carousel slide 1 title
  ///
  /// In en, this message translates to:
  /// **'Privacy and security'**
  String get carouselPrivacyTitle;

  /// Login carousel slide 1 description
  ///
  /// In en, this message translates to:
  /// **'Keep your conversations private. Even in case of a breach, your messages remain secure.'**
  String get carouselPrivacyDescription;

  /// Login carousel slide 2 title
  ///
  /// In en, this message translates to:
  /// **'Choose your identity'**
  String get carouselIdentityTitle;

  /// Login carousel slide 2 description
  ///
  /// In en, this message translates to:
  /// **'Chat without revealing your phone number or email. Choose your identity: real name, pseudonym, or anonymous.'**
  String get carouselIdentityDescription;

  /// Login carousel slide 3 title
  ///
  /// In en, this message translates to:
  /// **'Decentralized and permissionless'**
  String get carouselDecentralizedTitle;

  /// Login carousel slide 3 description
  ///
  /// In en, this message translates to:
  /// **'No central authority controls your communication-no permissions needed, no censorship possible.'**
  String get carouselDecentralizedDescription;

  /// Learn more button text on signup screen
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// Button to return to signup from carousel
  ///
  /// In en, this message translates to:
  /// **'Back to sign up'**
  String get backToSignUp;

  /// Button to delete all application data
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// Confirmation dialog title for delete all data
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllDataConfirmation;

  /// Warning message for delete all data action
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your chats, messages, and settings from this device. This action cannot be undone.'**
  String get deleteAllDataWarning;

  /// Error message when data deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete all data. Please try again.'**
  String get deleteAllDataError;

  /// Chat information screen title
  ///
  /// In en, this message translates to:
  /// **'Chat Information'**
  String get chatInformation;

  /// Action label to add a user as contact
  ///
  /// In en, this message translates to:
  /// **'Add as contact'**
  String get addAsContact;

  /// Action label to remove a user as contact
  ///
  /// In en, this message translates to:
  /// **'Remove as contact'**
  String get removeAsContact;

  /// Action label to add this user to a group
  ///
  /// In en, this message translates to:
  /// **'Add to group'**
  String get addToGroup;

  /// Action label to add this user to another group
  ///
  /// In en, this message translates to:
  /// **'Add to another group'**
  String get addToAnotherGroup;

  /// Title for the relay resolution screen
  ///
  /// In en, this message translates to:
  /// **'Relay Setup'**
  String get relayResolutionTitle;

  /// Explanation of what happened during relay resolution
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find your relay lists on the network. You can provide a relay where your lists are published, or use our default relays to get started.'**
  String get relayResolutionDescription;

  /// Button text for publishing defaults
  ///
  /// In en, this message translates to:
  /// **'Use default relays'**
  String get relayResolutionUseDefaults;

  /// Button text for trying a custom relay
  ///
  /// In en, this message translates to:
  /// **'Search relay'**
  String get relayResolutionTryRelay;

  /// Placeholder for relay URL input
  ///
  /// In en, this message translates to:
  /// **'wss://relay.example.com'**
  String get relayResolutionRelayPlaceholder;

  /// Label for relay URL input
  ///
  /// In en, this message translates to:
  /// **'Relay URL'**
  String get relayResolutionRelayLabel;

  /// Error when custom relay didn't find lists
  ///
  /// In en, this message translates to:
  /// **'No relay lists found on this relay. Try another or use defaults.'**
  String get relayResolutionNotFound;

  /// Error message for LoginInvalidKeyFormat
  ///
  /// In en, this message translates to:
  /// **'Invalid nsec. Make sure you entered it correctly.'**
  String get loginErrorInvalidKey;

  /// Error message for LoginNoRelayConnections
  ///
  /// In en, this message translates to:
  /// **'Could not connect to any relays. Please check your connection and try again.'**
  String get loginErrorNoRelayConnections;

  /// Error message for LoginTimeout
  ///
  /// In en, this message translates to:
  /// **'Login timed out. Please try again.'**
  String get loginErrorTimeout;

  /// Generic fallback error message for login
  ///
  /// In en, this message translates to:
  /// **'An error occurred during login. Please try again.'**
  String get loginErrorGeneric;

  /// Error when trying to continue a login that was not started
  ///
  /// In en, this message translates to:
  /// **'No login in progress. Please start over.'**
  String get loginErrorNoLoginInProgress;

  /// Error for internal login failures
  ///
  /// In en, this message translates to:
  /// **'An internal error occurred. Please try again.'**
  String get loginErrorInternal;

  /// Error when clipboard is empty during login paste
  ///
  /// In en, this message translates to:
  /// **'Nothing to paste'**
  String get loginPasteNothingToPaste;

  /// Error when clipboard paste fails during login
  ///
  /// In en, this message translates to:
  /// **'Failed to paste from clipboard'**
  String get loginPasteFailed;

  /// Button text to open device settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Generic scanner error message
  ///
  /// In en, this message translates to:
  /// **'Scanner error'**
  String get scannerError;

  /// Description for generic scanner error
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with the scanner. Please try again.'**
  String get scannerErrorDescription;

  /// Description for camera permission denied error
  ///
  /// In en, this message translates to:
  /// **'Please enable camera access in your device settings to scan QR codes.'**
  String get cameraPermissionDeniedDescription;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Group info screen title
  ///
  /// In en, this message translates to:
  /// **'Group Information'**
  String get groupInformation;

  /// Edit group screen title
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get editGroup;

  /// Button text for editing a group in group info screen
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editGroupAction;

  /// Label for group name input
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get groupNameLabel;

  /// Label for group description input
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get groupDescriptionLabel;

  /// Member count label for group info
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Member} other{{count} Members}}'**
  String membersCount(int count);

  /// Badge label for admin users in group member list
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminBadge;

  /// Section label for group member list
  ///
  /// In en, this message translates to:
  /// **'Members:'**
  String get membersLabel;

  /// Badge label for regular (non-admin) members in a group
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberBadge;

  /// Action label to send a message to a user
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// Action label to make a group member an admin
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get makeAdmin;

  /// Action label to remove admin role from a group member
  ///
  /// In en, this message translates to:
  /// **'Remove admin'**
  String get removeAdminRole;

  /// Action label to remove a member from a group
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get removeFromGroup;

  /// Confirmation dialog title for removing a member from group
  ///
  /// In en, this message translates to:
  /// **'Remove from group?'**
  String get removeFromGroupConfirmation;

  /// Warning message for removing a member from group
  ///
  /// In en, this message translates to:
  /// **'This member will be removed from the group and will no longer be able to see new messages.'**
  String get removeFromGroupWarning;

  /// Confirmation dialog title for making a member admin
  ///
  /// In en, this message translates to:
  /// **'Make admin?'**
  String get makeAdminConfirmation;

  /// Warning message for making a member admin
  ///
  /// In en, this message translates to:
  /// **'This member will be able to manage the group, add or remove members, and change group settings.'**
  String get makeAdminWarning;

  /// Confirmation dialog title for removing admin role
  ///
  /// In en, this message translates to:
  /// **'Remove admin?'**
  String get removeAdminConfirmation;

  /// Warning message for removing admin role
  ///
  /// In en, this message translates to:
  /// **'This member will no longer be able to manage the group, add or remove members, or change group settings.'**
  String get removeAdminWarning;

  /// Error message when removing a member from group fails
  ///
  /// In en, this message translates to:
  /// **'Failed to remove member. Please try again.'**
  String get failedToRemoveFromGroup;

  /// Error message when making a member admin fails
  ///
  /// In en, this message translates to:
  /// **'Failed to make admin. Please try again.'**
  String get failedToMakeAdmin;

  /// Error message when removing admin role fails
  ///
  /// In en, this message translates to:
  /// **'Failed to remove admin. Please try again.'**
  String get failedToRemoveAdmin;

  /// System notice message when group settings are updated
  ///
  /// In en, this message translates to:
  /// **'Group updated successfully'**
  String get groupUpdatedSuccessfully;

  /// User-friendly error when group fails to load
  ///
  /// In en, this message translates to:
  /// **'Unable to load group. Please try again.'**
  String get groupLoadError;

  /// User-friendly error when group fails to save
  ///
  /// In en, this message translates to:
  /// **'Unable to save group. Please try again.'**
  String get groupSaveError;

  /// Error message when fetching group members fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load group members. Please try again.'**
  String get failedToFetchGroupMembers;

  /// Error message when adding members to group fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add members. Please try again.'**
  String get failedToAddMembers;

  /// Warning message when group is created successfully but image upload fails
  ///
  /// In en, this message translates to:
  /// **'Group created, but the image failed to upload.'**
  String get groupImageUploadFailed;

  /// Callout title when user needs to update their whitenoise app
  ///
  /// In en, this message translates to:
  /// **'{name} needs update'**
  String updateNeeded(String name);

  /// Callout description when user needs to update their whitenoise app
  ///
  /// In en, this message translates to:
  /// **'You can\'t start a secure chat with {name} yet. They need to update White Noise before secure messaging works.'**
  String updateNeededDescription(String name);

  /// Confirmation dialog message for adding user to group
  ///
  /// In en, this message translates to:
  /// **'Add {userName} to {groupName}?'**
  String addToGroupConfirmation(String userName, String groupName);

  /// Callout description when unknown user is not on White Noise
  ///
  /// In en, this message translates to:
  /// **'This user isn\'t on White Noise yet. Share the app to start a secure chat.'**
  String get unknownInviteToWhiteNoiseDescription;

  /// Callout title when user needs to update their whitenoise app and we don't know the user name
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get unknownUserNeedsUpdate;

  /// Callout description when user needs to update their whitenoise app and we don't know the user name
  ///
  /// In en, this message translates to:
  /// **'You can\'t start a secure chat with this user yet. They need to update White Noise before secure messaging works.'**
  String get unknownUserNeedsUpdateDescription;

  /// Add button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Message shown when user has no groups to add someone to
  ///
  /// In en, this message translates to:
  /// **'No groups available'**
  String get noGroupsAvailable;

  /// Message shown when user has no groups where they are admin to add someone to
  ///
  /// In en, this message translates to:
  /// **'You\'re not an admin in any groups yet. Create a group to add people.'**
  String get noAdminGroupsAvailable;

  /// Title for the switch profile screen
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profilesTitle;

  /// Message shown when there are no accounts to switch to
  ///
  /// In en, this message translates to:
  /// **'No accounts available'**
  String get noAccountsAvailable;

  /// Button text to connect another profile/account
  ///
  /// In en, this message translates to:
  /// **'Connect Another Profile'**
  String get connectAnotherProfile;

  /// Toggle label for debug mode in developer settings
  ///
  /// In en, this message translates to:
  /// **'Debug mode'**
  String get rawDebugView;

  /// Subtitle for the debug mode toggle
  ///
  /// In en, this message translates to:
  /// **'Show raw message data in chat'**
  String get rawDebugViewDescription;

  /// Screen title for the debug mode screen
  ///
  /// In en, this message translates to:
  /// **'Debug Mode'**
  String get rawDebugViewTitle;

  /// Label for group ID in debug mode
  ///
  /// In en, this message translates to:
  /// **'Group ID'**
  String get rawDebugViewGroupId;

  /// Message count shown in debug mode
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No messages} =1{1 message} other{{count} messages}}'**
  String rawDebugViewMessageCount(int count);

  /// Feedback text after copying debug data
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get rawDebugViewCopied;

  /// Screen title for the in-app log viewer
  ///
  /// In en, this message translates to:
  /// **'App Logs'**
  String get appLogsTitle;

  /// Label for the view logs button in developer settings
  ///
  /// In en, this message translates to:
  /// **'View logs'**
  String get appLogsViewLogs;

  /// Subtitle for the view logs button
  ///
  /// In en, this message translates to:
  /// **'View all Logger output in app'**
  String get appLogsViewLogsDescription;

  /// Button to clear logs (legacy, use appLogsEraseAll)
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get appLogsClear;

  /// Button to erase all logs
  ///
  /// In en, this message translates to:
  /// **'Erase all'**
  String get appLogsEraseAll;

  /// Shown when log list is empty
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get appLogsEmpty;

  /// Placeholder for log search field
  ///
  /// In en, this message translates to:
  /// **'Search logs...'**
  String get appLogsSearchPlaceholder;

  /// Placeholder for adding include/exclude filter
  ///
  /// In en, this message translates to:
  /// **'Add filter pattern'**
  String get appLogsAddPatternPlaceholder;

  /// Button to add exclude filter (hide matching logs)
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get appLogsIgnore;

  /// Button to add include filter (show only matching logs)
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get appLogsShow;

  /// Button to clear all filter rules
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get appLogsClearFilters;

  /// Label on the button that resumes live log streaming
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get appLogsLive;

  /// Shown/filtered count when filters active
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total}'**
  String appLogsFilteredCount(int shown, int total);

  /// Button to copy all visible logs to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get appLogsCopyAll;

  /// Error message when relay URL doesn't start with wss:// or ws://
  ///
  /// In en, this message translates to:
  /// **'URL must start with wss:// or ws://'**
  String get invalidRelayUrlScheme;

  /// Error message when relay URL is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid relay URL'**
  String get invalidRelayUrl;

  /// Text shown inside a deleted message bubble
  ///
  /// In en, this message translates to:
  /// **'This message was deleted.'**
  String get thisMessageWasDeleted;

  /// User-friendly error when relay control state fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load relay control state. Please try again.'**
  String get relayControlStateLoadError;

  /// Report bug menu item and screen title
  ///
  /// In en, this message translates to:
  /// **'Report bug'**
  String get reportBug;

  /// Introductory description on the report bug screen
  ///
  /// In en, this message translates to:
  /// **'Help us improve White Noise by describing the issue you encountered.'**
  String get reportBugDescription;

  /// Label for the 'what went wrong' field
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get reportBugWhatWentWrong;

  /// Placeholder for the 'what went wrong' field
  ///
  /// In en, this message translates to:
  /// **'Describe the issue you experienced...'**
  String get reportBugWhatWentWrongPlaceholder;

  /// Label for the steps to reproduce field
  ///
  /// In en, this message translates to:
  /// **'Steps to reproduce'**
  String get reportBugStepsToReproduce;

  /// Placeholder for the steps to reproduce field
  ///
  /// In en, this message translates to:
  /// **'1. Go to...\n2. Tap on...\n3. See error'**
  String get reportBugStepsToReproducePlaceholder;

  /// Label for the frequency selector
  ///
  /// In en, this message translates to:
  /// **'How often does this happen?'**
  String get reportBugFrequency;

  /// Frequency option: once
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get reportBugFrequencyOnce;

  /// Frequency option: always
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get reportBugFrequencyAlways;

  /// Frequency option: sometimes
  ///
  /// In en, this message translates to:
  /// **'Sometimes'**
  String get reportBugFrequencySometimes;

  /// Toggle label for including the user's npub
  ///
  /// In en, this message translates to:
  /// **'Include your npub'**
  String get reportBugIncludeNpub;

  /// Helper text for the include npub toggle
  ///
  /// In en, this message translates to:
  /// **'Lets us follow up with you if needed; leaving this off keeps your report anonymous.'**
  String get reportBugIncludeNpubDescription;

  /// Submit button on the report bug screen
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportBugSend;

  /// Success message after sending
  ///
  /// In en, this message translates to:
  /// **'Bug report sent. Thank you!'**
  String get reportBugSuccess;

  /// Error message when sending fails
  ///
  /// In en, this message translates to:
  /// **'Failed to send report. Please try again.'**
  String get reportBugError;

  /// Validation error when 'what went wrong' is empty
  ///
  /// In en, this message translates to:
  /// **'Please describe what went wrong.'**
  String get reportBugWhatWentWrongRequired;

  /// Error notice shown when starting a DM with support account fails
  ///
  /// In en, this message translates to:
  /// **'Failed to start chat with support'**
  String get failedToStartSupportChat;

  /// Error callout title on fatal error screen
  ///
  /// In en, this message translates to:
  /// **'Oh no!'**
  String get fatalErrorTitle;

  /// Error callout description on fatal error screen
  ///
  /// In en, this message translates to:
  /// **'We hit a bump loading the app. It\'s not you, it\'s us and we\'re sorry.\n\nHelp us fix it. Tap below to send this error to our team.'**
  String get fatalErrorDescription;

  /// Button label on the fatal error screen diagnostics box to copy the error to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy error'**
  String get fatalErrorCopyError;

  /// System notice shown after copying error details to clipboard on the fatal error screen
  ///
  /// In en, this message translates to:
  /// **'Error copied to clipboard'**
  String get fatalErrorErrorCopied;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it', 'pt', 'ru', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
