import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/utils/encoding.dart';

import '_support/harness.dart';

const _firstDisplayName = 'Integration Alice';
const _secondDisplayName = 'Integration Bob';
const _groupName = 'Integration Test Group';
const _initialMessage = 'Hello, testing initial message';
const _secondMessage = 'Hello, testing second message';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('two identities exchange messages through a group invite', (
    tester,
  ) async {
    await expectLocalRelaysAvailable();
    final container = await mountApp(tester);

    final firstPubkey = await createIdentity(
      tester,
      container,
      _firstDisplayName,
    );
    await createAdditionalIdentity(tester, container, _secondDisplayName);
    final activeSecondPubkey = container.read(authProvider).value;
    expect(activeSecondPubkey, isNotNull);
    final secondPubkey = activeSecondPubkey!;

    await switchProfile(tester, firstPubkey);
    final firstNpub = await copyPublicKey(tester);
    expect(hexFromNpub(firstNpub), firstPubkey);

    await switchProfile(tester, secondPubkey);
    await startGroupChat(
      tester,
      groupName: _groupName,
      inviteeNpub: firstNpub,
      inviteePubkey: firstPubkey,
    );
    await sendMessage(tester, container, _initialMessage);
    await expectMessageVisible(tester, _initialMessage);

    await returnToChatList(tester);
    await switchProfile(tester, firstPubkey);
    await openInvite(tester, _groupName);
    await expectMessageVisible(tester, _initialMessage);
    await tapKey(
      tester,
      const Key('chat_invite_accept_button'),
      timeout: const Duration(seconds: 60),
    );
    await waitForChatReady(tester, timeout: const Duration(seconds: 60));
    await sendMessage(tester, container, _secondMessage);
    await expectMessageVisible(tester, _secondMessage);

    await returnToChatList(tester);
    await switchProfile(tester, secondPubkey);
    await openChat(tester, _groupName);
    await expectMessageVisible(tester, _secondMessage);
  });
}
