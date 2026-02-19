import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_user_selection.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import '../test_helpers.dart';

User _createTestUser(String pubkey, {String? name}) {
  return User(
    pubkey: pubkey,
    metadata: FlutterMetadata(
      name: name,
      displayName: name,
      custom: const {},
    ),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

void main() {
  group('useUserSelection', () {
    testWidgets('initializes with empty selection', (tester) async {
      late UserSelectionState state;

      await mountHook(
        tester,
        () {
          final result = useUserSelection();
          state = result.state;
          return Container();
        },
      );

      expect(state.selectedUsers, isEmpty);
      expect(state.selectedCount, 0);
    });

    testWidgets('initializes with initial users', (tester) async {
      final initialUsers = [
        _createTestUser(testPubkeyA, name: 'Alice'),
        _createTestUser(testPubkeyB, name: 'Bob'),
      ];

      late UserSelectionState state;

      await mountHook(
        tester,
        () {
          final result = useUserSelection(initialUsers: initialUsers);
          state = result.state;
          return Container();
        },
      );

      expect(state.selectedUsers, hasLength(2));
      expect(state.selectedCount, 2);
    });

    testWidgets('toggleUser adds user when not selected', (tester) async {
      late UserSelectionState state;
      late UserSelectionActions actions;

      await mountHook(
        tester,
        () {
          final result = useUserSelection();
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      final user = _createTestUser(testPubkeyA, name: 'Alice');
      actions.toggleUser(user);
      await tester.pump();

      expect(state.selectedUsers, hasLength(1));
      expect(state.selectedUsers.first.pubkey, testPubkeyA);
      expect(state.isSelected(user), isTrue);
    });

    testWidgets('toggleUser removes user when already selected', (tester) async {
      final initialUser = _createTestUser(testPubkeyA, name: 'Alice');
      late UserSelectionState state;
      late UserSelectionActions actions;

      await mountHook(
        tester,
        () {
          final result = useUserSelection(initialUsers: [initialUser]);
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      expect(state.selectedUsers, hasLength(1));

      actions.toggleUser(initialUser);
      await tester.pump();

      expect(state.selectedUsers, isEmpty);
      expect(state.isSelected(initialUser), isFalse);
    });

    testWidgets('toggleUser handles multiple users', (tester) async {
      late UserSelectionState state;
      late UserSelectionActions actions;

      await mountHook(
        tester,
        () {
          final result = useUserSelection();
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      final user1 = _createTestUser(testPubkeyA, name: 'Alice');
      final user2 = _createTestUser(testPubkeyB, name: 'Bob');
      final user3 = _createTestUser(testPubkeyC, name: 'Charlie');

      actions.toggleUser(user1);
      await tester.pump();
      expect(state.selectedUsers, hasLength(1));

      actions.toggleUser(user2);
      await tester.pump();
      expect(state.selectedUsers, hasLength(2));

      actions.toggleUser(user3);
      await tester.pump();
      expect(state.selectedUsers, hasLength(3));

      actions.toggleUser(user2);
      await tester.pump();
      expect(state.selectedUsers, hasLength(2));
      expect(state.isSelected(user1), isTrue);
      expect(state.isSelected(user2), isFalse);
      expect(state.isSelected(user3), isTrue);
    });

    testWidgets('setUsers replaces all selected users', (tester) async {
      final initialUser = _createTestUser(testPubkeyA, name: 'Alice');
      late UserSelectionState state;
      late UserSelectionActions actions;

      await mountHook(
        tester,
        () {
          final result = useUserSelection(initialUsers: [initialUser]);
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      expect(state.selectedUsers, hasLength(1));

      final newUsers = [
        _createTestUser(testPubkeyB, name: 'Bob'),
        _createTestUser(testPubkeyC, name: 'Charlie'),
      ];

      actions.setUsers(newUsers);
      await tester.pump();

      expect(state.selectedUsers, hasLength(2));
      expect(state.selectedUsers[0].pubkey, testPubkeyB);
      expect(state.selectedUsers[1].pubkey, testPubkeyC);
    });

    testWidgets('clearSelection removes all users', (tester) async {
      final initialUsers = [
        _createTestUser(testPubkeyA, name: 'Alice'),
        _createTestUser(testPubkeyB, name: 'Bob'),
      ];

      late UserSelectionState state;
      late UserSelectionActions actions;

      await mountHook(
        tester,
        () {
          final result = useUserSelection(initialUsers: initialUsers);
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      expect(state.selectedUsers, hasLength(2));

      actions.clearSelection();
      await tester.pump();

      expect(state.selectedUsers, isEmpty);
      expect(state.selectedCount, 0);
    });

    testWidgets('isSelected returns correct value', (tester) async {
      final user1 = _createTestUser(testPubkeyA, name: 'Alice');
      final user2 = _createTestUser(testPubkeyB, name: 'Bob');

      late UserSelectionState state;

      await mountHook(
        tester,
        () {
          final result = useUserSelection(initialUsers: [user1]);
          state = result.state;
          return Container();
        },
      );

      expect(state.isSelected(user1), isTrue);
      expect(state.isSelected(user2), isFalse);
    });
  });
}
