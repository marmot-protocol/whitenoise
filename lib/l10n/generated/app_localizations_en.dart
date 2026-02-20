// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'White Noise';

  @override
  String get sloganDecentralized => 'Decentralized';

  @override
  String get sloganUncensorable => 'Uncensorable';

  @override
  String get sloganSecureMessaging => 'Secure Messaging';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get loginTitle => 'Login';

  @override
  String get enterPrivateKey => 'Enter your private key';

  @override
  String get nsecPlaceholder => 'nsec...';

  @override
  String get setupProfile => 'Setup profile';

  @override
  String get chooseName => 'Choose a name';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get introduceYourself => 'Introduce yourself';

  @override
  String get writeSomethingAboutYourself => 'Write something about yourself';

  @override
  String get cancel => 'Cancel';

  @override
  String get profileReady => 'Your profile is ready!';

  @override
  String get startConversationHint =>
      'Start a conversation by adding friends or sharing your profile.';

  @override
  String get shareYourProfile => 'Share your profile';

  @override
  String get startChat => 'Start a chat';

  @override
  String get settings => 'Settings';

  @override
  String get shareAndConnect => 'Share & connect';

  @override
  String get switchProfile => 'Switch profile';

  @override
  String get addNewProfile => 'Add a new profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get profileKeys => 'Profile keys';

  @override
  String get networkRelays => 'Network relays';

  @override
  String get appearance => 'Appearance';

  @override
  String get privacySecurity => 'Privacy & security';

  @override
  String get donateToWhiteNoise => 'Donate to White Noise';

  @override
  String get developerSettings => 'Developer settings';

  @override
  String get signOut => 'Sign out';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get privacySecurityTitle => 'Privacy & security';

  @override
  String get deleteAllAppData => 'Delete All App Data';

  @override
  String get deleteAppData => 'Delete app data';

  @override
  String get deleteAllAppDataDescription =>
      'Erase every profile, key, chat, and local file from this device.';

  @override
  String get deleteAllAppDataConfirmation => 'Delete all app data?';

  @override
  String get deleteAllAppDataWarning =>
      'This will erase every profile, key, chat, and local file from this device. This cannot be undone.';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get profileKeysTitle => 'Profile keys';

  @override
  String get publicKey => 'Public key';

  @override
  String get publicKeyCopied => 'Public key copied to clipboard';

  @override
  String get publicKeyDescription =>
      'Your public key is your identifier on Nostr. Share it so others can find, recognize, and connect with you.';

  @override
  String get privateKey => 'Private Key';

  @override
  String get privateKeyCopied => 'Private key copied to clipboard';

  @override
  String get privateKeyDescription =>
      'Your private key works like a secret password that grants access to your Nostr identity.';

  @override
  String get keepPrivateKeySecure => 'Keep your private key safe!';

  @override
  String get privateKeyWarning =>
      'Don\'t share your private key publicly, and use it only to log in to other Nostr apps.';

  @override
  String get nsecOnExternalSigner => 'Private key is stored in external signer';

  @override
  String get nsecOnExternalSignerDescription =>
      'Your private key isn\'t available in White Noise. Open your signer to view or manage it.';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get profileName => 'Profile name';

  @override
  String get nostrAddress => 'Nostr address';

  @override
  String get nostrAddressPlaceholder => 'example@whitenoise.chat';

  @override
  String get aboutYou => 'About you';

  @override
  String get profileIsPublic => 'Profile is public';

  @override
  String get profilePublicDescription =>
      'Your profile information will be visible to everyone on the network.';

  @override
  String get discard => 'Discard';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String get save => 'Save';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String errorLoadingProfile(String error) {
    return 'Error loading profile: $error';
  }

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String get profileLoadError => 'Unable to load profile. Please try again.';

  @override
  String get failedToLoadPrivateKey => 'Could not load private key. Please try again.';

  @override
  String get profileSaveError => 'Unable to save profile. Please try again.';

  @override
  String get networkRelaysTitle => 'Network Relays';

  @override
  String get myRelays => 'My Relays';

  @override
  String get myRelaysHelp => 'Relays you have defined for use across all your Nostr applications.';

  @override
  String get inboxRelays => 'Inbox Relays';

  @override
  String get inboxRelaysHelp =>
      'Relays used to receive invitations and start secure conversations with new users.';

  @override
  String get keyPackageRelays => 'Key Package Relays';

  @override
  String get keyPackageRelaysHelp =>
      'Relays that store your secure key so others can invite you to encrypted conversations.';

  @override
  String get errorLoadingRelays => 'Error loading relays';

  @override
  String get noRelaysConfigured => 'No relays configured';

  @override
  String get donateTitle => 'Donate to White Noise';

  @override
  String get donateDescription =>
      'As a not-for-profit, White Noise exists solely for your privacy and freedom, not for profit. Your support keeps us independent and uncompromised.';

  @override
  String get lightningAddress => 'Lightning Address';

  @override
  String get bitcoinSilentPayment => 'Bitcoin Silent Payment';

  @override
  String get copiedToClipboardThankYou => 'Copied to clipboard. Thank you!';

  @override
  String get shareProfileTitle => 'Share profile';

  @override
  String get scanToConnect => 'Scan to connect';

  @override
  String get signOutTitle => 'Sign out';

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out?';

  @override
  String get signOutWarning =>
      'When you sign out of White Noise, your chats will be deleted from this device and cannot be restored on another device.';

  @override
  String get signOutWarningBackupKey =>
      'If you haven\'t backed up your private key, you won\'t be able to use this profile on any other Nostr service.';

  @override
  String get backUpPrivateKey => 'Back up your private key';

  @override
  String get copyPrivateKeyHint =>
      'Copy your private key to restore your account on another device.';

  @override
  String get publicKeyCopyError => 'Failed to copy public key. Please try again.';

  @override
  String get noChatsYet => 'No chats yet';

  @override
  String get startConversation => 'Start a conversation';

  @override
  String get welcomeNoticeTitle => 'Your profile is ready';

  @override
  String welcomeNoticeDescription(String findPeople, String shareProfile, String startANewChat) {
    return 'Tap $findPeople to find your friends. $shareProfile to connect with people you know, or $startANewChat using the chat plus icon.';
  }

  @override
  String get findPeople => 'Find people';

  @override
  String get startANewChat => 'start a new chat';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get messagePlaceholder => 'Message';

  @override
  String get failedToSendMessage => 'Failed to send message. Please try again.';

  @override
  String get invitedToSecureChat => 'You are invited to a secure chat';

  @override
  String get decline => 'Decline';

  @override
  String get accept => 'Accept';

  @override
  String failedToAcceptInvitation(String error) {
    return 'Failed to accept invitation: $error';
  }

  @override
  String failedToDeclineInvitation(String error) {
    return 'Failed to decline invitation: $error';
  }

  @override
  String get startNewChat => 'Start new chat';

  @override
  String get noResults => 'No results';

  @override
  String get noFollowsYet => 'No follows yet';

  @override
  String get searchByNameOrNpub => 'Name or npub1...';

  @override
  String get developerSettingsTitle => 'Developer Settings';

  @override
  String get publishNewKeyPackage => 'Publish New Key Package';

  @override
  String get refreshKeyPackages => 'Refresh Key Packages';

  @override
  String get deleteAllKeyPackages => 'Delete All Key Packages';

  @override
  String keyPackagesCount(int count) {
    return 'Key Packages ($count)';
  }

  @override
  String get noKeyPackagesFound => 'No key packages found';

  @override
  String get keyPackagePublished => 'Key package published';

  @override
  String get keyPackagesRefreshed => 'Key packages refreshed';

  @override
  String get keyPackagesDeleted => 'All key packages deleted';

  @override
  String get keyPackageDeleted => 'Key package deleted';

  @override
  String packageNumber(int number) {
    return 'Package $number';
  }

  @override
  String get goBack => 'Go back';

  @override
  String get createGroup => 'Create group';

  @override
  String get newGroupChat => 'New group chat';

  @override
  String get selectMembers => 'Select Members';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get clearSelection => 'Clear';

  @override
  String get continueButton => 'Continue';

  @override
  String get setUpGroup => 'Set up group';

  @override
  String get groupName => 'Group Name';

  @override
  String get groupNamePlaceholder => 'Enter group name';

  @override
  String get groupDescription => 'Group Description';

  @override
  String get description => 'Description';

  @override
  String get groupDescriptionPlaceholder => 'What is this group for?';

  @override
  String members(int count) {
    return '$count members';
  }

  @override
  String invitingMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Inviting members:',
      one: 'Inviting member:',
    );
    return '$_temp0';
  }

  @override
  String get usersWithoutKeyPackages => 'Users without key packages (cannot be added)';

  @override
  String usersNotOnWhiteNoise(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'These users are not on White Noise',
      one: 'This user is not on White Noise',
    );
    return '$_temp0';
  }

  @override
  String usersNotOnWhiteNoiseDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'These users cannot be added to the group because they don\'t have White Noise installed or haven\'t published their key packages yet.',
      one:
          'This user cannot be added to the group because they don\'t have White Noise installed or haven\'t published their key package yet.',
    );
    return '$_temp0';
  }

  @override
  String get uploadingImage => 'Uploading image...';

  @override
  String get creatingGroup => 'Creating group...';

  @override
  String get groupNameRequired => 'Group name is required';

  @override
  String get noUsersWithKeyPackages => 'No users with key packages to add';

  @override
  String get createGroupFailed => 'Failed to create group';

  @override
  String get reportError => 'Report error';

  @override
  String get workInProgress => 'We\'re working on this';

  @override
  String get wipMessage =>
      'We\'re working on this feature. To support development, please donate to White Noise';

  @override
  String get donate => 'Donate';

  @override
  String get addRelay => 'Add Relay';

  @override
  String get enterRelayAddress => 'Enter relay address';

  @override
  String get relayAddressPlaceholder => 'wss://relay.example.com';

  @override
  String get removeRelay => 'Remove Relay?';

  @override
  String get removeRelayConfirmation =>
      'Are you sure you want to remove this relay? This action cannot be undone.';

  @override
  String get remove => 'Remove';

  @override
  String get messageActions => 'Message actions';

  @override
  String get reply => 'Reply';

  @override
  String get copyMessage => 'Copy';

  @override
  String get delete => 'Delete';

  @override
  String get failedToDeleteMessage => 'Failed to delete message. Please try again.';

  @override
  String get failedToSendReaction => 'Failed to send reaction. Please try again.';

  @override
  String get failedToRemoveReaction => 'Failed to remove reaction. Please try again.';

  @override
  String get unknownUser => 'Unknown user';

  @override
  String get unknownGroup => 'Unknown group';

  @override
  String get hasInvitedYouToSecureChat => 'Has invited you to a secure chat';

  @override
  String userInvitedYouToSecureChat(String name) {
    return '$name has invited you to a secure chat';
  }

  @override
  String get youHaveBeenInvitedToSecureChat => 'You have been invited to a secure chat';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageUpdateFailed => 'Failed to save language preference. Please try again.';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String get profile => 'Profile';

  @override
  String get follow => 'Follow';

  @override
  String get unfollow => 'Unfollow';

  @override
  String get failedToStartChat => 'Failed to start chat. Please try again.';

  @override
  String get inviteToWhiteNoise => 'Invite to White Noise';

  @override
  String inviteToWhiteNoiseDescription(String name) {
    return '$name isn\'t on White Noise yet. Share the app to start a secure chat.';
  }

  @override
  String get failedToUpdateFollow => 'Failed to update follow status. Please try again.';

  @override
  String get imagePickerError => 'Failed to pick image. Please try again.';

  @override
  String get scanNsec => 'Scan QR code';

  @override
  String get scanNsecHint => 'Scan your private key QR code to login.';

  @override
  String get cameraPermissionDenied => 'Camera permission denied';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get scanNpub => 'Scan QR code';

  @override
  String get scanNpubHint => 'Scan a contact\'s QR code.';

  @override
  String get invalidNpub => 'Invalid public key. Please try again.';

  @override
  String get you => 'You';

  @override
  String get timestampNow => 'Now';

  @override
  String timestampMinutes(int count) {
    return '${count}m';
  }

  @override
  String timestampHours(int count) {
    return '${count}h';
  }

  @override
  String get timestampYesterday => 'Yesterday';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get monthJanShort => 'Jan';

  @override
  String get monthFebShort => 'Feb';

  @override
  String get monthMarShort => 'Mar';

  @override
  String get monthAprShort => 'Apr';

  @override
  String get monthMayShort => 'May';

  @override
  String get monthJunShort => 'Jun';

  @override
  String get monthJulShort => 'Jul';

  @override
  String get monthAugShort => 'Aug';

  @override
  String get monthSepShort => 'Sep';

  @override
  String get monthOctShort => 'Oct';

  @override
  String get monthNovShort => 'Nov';

  @override
  String get monthDecShort => 'Dec';

  @override
  String get loginWithAmber => 'Login with Amber';

  @override
  String get signerConnectionError => 'Unable to connect to signer. Please try again.';

  @override
  String get search => 'Search';

  @override
  String get filterChats => 'Chats';

  @override
  String get filterArchive => 'Archive';

  @override
  String get signerErrorUserRejected => 'Login cancelled';

  @override
  String get signerErrorNotConnected => 'Not connected to signer. Please try again.';

  @override
  String get signerErrorNoSigner =>
      'No signer app found. Please install a NIP-55 compatible signer.';

  @override
  String get signerErrorNoResponse => 'No response from signer. Please try again.';

  @override
  String get signerErrorNoPubkey => 'Unable to get public key from signer.';

  @override
  String get signerErrorNoResult => 'Signer did not return a result.';

  @override
  String get signerErrorNoEvent => 'Signer did not return a signed event.';

  @override
  String get signerErrorRequestInProgress => 'Another request is in progress. Please wait.';

  @override
  String get signerErrorNoActivity => 'Unable to launch signer. Please try again.';

  @override
  String get signerErrorLaunchError => 'Failed to launch signer app.';

  @override
  String get signerErrorUnknown => 'An error occurred with the signer. Please try again.';

  @override
  String get messageNotFound => 'Message not found';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get mute => 'Mute';

  @override
  String get archive => 'Archive';

  @override
  String get failedToPinChat => 'Failed to update pin. Please try again.';

  @override
  String get carouselPrivacyTitle => 'Privacy and security';

  @override
  String get carouselPrivacyDescription =>
      'Keep your conversations private. Even in case of a breach, your messages remain secure.';

  @override
  String get carouselIdentityTitle => 'Choose your identity';

  @override
  String get carouselIdentityDescription =>
      'Chat without revealing your phone number or email. Choose your identity: real name, pseudonym, or anonymous.';

  @override
  String get carouselDecentralizedTitle => 'Decentralized and permissionless';

  @override
  String get carouselDecentralizedDescription =>
      'No central authority controls your communication-no permissions needed, no censorship possible.';

  @override
  String get learnMore => 'Learn more';

  @override
  String get backToSignUp => 'Back to sign up';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get deleteAllDataConfirmation => 'Delete all data?';

  @override
  String get deleteAllDataWarning =>
      'This will permanently delete all your chats, messages, and settings from this device. This action cannot be undone.';

  @override
  String get deleteAllDataError => 'Failed to delete all data. Please try again.';

  @override
  String get chatInformation => 'Chat Information';

  @override
  String get addAsContact => 'Add as contact';

  @override
  String get removeAsContact => 'Remove as contact';

  @override
  String get addToGroup => 'Add to group';

  @override
  String get addToAnotherGroup => 'Add to another group';

  @override
  String get relayResolutionTitle => 'Relay Setup';

  @override
  String get relayResolutionDescription =>
      'We couldn\'t find your relay lists on the network. You can provide a relay where your lists are published, or use our default relays to get started.';

  @override
  String get relayResolutionUseDefaults => 'Use default relays';

  @override
  String get relayResolutionTryRelay => 'Search relay';

  @override
  String get relayResolutionRelayPlaceholder => 'wss://relay.example.com';

  @override
  String get relayResolutionRelayLabel => 'Relay URL';

  @override
  String get relayResolutionNotFound =>
      'No relay lists found on this relay. Try another or use defaults.';

  @override
  String get loginErrorInvalidKey => 'Invalid private key format. Please check and try again.';

  @override
  String get loginErrorNoRelayConnections =>
      'Could not connect to any relays. Please check your connection and try again.';

  @override
  String get loginErrorTimeout => 'Login timed out. Please try again.';

  @override
  String get loginErrorGeneric => 'An error occurred during login. Please try again.';

  @override
  String get loginErrorNoLoginInProgress => 'No login in progress. Please start over.';

  @override
  String get loginErrorInternal => 'An internal error occurred. Please try again.';

  @override
  String get loginPasteNothingToPaste => 'Nothing to paste';

  @override
  String get loginPasteFailed => 'Failed to paste from clipboard';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get scannerError => 'Scanner error';

  @override
  String get scannerErrorDescription => 'Something went wrong with the scanner. Please try again.';

  @override
  String get cameraPermissionDeniedDescription =>
      'Please enable camera access in your device settings to scan QR codes.';

  @override
  String get retry => 'Retry';

  @override
  String get groupInformation => 'Group Information';

  @override
  String get editGroup => 'Edit Group';

  @override
  String get editGroupAction => 'Edit group';

  @override
  String get groupNameLabel => 'Name';

  @override
  String get groupDescriptionLabel => 'About';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Members',
      one: '1 Member',
    );
    return '$_temp0';
  }

  @override
  String get adminBadge => 'Admin';

  @override
  String get membersLabel => 'Members:';

  @override
  String get memberBadge => 'Member';

  @override
  String get sendMessage => 'Send message';

  @override
  String get makeAdmin => 'Make admin';

  @override
  String get removeAdminRole => 'Remove admin';

  @override
  String get removeFromGroup => 'Remove from group';

  @override
  String get removeFromGroupConfirmation => 'Remove from group?';

  @override
  String get removeFromGroupWarning =>
      'This member will be removed from the group and will no longer be able to see new messages.';

  @override
  String get makeAdminConfirmation => 'Make admin?';

  @override
  String get makeAdminWarning =>
      'This member will be able to manage the group, add or remove members, and change group settings.';

  @override
  String get removeAdminConfirmation => 'Remove admin?';

  @override
  String get removeAdminWarning =>
      'This member will no longer be able to manage the group, add or remove members, or change group settings.';

  @override
  String get failedToRemoveFromGroup => 'Failed to remove member. Please try again.';

  @override
  String get failedToMakeAdmin => 'Failed to make admin. Please try again.';

  @override
  String get failedToRemoveAdmin => 'Failed to remove admin. Please try again.';

  @override
  String get groupUpdatedSuccessfully => 'Group updated successfully';

  @override
  String get groupLoadError => 'Unable to load group. Please try again.';

  @override
  String get groupSaveError => 'Unable to save group. Please try again.';

  @override
  String get failedToFetchGroupMembers => 'Failed to load group members. Please try again.';

  @override
  String get failedToAddMembers => 'Failed to add members. Please try again.';

  @override
  String get userNeedsUpdate => 'Key update needed';

  @override
  String userNeedsUpdateDescription(String name) {
    return 'You can\'t start a secure chat with $name yet. They need to update White Noise before secure messaging works.';
  }

  @override
  String addToGroupConfirmation(String userName, String groupName) {
    return 'Add $userName to $groupName?';
  }

  @override
  String get unknownInviteToWhiteNoiseDescription =>
      'This user isn\'t on White Noise yet. Share the app to start a secure chat.';

  @override
  String get unknownUserNeedsUpdateDescription =>
      'You can\'t start a secure chat with this user yet. They need to update White Noise before secure messaging works.';

  @override
  String get add => 'Add';

  @override
  String get noGroupsAvailable => 'No groups available';

  @override
  String get noAdminGroupsAvailable =>
      'You\'re not an admin in any groups yet. Create a group to add people.';
}
