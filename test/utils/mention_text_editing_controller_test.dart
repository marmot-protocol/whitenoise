import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/mention_text_editing_controller.dart';

import '../test_helpers.dart';

void main() {
  group('MentionTextEditingController', () {
    test('displays a friendly mention while expanding to the Nostr URI', () {
      final controller = MentionTextEditingController();
      addTearDown(controller.dispose);

      controller.insertMention(
        start: 0,
        end: 0,
        displayName: 'Bob',
        uri: 'nostr:$testNpubB',
      );

      expect(controller.text, '@Bob ');
      expect(controller.messageText, 'nostr:$testNpubB ');
    });

    test('keeps mention identity when text is inserted around it', () {
      final controller = MentionTextEditingController();
      addTearDown(controller.dispose);

      controller.insertMention(
        start: 0,
        end: 0,
        displayName: 'Bob',
        uri: 'nostr:$testNpubB',
      );
      controller.value = controller.value.copyWith(
        text: 'Hi @Bob ',
        selection: const TextSelection.collapsed(offset: 8),
      );
      controller.value = controller.value.copyWith(
        text: 'Hi @Bob there',
        selection: const TextSelection.collapsed(offset: 13),
      );

      expect(controller.messageText, 'Hi nostr:$testNpubB there');
    });

    test('keeps mention identity when a mention is inserted before it', () {
      final controller = MentionTextEditingController();
      addTearDown(controller.dispose);

      controller.insertMention(
        start: 0,
        end: 0,
        displayName: 'Bob',
        uri: 'nostr:$testNpubB',
      );
      controller.value = controller.value.copyWith(
        selection: const TextSelection.collapsed(offset: 0),
      );
      controller.insertMention(
        start: controller.selection.start,
        end: controller.selection.end,
        displayName: 'Alice',
        uri: 'nostr:$testNpubC',
      );

      expect(controller.text, '@Alice @Bob ');
      expect(controller.messageText, 'nostr:$testNpubC nostr:$testNpubB ');
    });

    test('drops mention identity when the display text is edited', () {
      final controller = MentionTextEditingController();
      addTearDown(controller.dispose);

      controller.insertMention(
        start: 0,
        end: 0,
        displayName: 'Bob',
        uri: 'nostr:$testNpubB',
      );
      controller.value = controller.value.copyWith(
        text: '@Bobby ',
        selection: const TextSelection.collapsed(offset: 7),
      );

      expect(controller.messageText, '@Bobby ');
    });

    test('restores known stored Nostr URIs into friendly mentions', () {
      final controller = MentionTextEditingController(text: 'Hi nostr:$testNpubB');
      addTearDown(controller.dispose);

      controller.setMentionTargets([
        const MentionTextTarget(uri: 'nostr:$testNpubB', displayText: '@Bob'),
      ]);

      expect(controller.text, 'Hi @Bob');
      expect(controller.messageText, 'Hi nostr:$testNpubB');
    });

    test('moves selection after restored known Nostr URIs', () {
      final controller = MentionTextEditingController(text: 'Hi nostr:$testNpubB there');
      addTearDown(controller.dispose);
      controller.selection = TextSelection.collapsed(offset: controller.text.length);

      controller.setMentionTargets([
        const MentionTextTarget(uri: 'nostr:$testNpubB', displayText: '@Bob'),
      ]);

      expect(controller.text, 'Hi @Bob there');
      expect(controller.selection.baseOffset, controller.text.length);
    });

    test('moves selection inside a restored Nostr URI to the end of the mention', () {
      final controller = MentionTextEditingController(text: 'Hi nostr:$testNpubB');
      addTearDown(controller.dispose);
      controller.selection = const TextSelection.collapsed(offset: 8);

      controller.setMentionTargets([
        const MentionTextTarget(uri: 'nostr:$testNpubB', displayText: '@Bob'),
      ]);

      expect(controller.text, 'Hi @Bob');
      expect(controller.selection.baseOffset, 'Hi @Bob'.length);
    });

    test('notifies once when inserting a mention', () {
      final controller = MentionTextEditingController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.insertMention(
        start: 0,
        end: 0,
        displayName: 'Bob',
        uri: 'nostr:$testNpubB',
      );

      expect(notifications, 1);
    });

    test('notifies once when restoring known stored Nostr URIs', () {
      final controller = MentionTextEditingController(text: 'Hi nostr:$testNpubB');
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setMentionTargets([
        const MentionTextTarget(uri: 'nostr:$testNpubB', displayText: '@Bob'),
      ]);

      expect(notifications, 1);
      expect(controller.text, 'Hi @Bob');
    });
  });
}
