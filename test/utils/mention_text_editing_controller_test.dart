import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/mention_text_editing_controller.dart';

void main() {
  group('MentionTextEditingController', () {
    test('insertMention replaces the @query range with display text + space', () {
      final controller = MentionTextEditingController(text: 'hi @al')
        ..selection = const TextSelection.collapsed(offset: 6);
      controller.insertMention(
        start: 3,
        end: 6,
        displayName: 'Alice',
        uri: '@npub1alice',
      );
      expect(controller.text, 'hi @Alice ');
      expect(controller.selection.baseOffset, 'hi @Alice '.length);
    });

    test('messageText expands the tracked display back to the underlying uri', () {
      final controller = MentionTextEditingController(text: 'hi @al')
        ..selection = const TextSelection.collapsed(offset: 6);
      controller.insertMention(
        start: 3,
        end: 6,
        displayName: 'Alice',
        uri: '@npub1alice',
      );
      expect(controller.messageText, 'hi @npub1alice ');
    });

    test('editing into the mention text invalidates it', () {
      final controller = MentionTextEditingController(text: '')
        ..selection = const TextSelection.collapsed(offset: 0);
      controller.insertMention(
        start: 0,
        end: 0,
        displayName: 'Alice',
        uri: '@npub1alice',
      );
      expect(controller.text, '@Alice ');
      // User backspaces the 'e' in '@Alice'.
      controller.value = const TextEditingValue(
        text: '@Alic ',
        selection: TextSelection.collapsed(offset: 5),
      );
      // No tracked mention should remain — messageText equals plain text.
      expect(controller.messageText, '@Alic ');
    });

    test('IME composing chars at a mention boundary do not drop the mention', () {
      final controller = MentionTextEditingController(text: '')
        ..selection = const TextSelection.collapsed(offset: 0);
      controller.insertMention(
        start: 0,
        end: 0,
        displayName: 'Alice',
        uri: '@npub1alice',
      );
      expect(controller.text, '@Alice ');
      // Transient pinyin char inserted immediately after the mention; the
      // composing range marks it as not-yet-committed.
      controller.value = const TextEditingValue(
        text: '@Alicen ',
        selection: TextSelection.collapsed(offset: 7),
        composing: TextRange(start: 6, end: 7),
      );
      // The mention must survive the transient composition; messageText
      // expands it back to the URI.
      expect(controller.messageText, '@npub1alicen ');
    });

    test('non-composing edit at a mention boundary still drops the mention', () {
      final controller = MentionTextEditingController(text: '')
        ..selection = const TextSelection.collapsed(offset: 0);
      controller.insertMention(
        start: 0,
        end: 0,
        displayName: 'Alice',
        uri: '@npub1alice',
      );
      expect(controller.text, '@Alice ');
      // Same shape of edit, but no composing range — a fully committed
      // keystroke that extends the name should drop the mention.
      controller.value = const TextEditingValue(
        text: '@Alicen ',
        selection: TextSelection.collapsed(offset: 7),
      );
      expect(controller.messageText, '@Alicen ');
    });

    test('setMentionTargets restores display form for known uris in drafts', () {
      final controller = MentionTextEditingController(text: 'hello @npub1alice :)')
        ..selection = const TextSelection.collapsed(offset: 'hello '.length);
      controller.setMentionTargets(const [
        MentionTextTarget(uri: '@npub1alice', displayText: '@Alice'),
      ]);
      expect(controller.text, 'hello @Alice :)');
      expect(controller.messageText, 'hello @npub1alice :)');
    });

    test('setMentionTargets is a no-op when the target set is unchanged', () {
      final controller = MentionTextEditingController(text: '@npub1alice')
        ..selection = const TextSelection.collapsed(offset: 0);
      const targets = [
        MentionTextTarget(uri: '@npub1alice', displayText: '@Alice'),
      ];
      controller.setMentionTargets(targets);
      expect(controller.text, '@Alice');
      // Calling again with the same targets does not double-process.
      controller.setMentionTargets(targets);
      expect(controller.text, '@Alice');
    });

    testWidgets('buildTextSpan styles mentions with the theme primary color', (tester) async {
      final controller = MentionTextEditingController(text: '')
        ..selection = const TextSelection.collapsed(offset: 0);
      controller.insertMention(
        start: 0,
        end: 0,
        displayName: 'Alice',
        uri: '@npub1alice',
      );

      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: Color(0xFF112233)),
          ),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final span = controller.buildTextSpan(
        context: capturedContext,
        style: const TextStyle(color: Color(0xFF000000)),
        withComposing: false,
      );
      final children = span.children!.cast<TextSpan>();
      final mentionSpan = children.firstWhere((s) => s.text == '@Alice');
      expect(mentionSpan.style!.color, const Color(0xFF112233));
      expect(mentionSpan.style!.fontWeight, FontWeight.w700);
    });

    testWidgets('buildTextSpan falls back to super when no valid mentions', (tester) async {
      final controller = MentionTextEditingController(text: 'plain text');
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final span = controller.buildTextSpan(
        context: capturedContext,
        style: const TextStyle(color: Color(0xFF000000)),
        withComposing: false,
      );
      expect(span.text, 'plain text');
    });

    test('insertMention shifts later mentions and preserves earlier ones', () {
      final controller = MentionTextEditingController(text: 'hello world');
      controller.insertMention(
        start: 6,
        end: 11,
        displayName: 'Bob',
        uri: '@npub1bob',
      );
      expect(controller.text, 'hello @Bob ');
      // Insert another mention at the very start; the existing Bob mention
      // must shift right by the length of the new prefix.
      controller.insertMention(
        start: 0,
        end: 0,
        displayName: 'Alice',
        uri: '@npub1alice',
      );
      expect(controller.text, '@Alice hello @Bob ');
      expect(controller.messageText, '@npub1alice hello @npub1bob ');
    });

    testWidgets('buildTextSpan emits leading text before a mention', (tester) async {
      final controller = MentionTextEditingController(text: 'hi there');
      controller.insertMention(
        start: 3,
        end: 8,
        displayName: 'Bob',
        uri: '@npub1bob',
      );
      expect(controller.text, 'hi @Bob ');

      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final span = controller.buildTextSpan(
        context: capturedContext,
        style: const TextStyle(color: Color(0xFF000000)),
        withComposing: false,
      );
      final children = span.children!.cast<TextSpan>();
      // Leading text 'hi ' should appear before the mention span.
      expect(children.first.text, 'hi ');
      expect(children.any((s) => s.text == '@Bob'), isTrue);
    });

    test('setMentionTargets replaces a known uri that sits after existing text', () {
      // Covers the _replaceKnownUris selection-shift branch where the cursor
      // sits past the replacement range.
      final controller = MentionTextEditingController(text: 'hi @npub1alice okay')
        ..selection = const TextSelection.collapsed(offset: 19);
      controller.setMentionTargets(const [
        MentionTextTarget(uri: '@npub1alice', displayText: '@Alice'),
      ]);
      expect(controller.text, 'hi @Alice okay');
      expect(controller.messageText, 'hi @npub1alice okay');
      // Cursor should have shifted back by the length delta (-5).
      expect(controller.selection.baseOffset, 14);
    });

    test('setMentionTargets snaps cursor to end of display when it was mid-URI', () {
      final controller = MentionTextEditingController(text: 'hi @npub1alice okay')
        ..selection = const TextSelection.collapsed(offset: 8); // mid-URI
      controller.setMentionTargets(const [
        MentionTextTarget(uri: '@npub1alice', displayText: '@Alice'),
      ]);
      expect(controller.text, 'hi @Alice okay');
      // newStart=3, displayText.length=6 -> 9.
      expect(controller.selection.baseOffset, 9);
    });

    test('insertion before an existing mention shifts the mention via _shiftMentions', () {
      final controller = MentionTextEditingController(text: 'hello world');
      controller.insertMention(
        start: 6,
        end: 11,
        displayName: 'Bob',
        uri: '@npub1bob',
      );
      // text = 'hello @Bob ', mention Bob at (6, 10).
      controller.value = const TextEditingValue(
        text: 'Xhello @Bob ',
        selection: TextSelection.collapsed(offset: 1),
      );
      // _shiftMentions should shift Bob's tracked position by +1 since the
      // insertion is fully before it.
      expect(controller.messageText, 'Xhello @npub1bob ');
    });

    test('bare npub replacement preserves a mention that sits after it', () {
      final controller = MentionTextEditingController(text: 'Hello ');
      controller.insertMention(
        start: 6,
        end: 6,
        displayName: 'Alice',
        uri: '@npub1alice',
      );
      // text = 'Hello @Alice ', mention at (6, 12).
      // 58 base32 chars after '@npub1' as required by _bareNpubRegex.
      final bareNpub = '@npub1${'q' * 58}';
      controller.value = TextEditingValue(
        text: '$bareNpub Hello @Alice ',
        selection: TextSelection.collapsed(offset: bareNpub.length + 1),
      );
      // The bare npub becomes a truncated display string, but the @Alice
      // mention that sits AFTER the replacement must shift in lockstep so
      // messageText still expands it back to the URI.
      expect(controller.text.contains('@Alice'), isTrue);
      expect(controller.text.contains('…'), isTrue);
      expect(controller.messageText.endsWith('@npub1alice '), isTrue);
      expect(controller.messageText.startsWith(bareNpub), isTrue);
    });

    test('insertMention with empty displayName falls back to the uri', () {
      final controller = MentionTextEditingController(text: '@')
        ..selection = const TextSelection.collapsed(offset: 1);
      controller.insertMention(
        start: 0,
        end: 1,
        displayName: '   ',
        uri: '@npub1bare',
      );
      expect(controller.text, '@npub1bare ');
      expect(controller.messageText, '@npub1bare ');
    });

    group('isCursorInsideMention', () {
      MentionTextEditingController makeWithMention() {
        final c = MentionTextEditingController(text: '')
          ..selection = const TextSelection.collapsed(offset: 0);
        c.insertMention(
          start: 0,
          end: 0,
          displayName: 'Alice',
          uri: '@npub1alice',
        );
        // text is now '@Alice ' with cursor after the trailing space.
        return c;
      }

      test('returns false when there are no mentions', () {
        final c = MentionTextEditingController(text: 'hello @world');
        c.selection = const TextSelection.collapsed(offset: 7);
        expect(c.isCursorInsideMention, isFalse);
      });

      test('returns true when cursor is inside the mention range', () {
        final c = makeWithMention();
        c.selection = const TextSelection.collapsed(offset: 3);
        expect(c.isCursorInsideMention, isTrue);
      });

      test('returns true at the trailing edge of the mention', () {
        final c = makeWithMention();
        // '@Alice' ends at offset 6.
        c.selection = const TextSelection.collapsed(offset: 6);
        expect(c.isCursorInsideMention, isTrue);
      });

      test('returns false at the leading edge of the mention', () {
        final c = makeWithMention();
        c.selection = const TextSelection.collapsed(offset: 0);
        expect(c.isCursorInsideMention, isFalse);
      });

      test('returns false past the trailing space of the mention', () {
        final c = makeWithMention();
        c.selection = const TextSelection.collapsed(offset: 7);
        expect(c.isCursorInsideMention, isFalse);
      });
    });

    test('out-of-range insertMention is a no-op', () {
      final controller = MentionTextEditingController(text: 'hi');
      controller.insertMention(
        start: -1,
        end: 5,
        displayName: 'Alice',
        uri: '@npub1alice',
      );
      expect(controller.text, 'hi');
    });

    group('bare @npub auto-detection', () {
      const fullNpub = '@npub1xtscya34g58tk0z605fvr788k263gsu6cy9x0mhnm87echrgufzsevkk5s';
      const truncated = '@npub1xtscya3…kk5s';

      test('typing a full bare @npub auto-truncates to styled display', () {
        final controller = MentionTextEditingController();
        controller.value = const TextEditingValue(
          text: 'hi $fullNpub there',
          selection: TextSelection.collapsed(offset: 3 + fullNpub.length),
        );
        expect(controller.text, 'hi $truncated there');
        expect(controller.messageText, 'hi $fullNpub there');
      });

      test('a partial npub (too short) is left untouched', () {
        final controller = MentionTextEditingController(text: '@npub1abc');
        controller.value = const TextEditingValue(text: '@npub1abc');
        expect(controller.text, '@npub1abc');
        expect(controller.messageText, '@npub1abc');
      });

      test('known target wins over bare auto-detection', () {
        final controller = MentionTextEditingController();
        controller.setMentionTargets(const [
          MentionTextTarget(uri: fullNpub, displayText: '@Trent'),
        ]);
        controller.value = const TextEditingValue(
          text: 'hi $fullNpub',
          selection: TextSelection.collapsed(offset: 3 + fullNpub.length),
        );
        expect(controller.text, 'hi @Trent');
        expect(controller.messageText, 'hi $fullNpub');
      });

      test('resolver returns display name → mention shows @Name instead of truncating', () {
        final controller = MentionTextEditingController()
          ..displayNameForNpub = (npub) => npub == fullNpub.substring(1) ? 'Satoshi' : null;
        controller.value = const TextEditingValue(
          text: fullNpub,
          selection: TextSelection.collapsed(offset: fullNpub.length),
        );
        expect(controller.text, '@Satoshi');
        expect(controller.messageText, fullNpub);
      });

      test('resolver returns null → falls back to truncation', () {
        final controller = MentionTextEditingController()..displayNameForNpub = (_) => null;
        controller.value = const TextEditingValue(
          text: fullNpub,
          selection: TextSelection.collapsed(offset: fullNpub.length),
        );
        expect(controller.text, truncated);
        expect(controller.messageText, fullNpub);
      });

      test('setting a resolver after the fact upgrades existing truncated mentions', () {
        final controller = MentionTextEditingController();
        controller.value = const TextEditingValue(
          text: fullNpub,
          selection: TextSelection.collapsed(offset: fullNpub.length),
        );
        expect(controller.text, truncated);
        controller.displayNameForNpub = (_) => 'Satoshi';
        expect(controller.text, '@Satoshi');
        expect(controller.messageText, fullNpub);
      });

      test('clearing the resolver downgrades known mentions back to truncated', () {
        final controller = MentionTextEditingController()..displayNameForNpub = (_) => 'Satoshi';
        controller.value = const TextEditingValue(
          text: fullNpub,
          selection: TextSelection.collapsed(offset: fullNpub.length),
        );
        expect(controller.text, '@Satoshi');
        controller.displayNameForNpub = null;
        expect(controller.text, truncated);
      });

      test('does NOT auto-convert when the npub is mid-token (no leading boundary)', () {
        final controller = MentionTextEditingController();
        controller.value = const TextEditingValue(
          text: 'foo$fullNpub bar',
          selection: TextSelection.collapsed(offset: 0),
        );
        // Mid-token: no boundary before @ → left as-is.
        expect(controller.text, 'foo$fullNpub bar');
        expect(controller.messageText, 'foo$fullNpub bar');
      });

      test('preserves prior display mentions when hydrating a raw URI elsewhere', () {
        const otherNpub = '@npub1xtscya34g58tk0z605fvr788k263gsu6cy9x0mhnm87echrgufzsevkk5s';
        final controller = MentionTextEditingController();
        // First insert a display mention via the picker.
        controller.insertMention(
          start: 0,
          end: 0,
          displayName: 'Alice',
          uri: '@npub1alice',
        );
        expect(controller.text, '@Alice ');
        // Register Bob as a known target.
        controller.setMentionTargets(const [
          MentionTextTarget(uri: '@npub1alice', displayText: '@Alice'),
          MentionTextTarget(uri: otherNpub, displayText: '@Bob'),
        ]);
        // Now paste a raw Bob URI after Alice.
        controller.value = const TextEditingValue(
          text: '@Alice $otherNpub',
          selection: TextSelection.collapsed(offset: '@Alice $otherNpub'.length),
        );
        // Both mentions should now be tracked.
        expect(controller.text, '@Alice @Bob');
        expect(
          controller.messageText,
          '@npub1alice @npub1xtscya34g58tk0z605fvr788k263gsu6cy9x0mhnm87echrgufzsevkk5s',
        );
      });

      test('re-assigning the same resolver is a no-op (cursor stays put)', () {
        final controller = MentionTextEditingController();
        controller.value = const TextEditingValue(
          text: 'hello $fullNpub world',
          selection: TextSelection.collapsed(offset: 3),
        );
        String? sameResolver(String _) => 'Satoshi';
        controller.displayNameForNpub = sameResolver;
        final cursorAfterFirstAssign = controller.selection.baseOffset;
        // Assigning the exact same closure again must not re-run the cascade
        // that would otherwise move the cursor.
        controller.displayNameForNpub = sameResolver;
        expect(controller.selection.baseOffset, cursorAfterFirstAssign);
      });

      test('editing inside the truncated display invalidates the mention', () {
        final controller = MentionTextEditingController();
        controller.value = const TextEditingValue(
          text: fullNpub,
          selection: TextSelection.collapsed(offset: fullNpub.length),
        );
        expect(controller.text, truncated);
        // Backspace inside the truncated display.
        final shorter = truncated.substring(0, truncated.length - 1);
        controller.value = TextEditingValue(
          text: shorter,
          selection: TextSelection.collapsed(offset: shorter.length),
        );
        expect(controller.text, shorter);
        expect(controller.messageText, shorter);
      });
    });
  });
}
