import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:whitenoise/main.dart' show WnApp;
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/message_debug_log_provider.dart';
import 'package:whitenoise/providers/offline_provider.dart';
import 'package:whitenoise/src/rust/api.dart' as rust_api;
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/utils/encoding.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';

import '../test/mocks/mock_secure_storage.dart';

const _firstDisplayName = 'Integration Alice';
const _secondDisplayName = 'Integration Bob';
const _groupName = 'Integration Test Group';
const _initialMessage = 'Hello, testing initial message';
const _secondMessage = 'Hello, testing second message';
const _relayUrls = ['ws://localhost:8080', 'ws://localhost:7777'];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('two identities exchange messages through a group invite', (
    tester,
  ) async {
    await _expectLocalRelaysAvailable();
    final container = await _mountApp(tester);

    final firstPubkey = await _createIdentity(
      tester,
      container,
      _firstDisplayName,
    );
    await _createAdditionalIdentity(tester, container, _secondDisplayName);
    final activeSecondPubkey = container.read(authProvider).value;
    expect(activeSecondPubkey, isNotNull);
    final secondPubkey = activeSecondPubkey!;

    await _switchProfile(tester, firstPubkey);
    final firstNpub = await _copyPublicKey(tester);
    expect(hexFromNpub(firstNpub), firstPubkey);

    await _switchProfile(tester, secondPubkey);
    await _startGroupChat(
      tester,
      inviteeNpub: firstNpub,
      inviteePubkey: firstPubkey,
    );
    await _sendMessage(tester, container, _initialMessage);
    await _expectMessageVisible(tester, _initialMessage);

    await _returnToChatList(tester);
    await _switchProfile(tester, firstPubkey);
    await _openInvite(tester);
    await _expectMessageVisible(tester, _initialMessage);
    await _tapKey(
      tester,
      const Key('chat_invite_accept_button'),
      timeout: const Duration(seconds: 60),
    );
    await _waitForChatReady(tester, timeout: const Duration(seconds: 60));
    await _sendMessage(tester, container, _secondMessage);
    await _expectMessageVisible(tester, _secondMessage);

    await _returnToChatList(tester);
    await _switchProfile(tester, secondPubkey);
    await _openChat(tester);
    await _expectMessageVisible(tester, _secondMessage);
  });
}

Future<ProviderContainer> _mountApp(WidgetTester tester) async {
  await RustLib.init();

  final root = await Directory.systemTemp.createTemp('whitenoise_integration_');
  addTearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  final dataDir = Directory('${root.path}/data');
  final logsDir = Directory('${root.path}/logs');
  await dataDir.create(recursive: true);
  await logsDir.create(recursive: true);
  final config = await rust_api.createWhitenoiseConfig(
    dataDir: dataDir.path,
    logsDir: logsDir.path,
    defaultRelayUrls: _relayUrls,
  );
  await rust_api.initializeWhitenoise(config: config);

  final container = ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(MockSecureStorage()),
      checkConnectivityFunctionProvider.overrideWithValue(
        () async => [ConnectivityResult.wifi],
      ),
      connectivityStreamProvider.overrideWithValue(const Stream.empty()),
      reachAnyRelayHostFunctionProvider.overrideWithValue((_) async => true),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const WnApp()),
  );
  await _pumpUntilFound(tester, find.byKey(const Key('auth_signup_button')));
  return container;
}

Future<String> _createIdentity(
  WidgetTester tester,
  ProviderContainer container,
  String displayName,
) async {
  await _tapKey(tester, const Key('auth_signup_button'));
  await _enterTextInWidget(
    tester,
    const Key('signup_display_name_field'),
    displayName,
  );
  await _tapKey(tester, const Key('signup_create_profile_button'));
  await _pumpUntilFound(
    tester,
    find.byKey(const Key('chat_add_button')),
    timeout: const Duration(seconds: 90),
  );
  final pubkey = container.read(authProvider).value;
  expect(pubkey, isNotNull);
  return pubkey!;
}

Future<String> _createAdditionalIdentity(
  WidgetTester tester,
  ProviderContainer container,
  String displayName,
) async {
  await _returnToChatList(tester);
  await _openSettings(tester);
  await _tapKey(tester, const Key('settings_switch_profile_button'));
  await _tapKey(tester, const Key('connect_another_profile_button'));
  return _createIdentity(tester, container, displayName);
}

Future<String> _copyPublicKey(WidgetTester tester) async {
  await _returnToChatList(tester);
  await _openSettings(tester);
  await _tapKey(tester, const Key('settings_profile_keys_menu_item'));
  final publicKeyField = find.byKey(const Key('profile_keys_public_key_field'));
  await _pumpUntilFound(tester, publicKeyField);
  await tester.tap(
    find.descendant(
      of: publicKeyField,
      matching: find.byKey(const Key('copy_button')),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
  final clipboardData = await Clipboard.getData('text/plain');
  final npub = clipboardData?.text;
  expect(npub, isNotNull);
  expect(npub, startsWith('npub1'));
  await _returnToChatList(tester);
  return npub!;
}

Future<void> _switchProfile(WidgetTester tester, String pubkey) async {
  await _returnToChatList(tester);
  await _openSettings(tester);
  await _tapKey(tester, const Key('settings_switch_profile_button'));
  await _tapKey(
    tester,
    Key('profile_switcher_item_$pubkey'),
  );
  await _returnToChatList(tester);
}

Future<void> _startGroupChat(
  WidgetTester tester, {
  required String inviteeNpub,
  required String inviteePubkey,
}) async {
  await _tapKey(tester, const Key('chat_add_button'));
  await _tapKey(tester, const Key('create_group_menu_item'));
  await _enterTextInWidget(
    tester,
    const Key('user_selection_search_field'),
    inviteeNpub,
  );
  await _tapKey(
    tester,
    Key(inviteePubkey),
    timeout: const Duration(seconds: 60),
  );
  await _pumpUntilFound(tester, find.byKey(Key('bubble_$inviteePubkey')));
  await _tapKey(tester, const Key('user_selection_continue_button'));
  await _enterTextInWidget(
    tester,
    const Key('set_up_group_name_field'),
    _groupName,
  );
  await _pumpUntilFound(
    tester,
    find.byKey(Key('member_$inviteePubkey')),
    timeout: const Duration(seconds: 60),
  );
  await _tapKey(tester, const Key('set_up_group_create_button'));
  await _waitForChatReady(tester, timeout: const Duration(seconds: 90));
}

Future<void> _sendMessage(
  WidgetTester tester,
  ProviderContainer container,
  String message,
) async {
  final input = find.descendant(
    of: find.byKey(const Key('chat_message_input')),
    matching: find.byType(TextField),
  );
  await _pumpUntilFound(tester, input);
  await tester.enterText(input, message);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(
    find.descendant(
      of: find.byKey(const Key('chat_message_input')),
      matching: find.byKey(const Key('send_button')),
    ),
  );
  try {
    await _expectMessageVisible(tester, message);
  } catch (_) {
    fail(
      'Timed out waiting for sent message "$message".\n'
      '${_messageDebugSummary(container)}',
    );
  }
}

String _messageDebugSummary(ProviderContainer container) {
  final state = container.read(messageDebugLogProvider);
  final sendLines = state.sendLog
      .take(8)
      .map((entry) {
        final details = [
          entry.status.name,
          'group=${entry.groupId}',
          if (entry.contentLen != null) 'len=${entry.contentLen}',
          if (entry.resultId != null) 'result=${entry.resultId}',
          if (entry.error != null) 'error=${entry.error}',
        ];
        return 'send: ${details.join(' ')}';
      })
      .join('\n');
  final streamLines = state.streamLog
      .take(12)
      .map((entry) {
        final details = [
          entry.eventType.name,
          'group=${entry.groupId}',
          if (entry.messageCount != null) 'count=${entry.messageCount}',
          if (entry.trigger != null) 'trigger=${entry.trigger}',
          if (entry.messageId != null) 'message=${entry.messageId}',
          if (entry.error != null) 'error=${entry.error}',
        ];
        return 'stream: ${details.join(' ')}';
      })
      .join('\n');
  return [
    'Message debug log:',
    if (sendLines.isEmpty) 'send: <none>' else sendLines,
    if (streamLines.isEmpty) 'stream: <none>' else streamLines,
  ].join('\n');
}

Future<void> _openInvite(WidgetTester tester) async {
  await _pumpUntilFound(
    tester,
    find.text(_groupName),
    timeout: const Duration(seconds: 90),
  );
  await tester.tap(find.text(_groupName).first);
  await _pumpUntilFound(
    tester,
    find.byKey(const Key('chat_invite_accept_button')),
    timeout: const Duration(seconds: 60),
  );
}

Future<void> _openChat(WidgetTester tester) async {
  await _pumpUntilFound(
    tester,
    find.text(_groupName),
    timeout: const Duration(seconds: 60),
  );
  await tester.tap(find.text(_groupName).first);
  await _waitForChatReady(tester, timeout: const Duration(seconds: 60));
}

Future<void> _expectMessageVisible(WidgetTester tester, String message) {
  return _pumpUntilFound(
    tester,
    find.descendant(
      of: find.byType(WnMessageBubble),
      matching: find.textContaining(message, findRichText: true),
    ),
    timeout: const Duration(seconds: 90),
  );
}

Future<void> _waitForChatReady(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  await _pumpUntilFound(
    tester,
    find.byKey(const Key('chat_message_input')),
    timeout: timeout,
  );
  await _pumpUntilNotFound(
    tester,
    find.byType(CircularProgressIndicator),
    timeout: timeout,
  );
}

Future<void> _openSettings(WidgetTester tester) async {
  await _tapKey(tester, const Key('avatar_button'));
  await _pumpUntilFound(
    tester,
    find.byKey(const Key('settings_switch_profile_button')),
  );
}

Future<void> _returnToChatList(WidgetTester tester) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (find.byKey(const Key('chat_add_button')).evaluate().isNotEmpty) {
      return;
    }

    final chatBackButton = find.byKey(const Key('back_button'));
    if (chatBackButton.evaluate().isNotEmpty) {
      await tester.tap(chatBackButton.first);
      continue;
    }

    final slateBackButton = find.byKey(const Key('slate_back_button'));
    if (slateBackButton.evaluate().isNotEmpty) {
      await tester.tap(slateBackButton.first);
      continue;
    }
  }

  fail('Timed out returning to the chat list');
}

Future<void> _enterTextInWidget(
  WidgetTester tester,
  Key key,
  String text,
) async {
  final field = find.descendant(
    of: find.byKey(key),
    matching: find.byType(TextField),
  );
  await _pumpUntilFound(tester, field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _tapKey(
  WidgetTester tester,
  Key key, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final finder = find.byKey(key);
  await _pumpUntilFound(tester, finder, timeout: timeout);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

Future<void> _pumpUntilNotFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isEmpty) return;
  }
  fail('Timed out waiting for $finder to disappear');
}

Future<void> _expectLocalRelaysAvailable() async {
  await _expectLocalRelayAvailable(8080);
  await _expectLocalRelayAvailable(7777);
}

Future<void> _expectLocalRelayAvailable(int port) async {
  try {
    final socket = await Socket.connect(
      '127.0.0.1',
      port,
      timeout: const Duration(seconds: 1),
    );
    socket.destroy();
  } catch (error) {
    fail(
      'Expected a local Nostr relay on 127.0.0.1:$port before running this integration test. '
      'Run `docker compose up -d`, then run the test again. '
      'Connection error: $error',
    );
  }
}
