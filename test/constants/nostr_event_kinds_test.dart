import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/constants/nostr_event_kinds.dart';

void main() {
  group('NostrEventKinds', () {
    test('deletion is 5 (NIP-09)', () {
      expect(NostrEventKinds.deletion, 5);
    });

    test('reaction is 7 (NIP-25)', () {
      expect(NostrEventKinds.reaction, 7);
    });

    test('chatMessage is 9 (NIP-C7)', () {
      expect(NostrEventKinds.chatMessage, 9);
    });

    test('mlsKeyPackage is 30443 (MIP-00)', () {
      expect(NostrEventKinds.mlsKeyPackage, 30443);
    });

    test('mlsKeyPackageLegacy is 443 (MIP-00 legacy)', () {
      expect(NostrEventKinds.mlsKeyPackageLegacy, 443);
    });

    test('mlsWelcome is 444 (MIP-02)', () {
      expect(NostrEventKinds.mlsWelcome, 444);
    });

    test('mlsGroupMessage is 445 (MIP-03)', () {
      expect(NostrEventKinds.mlsGroupMessage, 445);
    });

    test('giftWrap is 1059 (NIP-59)', () {
      expect(NostrEventKinds.giftWrap, 1059);
    });

    test('relayListMetadata is 10002 (NIP-65)', () {
      expect(NostrEventKinds.relayListMetadata, 10002);
    });

    test('inboxRelays is 10050 (NIP-17)', () {
      expect(NostrEventKinds.inboxRelays, 10050);
    });

    test('mlsKeyPackageRelays is 10051 (MIP-00)', () {
      expect(NostrEventKinds.mlsKeyPackageRelays, 10051);
    });
  });
}
