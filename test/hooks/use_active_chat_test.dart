import 'dart:ui' show AppLifecycleState;

import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_active_chat.dart';

import '../test_helpers.dart' show mountHook;

void main() {
  group('useActiveChat', () {
    late List<String> setActiveChatCalls;
    late int clearActiveChatCallCount;
    late List<String> cancelNotificationsCalls;

    setUp(() {
      setActiveChatCalls = [];
      clearActiveChatCallCount = 0;
      cancelNotificationsCalls = [];
    });

    void setActiveChat(String groupId) => setActiveChatCalls.add(groupId);
    void clearActiveChat() => clearActiveChatCallCount++;
    void cancelGroupNotifications(String groupId) => cancelNotificationsCalls.add(groupId);

    testWidgets('sets active chat and cancels notifications on mount', (tester) async {
      await mountHook(tester, () {
        useActiveChat(
          groupId: 'group123',
          setActiveChat: setActiveChat,
          clearActiveChat: clearActiveChat,
          cancelGroupNotifications: cancelGroupNotifications,
        );
      });
      await tester.pump();

      expect(setActiveChatCalls, ['group123']);
      expect(cancelNotificationsCalls, ['group123']);
      expect(clearActiveChatCallCount, 0);
    });

    testWidgets('clears active chat when app goes to paused', (tester) async {
      await mountHook(tester, () {
        useActiveChat(
          groupId: 'group123',
          setActiveChat: setActiveChat,
          clearActiveChat: clearActiveChat,
          cancelGroupNotifications: cancelGroupNotifications,
        );
      });

      clearActiveChatCallCount = 0;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(clearActiveChatCallCount, 1);
    });

    testWidgets('clears active chat when app goes to inactive', (tester) async {
      await mountHook(tester, () {
        useActiveChat(
          groupId: 'group123',
          setActiveChat: setActiveChat,
          clearActiveChat: clearActiveChat,
          cancelGroupNotifications: cancelGroupNotifications,
        );
      });

      clearActiveChatCallCount = 0;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(clearActiveChatCallCount, 1);
    });

    testWidgets('clears active chat when app goes to hidden', (tester) async {
      await mountHook(tester, () {
        useActiveChat(
          groupId: 'group123',
          setActiveChat: setActiveChat,
          clearActiveChat: clearActiveChat,
          cancelGroupNotifications: cancelGroupNotifications,
        );
      });

      clearActiveChatCallCount = 0;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();

      expect(clearActiveChatCallCount, 1);
    });

    testWidgets('clears active chat when app goes to detached', (tester) async {
      await mountHook(tester, () {
        useActiveChat(
          groupId: 'group123',
          setActiveChat: setActiveChat,
          clearActiveChat: clearActiveChat,
          cancelGroupNotifications: cancelGroupNotifications,
        );
      });

      clearActiveChatCallCount = 0;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
      await tester.pump();

      expect(clearActiveChatCallCount, 1);
    });

    testWidgets('restores active chat when app resumes', (tester) async {
      await mountHook(tester, () {
        useActiveChat(
          groupId: 'group123',
          setActiveChat: setActiveChat,
          clearActiveChat: clearActiveChat,
          cancelGroupNotifications: cancelGroupNotifications,
        );
      });

      setActiveChatCalls.clear();
      cancelNotificationsCalls.clear();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(setActiveChatCalls, ['group123']);
      expect(cancelNotificationsCalls, ['group123']);
    });

    testWidgets('cancels notifications when app resumes', (tester) async {
      await mountHook(tester, () {
        useActiveChat(
          groupId: 'group123',
          setActiveChat: setActiveChat,
          clearActiveChat: clearActiveChat,
          cancelGroupNotifications: cancelGroupNotifications,
        );
      });

      cancelNotificationsCalls.clear();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(cancelNotificationsCalls, ['group123']);
    });

    testWidgets('does not clear active chat on unmount to prevent navigation race condition', (
      tester,
    ) async {
      await mountHook(tester, () {
        useActiveChat(
          groupId: 'group123',
          setActiveChat: setActiveChat,
          clearActiveChat: clearActiveChat,
          cancelGroupNotifications: cancelGroupNotifications,
        );
      });

      setActiveChatCalls.clear();
      clearActiveChatCallCount = 0;
      cancelNotificationsCalls.clear();

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(setActiveChatCalls, isEmpty);
      expect(clearActiveChatCallCount, 0);
    });
  });
}
