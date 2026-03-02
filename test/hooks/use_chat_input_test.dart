import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_chat_input.dart';
import 'package:whitenoise/src/rust/api/drafts.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

final _api = MockWnApi();

ChatMessage _createTestMessage({
  String id = 'msg-1',
  String content = 'Test message',
  String? replyToId,
}) {
  return ChatMessage(
    id: id,
    pubkey: testPubkeyA,
    content: content,
    createdAt: DateTime.now(),
    tags: const [],
    isReply: replyToId != null,
    isDeleted: false,
    contentTokens: const [],
    reactions: const ReactionSummary(byEmoji: [], userReactions: []),
    mediaAttachments: const [],
    kind: 9,
  );
}

Draft _createDraft({String content = 'saved draft', String? replyToId}) {
  return Draft(
    accountPubkey: testPubkeyA,
    mlsGroupId: testGroupId,
    content: content,
    replyToId: replyToId,
    mediaAttachments: const [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

ChatMessage? _noMessage(String _) => null;

Future<ChatInputState Function()> _mountInput(
  WidgetTester tester, {
  String pubkey = testPubkeyA,
  String groupId = testGroupId,
  ChatMessage? Function(String)? findMessage,
}) async {
  return mountHook(
    tester,
    () => useChatInput(
      pubkey: pubkey,
      groupId: groupId,
      findMessage: findMessage ?? _noMessage,
    ),
  );
}

class _WithFocusWidget extends HookWidget {
  const _WithFocusWidget({required this.onBuild});
  final void Function(ChatInputState) onBuild;

  @override
  Widget build(BuildContext context) {
    final state = useChatInput(
      pubkey: testPubkeyA,
      groupId: testGroupId,
      findMessage: _noMessage,
    );
    onBuild(state);
    return Focus(focusNode: state.focusNode, child: const SizedBox());
  }
}

Future<ChatInputState Function()> _mountInputWithFocus(WidgetTester tester) async {
  setUpTestView(tester);
  ChatInputState? result;
  await tester.pumpWidget(
    MaterialApp(home: _WithFocusWidget(onBuild: (s) => result = s)),
  );
  return () => result!;
}

void main() {
  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  group('useChatInput', () {
    group('basic state', () {
      testWidgets('provides a controller', (tester) async {
        final result = (await _mountInput(tester))();
        expect(result.controller, isNotNull);
      });

      testWidgets('provides a focusNode', (tester) async {
        final result = (await _mountInput(tester))();
        expect(result.focusNode, isNotNull);
      });

      testWidgets('hasContent is false initially', (tester) async {
        final result = (await _mountInput(tester))();
        expect(result.hasContent, isFalse);
      });

      testWidgets('hasContent is true when text is entered', (tester) async {
        final getResult = await _mountInput(tester);
        getResult().controller.text = 'hello';
        await tester.pump();
        expect(getResult().hasContent, isTrue);
      });

      testWidgets('hasFocus is false initially', (tester) async {
        final result = (await _mountInput(tester))();

        expect(result.hasFocus, isFalse);
      });

      testWidgets('hasFocus is true when focus is requested', (tester) async {
        final getResult = await _mountInputWithFocus(tester);
        getResult().focusNode.requestFocus();
        await tester.pump();

        expect(getResult().hasFocus, isTrue);
      });

      testWidgets('clear empties the controller', (tester) async {
        final getResult = await _mountInput(tester);
        getResult().controller.text = 'hello';
        await tester.pump();
        expect(getResult().hasContent, isTrue);

        getResult().clear();
        await tester.pump();

        expect(getResult().controller.text, isEmpty);
        expect(getResult().hasContent, isFalse);
      });
    });

    group('reply state', () {
      testWidgets('replyingTo is null initially', (tester) async {
        final result = (await _mountInput(tester))();
        expect(result.replyingTo, isNull);
      });

      testWidgets('setReplyingTo sets the message to reply to', (tester) async {
        final getResult = await _mountInput(tester);
        final message = _createTestMessage();

        getResult().setReplyingTo(message);
        await tester.pump();

        expect(getResult().replyingTo, equals(message));
      });

      testWidgets('cancelReply clears the reply state', (tester) async {
        final getResult = await _mountInput(tester);
        final message = _createTestMessage();

        getResult().setReplyingTo(message);
        await tester.pump();
        expect(getResult().replyingTo, isNotNull);

        getResult().cancelReply();
        await tester.pump();

        expect(getResult().replyingTo, isNull);
      });

      testWidgets('clear also clears the reply state', (tester) async {
        final getResult = await _mountInput(tester);
        final message = _createTestMessage();

        getResult().setReplyingTo(message);
        getResult().controller.text = 'hello';
        await tester.pump();
        expect(getResult().replyingTo, isNotNull);
        expect(getResult().hasContent, isTrue);

        getResult().clear();
        await tester.pump();

        expect(getResult().replyingTo, isNull);
        expect(getResult().controller.text, isEmpty);
      });
    });

    group('draft loading', () {
      testWidgets('loadDraft is called on mount', (tester) async {
        await _mountInput(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(_api.loadDraftCallCount, equals(1));
      });

      testWidgets('restores draft content into the controller', (tester) async {
        _api.loadDraftResult = _createDraft(content: 'my unsent message');

        final getResult = await _mountInput(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(getResult().controller.text, equals('my unsent message'));
      });

      testWidgets('restores replyingTo when draft has replyToId and findMessage resolves it', (
        tester,
      ) async {
        final replyMessage = _createTestMessage(id: 'reply-msg-1', content: 'original message');
        _api.loadDraftResult = _createDraft(content: 'draft reply', replyToId: 'reply-msg-1');

        final getResult = await _mountInput(
          tester,
          findMessage: (id) => id == 'reply-msg-1' ? replyMessage : null,
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(getResult().replyingTo, equals(replyMessage));
      });

      testWidgets('does not set replyingTo when findMessage returns null', (tester) async {
        _api.loadDraftResult = _createDraft(content: 'draft', replyToId: 'unknown-id');

        final getResult = await _mountInput(tester, findMessage: _noMessage);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(getResult().replyingTo, isNull);
      });

      testWidgets('handles loadDraft failure gracefully', (tester) async {
        _api.shouldFailLoadDraft = true;

        final getResult = await _mountInput(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(getResult().controller.text, isEmpty);
        expect(getResult().replyingTo, isNull);
      });

      testWidgets('does nothing when loadDraft returns null', (tester) async {
        _api.loadDraftResult = null;

        final getResult = await _mountInput(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(getResult().controller.text, isEmpty);
        expect(getResult().replyingTo, isNull);
      });

      testWidgets('does not set replyingTo when draft has no replyToId', (tester) async {
        _api.loadDraftResult = _createDraft(content: 'draft without reply');

        final getResult = await _mountInput(tester);
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(getResult().replyingTo, isNull);
      });

      testWidgets('ignores late-resolving loadDraft after unmount', (tester) async {
        final completer = Completer<Draft?>();
        _api.loadDraftCompleter = completer;
        _api.loadDraftResult = _createDraft(content: 'late draft');

        final getResult = await _mountInput(tester);

        await tester.pumpWidget(const SizedBox.shrink());

        completer.complete(_createDraft(content: 'late draft'));
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();

        expect(getResult().controller.text, isEmpty);
      });
    });

    group('draft saving', () {
      testWidgets('saves after debounce when user types', (tester) async {
        final getResult = await _mountInput(tester);
        getResult().controller.text = 'hello draft';
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(_api.saveDraftCallCount, equals(1));
        expect(_api.lastSavedDraftContent, equals('hello draft'));
      });

      testWidgets('debounced: only fires once for rapid changes', (tester) async {
        final getResult = await _mountInput(tester);

        getResult().controller.text = 'a';
        await tester.pump();
        getResult().controller.text = 'ab';
        await tester.pump();
        getResult().controller.text = 'abc';
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(_api.saveDraftCallCount, equals(1));
        expect(_api.lastSavedDraftContent, equals('abc'));
      });

      testWidgets('includes replyToId when replyingTo is set', (tester) async {
        final replyMessage = _createTestMessage(id: 'reply-id');
        final getResult = await _mountInput(tester);

        getResult().controller.text = 'replying here';
        await tester.pump();
        getResult().setReplyingTo(replyMessage);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(_api.lastSavedDraftReplyToId, equals('reply-id'));
      });

      testWidgets('saveDraft failure is handled gracefully', (tester) async {
        _api.shouldFailSaveDraft = true;
        final getResult = await _mountInput(tester);
        getResult().controller.text = 'hello draft';
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(_api.saveDraftCallCount, equals(1));
      });

      testWidgets('saves when reply is set with no text', (tester) async {
        final replyMessage = _createTestMessage(id: 'reply-only');
        final getResult = await _mountInput(tester);

        getResult().setReplyingTo(replyMessage);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(_api.saveDraftCallCount, equals(1));
        expect(_api.lastSavedDraftReplyToId, equals('reply-only'));
      });
    });

    group('draft deleting', () {
      testWidgets('deleteDraft is called when clear() is invoked', (tester) async {
        final getResult = await _mountInput(tester);
        getResult().controller.text = 'draft to delete';
        await tester.pump();

        getResult().clear();
        await tester.pumpAndSettle();

        expect(_api.deleteDraftCallCount, equals(1));
      });

      testWidgets('deleteDraft cancels any pending debounced save', (tester) async {
        final getResult = await _mountInput(tester);
        getResult().controller.text = 'draft';
        await tester.pump();

        getResult().clear();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(_api.saveDraftCallCount, equals(0));
        expect(_api.deleteDraftCallCount, equals(1));
      });

      testWidgets('deleteDraft is called after debounce when text is cleared to empty', (
        tester,
      ) async {
        final getResult = await _mountInput(tester);
        getResult().controller.text = 'some text';
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        getResult().controller.text = '';
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(_api.deleteDraftCallCount, equals(1));
      });

      testWidgets('deleteDraft failure in debounced save is handled gracefully', (tester) async {
        _api.shouldFailDeleteDraft = true;
        final getResult = await _mountInput(tester);
        getResult().controller.text = 'some text';
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        getResult().controller.text = '';
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(_api.deleteDraftCallCount, equals(1));
      });

      testWidgets('deleteDraft failure on clear is handled gracefully', (tester) async {
        _api.shouldFailDeleteDraft = true;
        final getResult = await _mountInput(tester);
        getResult().controller.text = 'draft to delete';
        await tester.pump();

        getResult().clear();
        await tester.pumpAndSettle();

        expect(_api.deleteDraftCallCount, equals(1));
      });

      testWidgets('deleteDraft is called when reply is canceled with no text', (tester) async {
        final replyMessage = _createTestMessage(id: 'reply-id');
        final getResult = await _mountInput(tester);

        getResult().setReplyingTo(replyMessage);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        getResult().cancelReply();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(_api.deleteDraftCallCount, equals(1));
      });
    });
  });
}
