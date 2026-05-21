import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/widgets/wn_message_bubble.dart';

import '_support/harness.dart';

const _aliceDisplayName = 'Interactions Alice';
const _bobDisplayName = 'Interactions Bob';
const _groupName = 'Interactions Test Group';
const _creatorSeedMessage = 'Bob seed';
const _seedMessage = 'hello from Alice';
const _replyMessage = 'Replying to you';
const _deleteMessage = 'delete me';

class _Identities {
  const _Identities({
    required this.container,
    required this.aliceKey,
    required this.bobKey,
  });

  final ProviderContainer container;
  final String aliceKey;
  final String bobKey;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // One testWidgets: the three phases share one costly setup.
  testWidgets(
    'reaction, reply and deletion propagate between two identities',
    (tester) async {
      final ids = await _setUp(tester);

      await _reactionPhase(tester, ids);
      await _replyPhase(tester, ids);
      await _deletePhase(tester, ids);
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

Future<_Identities> _setUp(WidgetTester tester) async {
  await expectLocalRelaysAvailable();
  final container = await mountApp(tester);

  final aliceKey = await createIdentity(tester, container, _aliceDisplayName);
  await createAdditionalIdentity(tester, container, _bobDisplayName);
  final activeBobKey = container.read(authProvider).value;
  expect(activeBobKey, isNotNull);
  final bobKey = activeBobKey!;

  await switchProfile(tester, aliceKey);
  final aliceNpub = await copyPublicKey(tester);

  await switchProfile(tester, bobKey);
  await startGroupChat(
    tester,
    groupName: _groupName,
    inviteeNpub: aliceNpub,
    inviteePubkey: aliceKey,
  );
  await sendMessage(tester, container, _creatorSeedMessage);
  await returnToChatList(tester);

  await switchProfile(tester, aliceKey);
  await openInvite(tester, _groupName);
  await tapKey(
    tester,
    const Key('chat_invite_accept_button'),
    timeout: const Duration(seconds: 60),
  );
  await waitForChatReady(tester, timeout: const Duration(seconds: 60));
  await sendMessage(tester, container, _seedMessage);
  await returnToChatList(tester);

  await switchProfile(tester, bobKey);
  await openChat(tester, _groupName);
  await expectMessageVisible(tester, _seedMessage);
  await returnToChatList(tester);

  return _Identities(
    container: container,
    aliceKey: aliceKey,
    bobKey: bobKey,
  );
}

Future<void> _reactionPhase(WidgetTester tester, _Identities ids) async {
  await switchProfile(tester, ids.aliceKey);
  await openChat(tester, _groupName);
  final seedId = await _messageIdForText(tester, _seedMessage);
  await _longPressMessage(tester, seedId, _seedMessage);
  await tapKey(tester, const Key('reaction_👍'));
  await _expectReactionOnMessage(tester, seedId, '👍');

  await returnToChatList(tester);
  await switchProfile(tester, ids.bobKey);
  await openChat(tester, _groupName);
  final bobSeedId = await _messageIdForText(tester, _seedMessage);
  await _expectReactionOnMessage(tester, bobSeedId, '👍');
}

Future<void> _replyPhase(WidgetTester tester, _Identities ids) async {
  await switchProfile(tester, ids.bobKey);
  await openChat(tester, _groupName);
  final seedId = await _messageIdForText(tester, _seedMessage);
  await _longPressMessage(tester, seedId, _seedMessage);
  await tapKey(tester, const Key('reply_button'));
  await pumpUntilFound(tester, find.byKey(const Key('cancel_quote_button')));

  await _typeAndSend(tester, _replyMessage);
  await expectMessageVisible(tester, _replyMessage);
  _expectReplyQuotes(tester, replyText: _replyMessage, quoted: _seedMessage);

  await returnToChatList(tester);
  await switchProfile(tester, ids.aliceKey);
  await openChat(tester, _groupName);
  await expectMessageVisible(tester, _replyMessage);
  _expectReplyQuotes(tester, replyText: _replyMessage, quoted: _seedMessage);
}

Future<void> _deletePhase(WidgetTester tester, _Identities ids) async {
  await switchProfile(tester, ids.aliceKey);
  await openChat(tester, _groupName);
  await sendMessage(tester, ids.container, _deleteMessage);
  await returnToChatList(tester);

  // Capture the id while the message text is still rendered: after deletion the
  // bubble no longer carries its original content, so a text lookup would fail.
  await switchProfile(tester, ids.bobKey);
  await openChat(tester, _groupName);
  await expectMessageVisible(tester, _deleteMessage);
  final bobDeleteId = await _messageIdForText(tester, _deleteMessage);
  await returnToChatList(tester);

  await switchProfile(tester, ids.aliceKey);
  await openChat(tester, _groupName);
  final aliceDeleteId = await _messageIdForText(tester, _deleteMessage);
  await _longPressMessage(tester, aliceDeleteId, _deleteMessage);
  await tapKey(tester, const Key('delete_button'));
  await _expectMessageDeleted(tester, aliceDeleteId);

  await returnToChatList(tester);
  await switchProfile(tester, ids.bobKey);
  await openChat(tester, _groupName);
  await _expectMessageDeleted(tester, bobDeleteId);
}

Future<void> _longPressMessage(
  WidgetTester tester,
  String messageId,
  String messageText,
) async {
  final bubble = find.byKey(Key('message_$messageId'));
  await pumpUntilFound(tester, bubble);
  // The keyed WnMessageBubble spans the full row width, so its centre is empty
  // space beside a content-sized, side-aligned bubble. Long-press the message
  // text instead — it always sits inside the visible bubble.
  final content = find
      .descendant(
        of: bubble,
        matching: find.textContaining(messageText, findRichText: true),
      )
      .first;
  await tester.ensureVisible(content);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.longPress(content);
  await tester.pump(const Duration(milliseconds: 500));
  await pumpUntilFound(tester, find.byKey(const Key('reply_button')));
}

Future<void> _typeAndSend(WidgetTester tester, String message) async {
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
  await tester.pump(const Duration(milliseconds: 200));
}

/// Resolves the `message.id` of the bubble currently rendering [text] by reading
/// it back from that bubble's own `Key`. The id is derived from the live widget
/// rather than the send result, so it always matches the key the test searches
/// for afterwards.
Future<String> _messageIdForText(WidgetTester tester, String text) async {
  final textFinder = find.textContaining(text, findRichText: true);
  await pumpUntilFound(tester, textFinder);

  final bubbleFinder = find.ancestor(
    of: textFinder,
    matching: find.byType(WnMessageBubble),
  );
  final bubble = tester.widgetList<WnMessageBubble>(bubbleFinder).first;
  final key = bubble.key;

  const prefix = 'message_';
  if (key is! ValueKey<String> || !key.value.startsWith(prefix)) {
    fail('WnMessageBubble for "$text" has an unexpected key: $key');
  }
  return key.value.substring(prefix.length);
}

Future<void> _expectReactionOnMessage(
  WidgetTester tester,
  String messageId,
  String emoji,
) async {
  await pumpUntilFound(
    tester,
    find.descendant(
      of: find.byKey(Key('message_$messageId')),
      matching: find.byKey(ValueKey(emoji)),
    ),
    timeout: const Duration(seconds: 90),
  );
}

Future<void> _expectMessageDeleted(
  WidgetTester tester,
  String messageId,
) async {
  await pumpUntilFound(
    tester,
    find.descendant(
      of: find.byKey(Key('message_$messageId')),
      matching: find.byKey(const Key('deleted_bubble_border')),
    ),
    timeout: const Duration(seconds: 90),
  );
}

void _expectReplyQuotes(
  WidgetTester tester, {
  required String replyText,
  required String quoted,
}) {
  final replyBubble = find
      .ancestor(
        of: find.textContaining(replyText, findRichText: true),
        matching: find.byType(WnMessageBubble),
      )
      .first;
  expect(replyBubble, findsOneWidget);
  expect(
    find.descendant(
      of: replyBubble,
      matching: find.textContaining(quoted, findRichText: true),
    ),
    findsWidgets,
  );
}
