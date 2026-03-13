import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:whitenoise/src/rust/api.dart' as rust_api;
import 'package:whitenoise/src/rust/api/account_groups.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/chat_list.dart';
import 'package:whitenoise/src/rust/api/drafts.dart';
import 'package:whitenoise/src/rust/api/error.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/user_search.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../test_helpers.dart' show testHexToNpub, testNpubToHex, testPubkeyA;

class MockThemeMode implements rust_api.ThemeMode {
  final String mode;
  const MockThemeMode(this.mode);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class MockLanguage implements rust_api.Language {
  final String code;
  const MockLanguage(this.code);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class MockAppSettings implements rust_api.AppSettings {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class MockWnApi implements RustLibApi {
  String currentThemeMode = 'system';
  String currentLanguage = 'system';
  bool shouldFailUpdateLanguage = false;
  bool shouldFailNpubConversion = false;
  bool shouldFailHexFromNpub = false;
  List<Account> accounts = [];
  Completer<List<Account>>? getAccountsCompleter;

  List<User> follows = [];
  KeyPackageStatus userHasKeyPackageStatus = KeyPackageStatus.valid;
  StreamController<UserSearchUpdate>? searchUsersController;

  bool sendBugReportCalled = false;
  String? lastBugReportWhatWentWrong;
  String? lastBugReportStepsToReproduce;
  String? lastBugReportFrequency;
  String? lastBugReportNpub;
  String? lastBugReportLogs;
  String? lastBugReportAppVersion;
  bool sendBugReportShouldFail = false;

  bool deleteAllDataCalled = false;
  bool deleteAllDataShouldFail = false;
  Duration deleteAllDataDelay = Duration.zero;
  Completer<void>? deleteAllDataCompleter;

  LoginResult? loginStartResult;
  LoginResult? loginExternalSignerStartResult;
  bool registerExternalSignerCalled = false;
  String relayControlStateResult = '{}';
  bool shouldFailRelayControlState = false;
  int relayControlStateCallCount = 0;

  String? lastReadMessageId;
  final List<String> markedAsReadMessages = [];
  int getAccountGroupCallCount = 0;
  bool shouldFailGetAccountGroup = false;

  Draft? loadDraftResult;
  Completer<Draft?>? loadDraftCompleter;
  int loadDraftCallCount = 0;
  bool shouldFailLoadDraft = false;
  int saveDraftCallCount = 0;
  String? lastSavedDraftContent;
  String? lastSavedDraftReplyToId;
  bool shouldFailSaveDraft = false;
  int deleteDraftCallCount = 0;
  bool shouldFailDeleteDraft = false;

  @override
  Future<KeyPackageStatus> crateApiUsersUserHasKeyPackage({
    required String pubkey,
    required bool blockingDataSync,
  }) async {
    return userHasKeyPackageStatus;
  }

  @override
  Future<AccountGroup> crateApiAccountGroupsGetAccountGroup({
    required String accountPubkey,
    required String mlsGroupId,
  }) async {
    getAccountGroupCallCount++;
    if (shouldFailGetAccountGroup) {
      throw Exception('Failed to fetch account group');
    }
    return AccountGroup(
      accountPubkey: accountPubkey,
      mlsGroupId: mlsGroupId,
      lastReadMessageId: lastReadMessageId,
      createdAt: PlatformInt64Util.from(0),
      updatedAt: PlatformInt64Util.from(0),
    );
  }

  @override
  Future<AccountGroup> crateApiAccountGroupsMarkMessageRead({
    required String accountPubkey,
    required String messageId,
  }) async {
    markedAsReadMessages.add(messageId);
    lastReadMessageId = messageId;
    return AccountGroup(
      accountPubkey: accountPubkey,
      mlsGroupId: 'mock_group',
      lastReadMessageId: messageId,
      createdAt: PlatformInt64Util.from(0),
      updatedAt: PlatformInt64Util.from(0),
    );
  }

  @override
  Future<List<User>> crateApiAccountsAccountFollows({required String pubkey}) async {
    return follows;
  }

  @override
  Future<void> crateApiAccountsFollowUser({
    required String accountPubkey,
    required String userToFollowPubkey,
  }) async {}

  @override
  Future<void> crateApiAccountsUnfollowUser({
    required String accountPubkey,
    required String userToUnfollowPubkey,
  }) async {}

  @override
  Future<bool> crateApiAccountsIsFollowingUser({
    required String accountPubkey,
    required String userPubkey,
  }) async {
    return follows.any((user) => user.pubkey == userPubkey);
  }

  @override
  Stream<UserSearchUpdate> crateApiUserSearchSearchUsers({
    required String accountPubkey,
    required String query,
    required int radiusStart,
    required int radiusEnd,
  }) {
    searchUsersController?.close();
    searchUsersController = StreamController<UserSearchUpdate>(sync: true);
    return searchUsersController!.stream;
  }

  @override
  String crateApiUtilsNpubFromHexPubkey({required String hexPubkey}) {
    if (shouldFailNpubConversion) {
      throw Exception('Invalid hex pubkey');
    }
    final npub = testHexToNpub[hexPubkey];
    if (npub == null) throw Exception('Unknown hex pubkey: $hexPubkey');
    return npub;
  }

  @override
  String crateApiUtilsHexPubkeyFromNpub({required String npub}) {
    if (shouldFailHexFromNpub) {
      throw Exception('Invalid npub');
    }
    final hex = testNpubToHex[npub];
    if (hex == null) throw Exception('Unknown npub: $npub');
    return hex;
  }

  @override
  Future<String> crateApiRelaysDebugRelayControlState() async {
    relayControlStateCallCount++;
    if (shouldFailRelayControlState) {
      throw Exception('relay control dump failed');
    }
    return relayControlStateResult;
  }

  @override
  Future<List<ChatMessage>> crateApiMessagesFetchAggregatedMessagesForGroup({
    required String pubkey,
    required String groupId,
  }) async {
    return [];
  }

  @override
  Future<bool> crateApiGroupsGroupIsDirectMessageType({
    required Group that,
    required String accountPubkey,
  }) async {
    return false;
  }

  @override
  Future<String?> crateApiGroupsGetGroupImagePath({
    required String accountPubkey,
    required String groupId,
  }) async {
    return null;
  }

  @override
  Future<RatchetTreeInfo> crateApiGroupsGetRatchetTreeInfo({
    required String accountPubkey,
    required String groupId,
  }) async {
    return RatchetTreeInfo(
      treeHash: 'a' * 64,
      serializedTree: 'deadbeef',
      leafNodes: [
        LeafNodeInfo(
          index: 0,
          encryptionKey: 'b' * 64,
          signatureKey: 'c' * 64,
          credentialIdentity: testPubkeyA,
        ),
      ],
    );
  }

  @override
  Stream<MessageStreamItem> crateApiMessagesSubscribeToGroupMessages({
    required String groupId,
  }) {
    return Stream.value(const MessageStreamItem.initialSnapshot(messages: []));
  }

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async {
    return FlutterMetadata(
      name: 'User $pubkey',
      displayName: 'Display $pubkey',
      custom: {},
    );
  }

  @override
  Future<List<ChatSummary>> crateApiChatListGetChatList({
    required String accountPubkey,
  }) async {
    return [];
  }

  @override
  Future<String?> crateApiAccountGroupsGetDmGroupWithPeer({
    required String accountPubkey,
    required String peerPubkey,
  }) async {
    return null;
  }

  @override
  Stream<ChatListStreamItem> crateApiChatListSubscribeToChatList({
    required String accountPubkey,
  }) {
    return Stream.value(const ChatListStreamItem.initialSnapshot(items: []));
  }

  @override
  Future<List<String>> crateApiGroupsGroupMembers({
    required String pubkey,
    required String groupId,
  }) async => [];

  @override
  Future<void> crateApiAccountsLogout({required String pubkey}) async {}

  @override
  Future<List<Account>> crateApiAccountsGetAccounts() async {
    if (getAccountsCompleter != null) {
      return getAccountsCompleter!.future;
    }
    return accounts;
  }

  @override
  Future<Account> crateApiAccountsGetAccount({required String pubkey}) async {
    final accountList = getAccountsCompleter != null
        ? await getAccountsCompleter!.future
        : accounts;
    return accountList.firstWhere(
      (a) => a.pubkey == pubkey,
      orElse: () => throw const ApiError.whitenoise(message: 'Account not found'),
    );
  }

  @override
  Future<String> crateApiUtilsGetDefaultBlossomServerUrl() async => 'https://blossom.example.com';

  @override
  Future<void> crateApiAccountsUpdateAccountMetadata({
    required String pubkey,
    required FlutterMetadata metadata,
  }) async {}

  @override
  rust_api.ThemeMode crateApiUtilsThemeModeLight() => const MockThemeMode('light');

  @override
  rust_api.ThemeMode crateApiUtilsThemeModeDark() => const MockThemeMode('dark');

  @override
  rust_api.ThemeMode crateApiUtilsThemeModeSystem() => const MockThemeMode('system');

  @override
  String crateApiUtilsThemeModeToString({required rust_api.ThemeMode themeMode}) {
    if (themeMode is MockThemeMode) {
      return themeMode.mode;
    }
    return 'system';
  }

  @override
  Future<rust_api.AppSettings> crateApiGetAppSettings() async {
    return MockAppSettings();
  }

  @override
  Future<rust_api.ThemeMode> crateApiAppSettingsThemeMode({
    required rust_api.AppSettings appSettings,
  }) async {
    return MockThemeMode(currentThemeMode);
  }

  @override
  Future<void> crateApiUpdateThemeMode({
    required rust_api.ThemeMode themeMode,
  }) async {
    if (themeMode is MockThemeMode) {
      currentThemeMode = themeMode.mode;
    }
  }

  @override
  rust_api.Language crateApiUtilsLanguageEnglish() => const MockLanguage('en');

  @override
  rust_api.Language crateApiUtilsLanguageSpanish() => const MockLanguage('es');

  @override
  rust_api.Language crateApiUtilsLanguageFrench() => const MockLanguage('fr');

  @override
  rust_api.Language crateApiUtilsLanguageGerman() => const MockLanguage('de');

  @override
  rust_api.Language crateApiUtilsLanguageItalian() => const MockLanguage('it');

  @override
  rust_api.Language crateApiUtilsLanguagePortuguese() => const MockLanguage('pt');

  @override
  rust_api.Language crateApiUtilsLanguageRussian() => const MockLanguage('ru');

  @override
  rust_api.Language crateApiUtilsLanguageTurkish() => const MockLanguage('tr');

  @override
  rust_api.Language crateApiUtilsLanguageSystem() => const MockLanguage('system');

  @override
  String crateApiUtilsLanguageToString({required rust_api.Language language}) {
    if (language is MockLanguage) {
      return language.code;
    }
    return 'en';
  }

  @override
  Future<rust_api.Language> crateApiAppSettingsLanguage({
    required rust_api.AppSettings appSettings,
  }) async {
    return MockLanguage(currentLanguage);
  }

  @override
  Future<void> crateApiUpdateLanguage({
    required rust_api.Language language,
  }) async {
    if (shouldFailUpdateLanguage) {
      throw Exception('Failed to update language');
    }
    if (language is MockLanguage) {
      currentLanguage = language.code;
    }
  }

  @override
  Future<void> crateApiDeleteAllData() async {
    deleteAllDataCalled = true;
    if (deleteAllDataCompleter != null) {
      await deleteAllDataCompleter!.future;
    }
    if (deleteAllDataDelay > Duration.zero) {
      await Future.delayed(deleteAllDataDelay);
    }
    if (deleteAllDataShouldFail) {
      throw Exception('Failed to delete all data');
    }
  }

  @override
  Future<LoginResult> crateApiAccountsLoginStart({
    required String nsecOrHexPrivkey,
  }) async {
    if (loginStartResult != null) return loginStartResult!;
    return LoginResult(
      account: Account(
        pubkey: testPubkeyA,
        accountType: AccountType.local,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: LoginStatus.complete,
    );
  }

  @override
  Future<LoginResult> crateApiAccountsLoginPublishDefaultRelays({
    required String pubkey,
  }) async {
    return LoginResult(
      account: Account(
        pubkey: pubkey,
        accountType: AccountType.local,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: LoginStatus.complete,
    );
  }

  @override
  Future<LoginResult> crateApiAccountsLoginWithCustomRelay({
    required String pubkey,
    required String relayUrl,
  }) async {
    return LoginResult(
      account: Account(
        pubkey: pubkey,
        accountType: AccountType.local,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: LoginStatus.complete,
    );
  }

  @override
  Future<void> crateApiAccountsLoginCancel({required String pubkey}) async {}

  @override
  Future<LoginResult> crateApiSignerLoginExternalSignerStart({
    required String pubkey,
    required FutureOr<String> Function(String) signEvent,
    required FutureOr<String> Function(String, String) nip04Encrypt,
    required FutureOr<String> Function(String, String) nip04Decrypt,
    required FutureOr<String> Function(String, String) nip44Encrypt,
    required FutureOr<String> Function(String, String) nip44Decrypt,
  }) async {
    if (loginExternalSignerStartResult != null) return loginExternalSignerStartResult!;
    return LoginResult(
      account: Account(
        pubkey: pubkey,
        accountType: AccountType.external_,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: LoginStatus.complete,
    );
  }

  @override
  Future<LoginResult> crateApiSignerLoginExternalSignerPublishDefaultRelays({
    required String pubkey,
  }) async {
    return LoginResult(
      account: Account(
        pubkey: pubkey,
        accountType: AccountType.external_,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: LoginStatus.complete,
    );
  }

  @override
  Future<LoginResult> crateApiSignerLoginExternalSignerWithCustomRelay({
    required String pubkey,
    required String relayUrl,
  }) async {
    return LoginResult(
      account: Account(
        pubkey: pubkey,
        accountType: AccountType.external_,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: LoginStatus.complete,
    );
  }

  @override
  Future<void> crateApiSignerRegisterExternalSigner({
    required String pubkey,
    required FutureOr<String> Function(String) signEvent,
    required FutureOr<String> Function(String, String) nip04Encrypt,
    required FutureOr<String> Function(String, String) nip04Decrypt,
    required FutureOr<String> Function(String, String) nip44Encrypt,
    required FutureOr<String> Function(String, String) nip44Decrypt,
  }) async {
    registerExternalSignerCalled = true;
  }

  @override
  Future<Draft?> crateApiDraftsLoadDraft({
    required String pubkey,
    required String groupId,
  }) async {
    loadDraftCallCount++;
    if (shouldFailLoadDraft) throw Exception('loadDraft failed');
    if (loadDraftCompleter != null) return loadDraftCompleter!.future;
    return loadDraftResult;
  }

  @override
  Future<Draft> crateApiDraftsSaveDraft({
    required String pubkey,
    required String groupId,
    required String content,
    String? replyToId,
    required List<MediaFile> mediaAttachments,
  }) async {
    saveDraftCallCount++;
    if (shouldFailSaveDraft) throw Exception('saveDraft failed');
    lastSavedDraftContent = content;
    lastSavedDraftReplyToId = replyToId;
    return Draft(
      accountPubkey: pubkey,
      mlsGroupId: groupId,
      content: content,
      replyToId: replyToId,
      mediaAttachments: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> crateApiDraftsDeleteDraft({
    required String pubkey,
    required String groupId,
  }) async {
    deleteDraftCallCount++;
    if (shouldFailDeleteDraft) throw Exception('deleteDraft failed');
  }

  @override
  Future<void> crateApiBugReportSendBugReport({
    required String whatWentWrong,
    String? expectedBehavior,
    String? stepsToReproduce,
    String? frequency,
    String? npub,
    String? logs,
    required String appVersion,
    required String platform,
    required String osVersion,
  }) async {
    sendBugReportCalled = true;
    lastBugReportWhatWentWrong = whatWentWrong;
    lastBugReportStepsToReproduce = stepsToReproduce;
    lastBugReportFrequency = frequency;
    lastBugReportNpub = npub;
    lastBugReportLogs = logs;
    lastBugReportAppVersion = appVersion;
    if (sendBugReportShouldFail) throw Exception('send_bug_report failed');
  }

  void reset() {
    sendBugReportCalled = false;
    lastBugReportWhatWentWrong = null;
    lastBugReportStepsToReproduce = null;
    lastBugReportFrequency = null;
    lastBugReportNpub = null;
    lastBugReportLogs = null;
    lastBugReportAppVersion = null;
    sendBugReportShouldFail = false;
    currentThemeMode = 'system';
    currentLanguage = 'system';
    shouldFailUpdateLanguage = false;
    shouldFailNpubConversion = false;
    shouldFailHexFromNpub = false;
    accounts = [];
    follows = [];
    getAccountsCompleter = null;
    userHasKeyPackageStatus = KeyPackageStatus.valid;
    searchUsersController?.close();
    searchUsersController = null;
    deleteAllDataCalled = false;
    deleteAllDataShouldFail = false;
    deleteAllDataDelay = Duration.zero;
    deleteAllDataCompleter = null;
    loginStartResult = null;
    loginExternalSignerStartResult = null;
    registerExternalSignerCalled = false;
    relayControlStateResult = '{}';
    shouldFailRelayControlState = false;
    relayControlStateCallCount = 0;
    lastReadMessageId = null;
    markedAsReadMessages.clear();
    getAccountGroupCallCount = 0;
    shouldFailGetAccountGroup = false;
    loadDraftResult = null;
    loadDraftCompleter = null;
    loadDraftCallCount = 0;
    shouldFailLoadDraft = false;
    saveDraftCallCount = 0;
    lastSavedDraftContent = null;
    lastSavedDraftReplyToId = null;
    shouldFailSaveDraft = false;
    deleteDraftCallCount = 0;
    shouldFailDeleteDraft = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
