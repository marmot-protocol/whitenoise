import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_chat_archive.dart';
import 'package:whitenoise/src/rust/api/account_groups.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  bool archivedAtResult = false;
  Completer<void>? archiveCompleter;
  Completer<void>? unarchiveCompleter;

  @override
  Future<AccountGroup> crateApiAccountGroupsGetAccountGroup({
    required String accountPubkey,
    required String mlsGroupId,
  }) async {
    getAccountGroupCallCount++;
    if (shouldFailGetAccountGroup) throw Exception('AccountGroup not found');
    return AccountGroup(
      accountPubkey: accountPubkey,
      mlsGroupId: mlsGroupId,
      archivedAt: archivedAtResult ? PlatformInt64Util.from(1000) : null,
      createdAt: PlatformInt64Util.from(0),
      updatedAt: PlatformInt64Util.from(0),
    );
  }

  @override
  Future<void> crateApiAccountGroupsArchiveChat({
    required String accountPubkey,
    required String mlsGroupId,
  }) async {
    archiveChatCallCount++;
    lastArchivedGroupId = mlsGroupId;
    if (archiveCompleter != null) await archiveCompleter!.future;
    if (shouldFailArchiveChat) throw Exception('archive_chat failed');
    archivedAtResult = true;
  }

  @override
  Future<void> crateApiAccountGroupsUnarchiveChat({
    required String accountPubkey,
    required String mlsGroupId,
  }) async {
    unarchiveChatCallCount++;
    lastUnarchivedGroupId = mlsGroupId;
    if (unarchiveCompleter != null) await unarchiveCompleter!.future;
    if (shouldFailUnarchiveChat) throw Exception('unarchive_chat failed');
    archivedAtResult = false;
  }

  @override
  void reset() {
    super.reset();
    archivedAtResult = false;
    archiveCompleter = null;
    unarchiveCompleter = null;
  }
}

final _api = _MockApi();

void main() {
  late ChatArchiveResult Function() getState;

  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  Future<void> pump(
    WidgetTester tester, {
    String accountPubkey = testPubkeyA,
    String mlsGroupId = testGroupId,
  }) async {
    getState = await mountHook(
      tester,
      () => useChatArchive(accountPubkey, mlsGroupId),
    );
  }

  group('useChatArchive', () {
    group('initial state', () {
      testWidgets('isLoading is true immediately after mount', (tester) async {
        await pump(tester);
        expect(getState().isLoading, isTrue);
        expect(getState().isArchived, isFalse);
        expect(getState().isActionLoading, isFalse);
      });

      testWidgets('isLoading becomes false after load completes', (tester) async {
        await pump(tester);
        await tester.pumpAndSettle();
        expect(getState().isLoading, isFalse);
      });

      testWidgets('isArchived is false when archivedAt is null', (tester) async {
        _api.archivedAtResult = false;
        await pump(tester);
        await tester.pumpAndSettle();

        expect(getState().isArchived, isFalse);
      });

      testWidgets('isArchived is true when archivedAt is set', (tester) async {
        _api.archivedAtResult = true;
        await pump(tester);
        await tester.pumpAndSettle();

        expect(getState().isArchived, isTrue);
      });

      testWidgets('keeps existing archive state when load fails', (tester) async {
        _api.shouldFailGetAccountGroup = true;
        await pump(tester);
        await tester.pumpAndSettle();

        expect(getState().isArchived, isFalse);
        expect(getState().isLoading, isFalse);
      });
    });

    group('archive action', () {
      testWidgets('sets isActionLoading while archive is running', (tester) async {
        _api.archivedAtResult = false;
        _api.archiveCompleter = Completer<void>();
        await pump(tester);
        await tester.pumpAndSettle();

        final archiveFuture = getState().archive();
        await tester.pump();
        expect(getState().isActionLoading, isTrue);

        _api.archiveCompleter!.complete();
        await archiveFuture;
        await tester.pumpAndSettle();
        expect(getState().isActionLoading, isFalse);
      });

      testWidgets('calls archiveChat and updates state to archived optimistically', (tester) async {
        _api.archivedAtResult = false;
        await pump(tester);
        await tester.pumpAndSettle();

        expect(getState().isArchived, isFalse);

        await getState().archive();
        await tester.pumpAndSettle();

        expect(_api.archiveChatCallCount, 1);
        expect(_api.lastArchivedGroupId, testGroupId);
        expect(_api.getAccountGroupCallCount, 1);
        expect(getState().isArchived, isTrue);
      });

      testWidgets('rolls back state and rethrows when archiveChat fails', (tester) async {
        _api.archivedAtResult = false;
        await pump(tester);
        await tester.pumpAndSettle();
        expect(getState().isLoading, isFalse);
        expect(getState().isArchived, isFalse);

        _api.shouldFailArchiveChat = true;
        await expectLater(getState().archive(), throwsA(isA<Exception>()));
        await tester.pumpAndSettle();
        expect(getState().isArchived, isFalse);
      });

      testWidgets('archive future completes without error if widget disposes before await', (
        tester,
      ) async {
        _api.archivedAtResult = false;
        _api.archiveCompleter = Completer<void>();
        await pump(tester);
        await tester.pumpAndSettle();

        final archiveFuture = getState().archive();
        await tester.pump();
        expect(getState().isActionLoading, isTrue);

        await tester.pumpWidget(const SizedBox());
        _api.archiveCompleter!.complete();
        await expectLater(archiveFuture, completes);
      });
    });

    group('unarchive action', () {
      testWidgets('calls unarchiveChat and updates state to not archived optimistically', (
        tester,
      ) async {
        _api.archivedAtResult = true;
        await pump(tester);
        await tester.pumpAndSettle();

        expect(getState().isArchived, isTrue);

        await getState().unarchive();
        await tester.pumpAndSettle();

        expect(_api.unarchiveChatCallCount, 1);
        expect(_api.lastUnarchivedGroupId, testGroupId);
        expect(_api.getAccountGroupCallCount, 1);
        expect(getState().isArchived, isFalse);
      });

      testWidgets('rolls back state and rethrows when unarchiveChat fails', (tester) async {
        _api.archivedAtResult = true;
        await pump(tester);
        await tester.pumpAndSettle();
        expect(getState().isLoading, isFalse);
        expect(getState().isArchived, isTrue);

        _api.shouldFailUnarchiveChat = true;
        await expectLater(getState().unarchive(), throwsA(isA<Exception>()));
        await tester.pumpAndSettle();
        expect(getState().isArchived, isTrue);
      });

      testWidgets('unarchive future completes without error if widget disposes before await', (
        tester,
      ) async {
        _api.archivedAtResult = true;
        _api.unarchiveCompleter = Completer<void>();
        await pump(tester);
        await tester.pumpAndSettle();

        final unarchiveFuture = getState().unarchive();
        await tester.pump();
        expect(getState().isActionLoading, isTrue);

        await tester.pumpWidget(const SizedBox());
        _api.unarchiveCompleter!.complete();
        await expectLater(unarchiveFuture, completes);
      });
    });
  });
}
