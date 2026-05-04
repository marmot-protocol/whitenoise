class NostrEventKinds {
  NostrEventKinds._();

  // NIP-09: https://github.com/nostr-protocol/nips/blob/master/09.md
  static const int deletion = 5;

  // NIP-25: https://github.com/nostr-protocol/nips/blob/master/25.md
  static const int reaction = 7;

  // NIP-C7: https://github.com/nostr-protocol/nips/blob/master/C7.md
  static const int chatMessage = 9;

  // MIP-00: https://github.com/marmot-protocol/marmot/blob/master/00.md
  static const int mlsKeyPackage = 30443;

  // MIP-00: https://github.com/marmot-protocol/marmot/blob/master/00.md
  static const int mlsKeyPackageLegacy = 443;

  // MIP-02: https://github.com/marmot-protocol/marmot/blob/master/02.md
  static const int mlsWelcome = 444;

  // MIP-03: https://github.com/marmot-protocol/marmot/blob/master/03.md
  static const int mlsGroupMessage = 445;

  // NIP-59: https://github.com/nostr-protocol/nips/blob/master/59.md
  static const int giftWrap = 1059;

  // NIP-65: https://github.com/nostr-protocol/nips/blob/master/65.md
  static const int relayListMetadata = 10002;

  // NIP-17: https://github.com/nostr-protocol/nips/blob/master/17.md
  static const int inboxRelays = 10050;

  // MIP-00: https://github.com/marmot-protocol/marmot/blob/master/00.md
  static const int mlsKeyPackageRelays = 10051;
}
