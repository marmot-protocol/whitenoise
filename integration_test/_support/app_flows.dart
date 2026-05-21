// Whitenoise user-journey helpers: identity, groups, messaging, navigation.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/message_debug_log_provider.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';

import 'tester_helpers.dart';

Future<String> createIdentity(
  WidgetTester tester,
  ProviderContainer container,
  String displayName,
) async {
  await tapKey(tester, const Key('auth_signup_button'));
  await enterTextInWidget(
    tester,
    const Key('signup_display_name_field'),
    displayName,
  );
  await tapKey(tester, const Key('signup_create_profile_button'));
  await pumpUntilFound(
    tester,
    find.byKey(const Key('chat_add_button')),
    timeout: const Duration(seconds: 90),
  );
  final pubkey = container.read(authProvider).value;
  expect(pubkey, isNotNull);
  return pubkey!;
}

Future<String> createAdditionalIdentity(
  WidgetTester tester,
  ProviderContainer container,
  String displayName,
) async {
  await returnToChatList(tester);
  await openSettings(tester);
  await tapKey(tester, const Key('settings_switch_profile_button'));
  await tapKey(tester, const Key('connect_another_profile_button'));
  return createIdentity(tester, container, displayName);
}

Future<String> copyPublicKey(WidgetTester tester) async {
  await returnToChatList(tester);
  await openSettings(tester);
  await tapKey(tester, const Key('settings_profile_keys_menu_item'));
  final publicKeyField = find.byKey(const Key('profile_keys_public_key_field'));
  await pumpUntilFound(tester, publicKeyField);
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
  await returnToChatList(tester);
  return npub!;
}

Future<void> switchProfile(WidgetTester tester, String pubkey) async {
  await returnToChatList(tester);
  await openSettings(tester);
  await tapKey(tester, const Key('settings_switch_profile_button'));
  await tapKey(
    tester,
    Key('profile_switcher_item_$pubkey'),
  );
  await returnToChatList(tester);
}

Future<void> startGroupChat(
  WidgetTester tester, {
  required String groupName,
  required String inviteeNpub,
  required String inviteePubkey,
}) async {
  await tapKey(tester, const Key('chat_add_button'));
  await tapKey(tester, const Key('create_group_menu_item'));
  await enterTextInWidget(
    tester,
    const Key('user_picker_search_field'),
    inviteeNpub,
  );
  await tapKey(
    tester,
    Key('user_picker_user_$inviteePubkey'),
    timeout: const Duration(seconds: 60),
  );
  await pumpUntilFound(
    tester,
    find.byKey(Key('user_picker_bubble_$inviteePubkey')),
  );
  await tapKey(tester, const Key('user_picker_submit_button'));
  await enterTextInWidget(
    tester,
    const Key('set_up_group_name_field'),
    groupName,
  );
  await pumpUntilFound(
    tester,
    find.byKey(Key('member_$inviteePubkey')),
    timeout: const Duration(seconds: 60),
  );
  await tapKey(tester, const Key('set_up_group_create_button'));
  await waitForChatReady(tester, timeout: const Duration(seconds: 90));
}

Future<void> sendMessage(
  WidgetTester tester,
  ProviderContainer container,
  String message,
) async {
  final input = find.descendant(
    of: find.byKey(const Key('chat_message_input')),
    matching: find.byType(TextField),
  );
  await pumpUntilFound(tester, input);
  await tester.enterText(input, message);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(
    find.descendant(
      of: find.byKey(const Key('chat_message_input')),
      matching: find.byKey(const Key('send_button')),
    ),
  );
  try {
    await expectMessageVisible(tester, message);
  } catch (_) {
    fail(
      'Timed out waiting for sent message "$message".\n'
      '${messageDebugSummary(container)}',
    );
  }
}

String messageDebugSummary(ProviderContainer container) {
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

Future<void> expectMessageVisible(WidgetTester tester, String message) {
  return pumpUntilFound(
    tester,
    find.descendant(
      of: find.byType(WnMessageBubble),
      matching: find.textContaining(message, findRichText: true),
    ),
    timeout: const Duration(seconds: 90),
  );
}

Future<void> waitForChatReady(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  await pumpUntilFound(
    tester,
    find.byKey(const Key('chat_message_input')),
    timeout: timeout,
  );
  await pumpUntilNotFound(
    tester,
    find.byType(CircularProgressIndicator),
    timeout: timeout,
  );
}

Future<void> openInvite(WidgetTester tester, String groupName) async {
  await pumpUntilFound(
    tester,
    find.text(groupName),
    timeout: const Duration(seconds: 90),
  );
  await tester.tap(find.text(groupName).first);
  await pumpUntilFound(
    tester,
    find.byKey(const Key('chat_invite_accept_button')),
    timeout: const Duration(seconds: 60),
  );
}

Future<void> openChat(WidgetTester tester, String groupName) async {
  await pumpUntilFound(
    tester,
    find.text(groupName),
    timeout: const Duration(seconds: 60),
  );
  await tester.tap(find.text(groupName).first);
  await waitForChatReady(tester, timeout: const Duration(seconds: 60));
}

Future<void> openSettings(WidgetTester tester) async {
  await tapKey(tester, const Key('avatar_button'));
  await pumpUntilFound(
    tester,
    find.byKey(const Key('settings_switch_profile_button')),
  );
}

Future<void> returnToChatList(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
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
