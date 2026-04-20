import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/constants/nostr_event_kinds.dart';
import 'package:whitenoise/hooks/use_key_packages.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../test_helpers.dart';

class MockApi implements RustLibApi {
  List<FlutterEvent> keyPackages = [];
  bool shouldThrow = false;
  bool shouldThrowOnRefresh = false;
  Completer<void>? publishCompleter;
  Completer<void>? fetchCompleter;
  Completer<void>? deleteCompleter;
  Completer<void>? deleteAllLegacyCompleter;

  @override
  Future<List<FlutterEvent>> crateApiAccountsAccountKeyPackages({
    required String accountPubkey,
  }) async {
    if (fetchCompleter != null) {
      await fetchCompleter!.future;
    }
    if (shouldThrow || shouldThrowOnRefresh) throw Exception('Network error');
    return keyPackages;
  }

  @override
  Future<void> crateApiAccountsPublishAccountKeyPackage({
    required String accountPubkey,
  }) async {
    if (publishCompleter != null) {
      await publishCompleter!.future;
    }
    if (shouldThrow) throw Exception('Network error');
    keyPackages.add(
      FlutterEvent(
        id: 'pkg_${keyPackages.length + 1}',
        pubkey: accountPubkey,
        createdAt: DateTime.now(),
        kind: NostrEventKinds.mlsKeyPackage,
        tags: const [],
        content: '',
      ),
    );
  }

  @override
  Future<bool> crateApiAccountsDeleteAccountKeyPackage({
    required String accountPubkey,
    required String keyPackageId,
  }) async {
    if (deleteCompleter != null) {
      await deleteCompleter!.future;
    }
    if (shouldThrow) throw Exception('Network error');
    keyPackages.removeWhere((p) => p.id == keyPackageId);
    return true;
  }

  @override
  Future<BigInt> crateApiAccountsDeleteAccountKeyPackages({
    required String accountPubkey,
  }) async {
    if (deleteAllLegacyCompleter != null) {
      await deleteAllLegacyCompleter!.future;
    }
    if (shouldThrow) throw Exception('Network error');
    final count = keyPackages.where((p) => p.kind == NostrEventKinds.mlsKeyPackageLegacy).length;
    keyPackages.removeWhere((p) => p.kind == NostrEventKinds.mlsKeyPackageLegacy);
    return BigInt.from(count);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

late ({
  KeyPackagesState state,
  Future<KeyPackageResult> Function() fetch,
  Future<KeyPackageResult> Function() publish,
  Future<KeyPackageResult> Function(String id) delete,
  Future<KeyPackageResult> Function() deleteAllLegacy,
})
hook;

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HookBuilder(
        builder: (context) {
          hook = useKeyPackages(testPubkeyA);
          return const SizedBox();
        },
      ),
    ),
  );
}

late MockApi mockApi;

void main() {
  setUpAll(() {
    mockApi = MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.keyPackages = [];
    mockApi.shouldThrow = false;
    mockApi.shouldThrowOnRefresh = false;
    mockApi.publishCompleter = null;
    mockApi.fetchCompleter = null;
    mockApi.deleteCompleter = null;
    mockApi.deleteAllLegacyCompleter = null;
  });

  group('fetch', () {
    testWidgets('loads packages from API', (tester) async {
      mockApi.keyPackages = [
        FlutterEvent(
          id: 'pkg1',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackage,
          tags: [],
          content: '',
        ),
      ];

      await _pump(tester);
      await hook.fetch();
      await tester.pump();

      expect(hook.state.packages.length, 1);
    });

    testWidgets('sets activeAction to fetch while loading', (tester) async {
      mockApi.fetchCompleter = Completer<void>();

      await _pump(tester);
      final future = hook.fetch();
      await tester.pump();

      expect(hook.state.isLoading, isTrue);
      expect(hook.state.activeAction, KeyPackageAction.fetch);

      mockApi.fetchCompleter!.complete();
      await future;
      await tester.pump();

      expect(hook.state.isLoading, isFalse);
      expect(hook.state.activeAction, isNull);
    });

    testWidgets('sets error on failure', (tester) async {
      mockApi.shouldThrow = true;

      await _pump(tester);
      await hook.fetch();
      await tester.pump();

      expect(hook.state.hasError, isTrue);
      expect(hook.state.activeAction, isNull);
    });
  });

  group('publish', () {
    testWidgets('refreshes packages after publish', (tester) async {
      await _pump(tester);
      await hook.publish();
      await tester.pump();
      expect(hook.state.isLoading, isFalse);
      expect(hook.state.packages.length, 1);
    });

    testWidgets('sets activeAction to publish while loading', (tester) async {
      mockApi.publishCompleter = Completer<void>();

      await _pump(tester);
      final future = hook.publish();
      await tester.pump();

      expect(hook.state.isLoading, isTrue);
      expect(hook.state.activeAction, KeyPackageAction.publish);

      mockApi.publishCompleter!.complete();
      await future;
      await tester.pump();

      expect(hook.state.isLoading, isFalse);
      expect(hook.state.activeAction, isNull);
    });

    testWidgets('sets error on failure', (tester) async {
      mockApi.shouldThrow = true;

      await _pump(tester);
      await hook.publish();
      await tester.pump();

      expect(hook.state.hasError, isTrue);
      expect(hook.state.activeAction, isNull);
    });

    testWidgets('returns success when publish succeeds but refresh fails', (tester) async {
      mockApi.shouldThrowOnRefresh = true;

      await _pump(tester);
      final result = await hook.publish();
      await tester.pump();

      expect(result.success, isTrue);
      expect(hook.state.isLoading, isFalse);
      expect(hook.state.hasError, isFalse);
    });
  });

  group('delete', () {
    testWidgets('removes package and refreshes list', (tester) async {
      mockApi.keyPackages = [
        FlutterEvent(
          id: 'pkg1',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackage,
          tags: [],
          content: '',
        ),
      ];

      await _pump(tester);
      await hook.fetch();
      await tester.pump();

      expect(hook.state.packages.length, 1);

      await hook.delete('pkg1');
      await tester.pump();

      expect(hook.state.packages, isEmpty);
    });

    testWidgets('does not execute when isLoading is true', (tester) async {
      mockApi.keyPackages = [
        FlutterEvent(
          id: 'pkg1',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackage,
          tags: [],
          content: '',
        ),
      ];

      await _pump(tester);
      await hook.fetch();
      await tester.pump();
      expect(hook.state.packages.length, 1);

      final completer = Completer<void>();
      mockApi.publishCompleter = completer;
      unawaited(hook.publish());
      await tester.pump();
      expect(hook.state.isLoading, isTrue);

      await hook.delete('pkg1');
      completer.complete();
      await tester.pump();
      await hook.fetch();
      await tester.pump();

      expect(hook.state.packages.length, 2);
    });

    testWidgets('sets error on failure', (tester) async {
      mockApi.keyPackages = [
        FlutterEvent(
          id: 'pkg1',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackage,
          tags: [],
          content: '',
        ),
      ];

      await _pump(tester);
      await hook.fetch();
      await tester.pump();

      mockApi.shouldThrow = true;
      await hook.delete('pkg1');
      await tester.pump();

      expect(hook.state.hasError, isTrue);
    });

    testWidgets('returns failure when delete succeeds but refresh fails', (tester) async {
      mockApi.keyPackages = [
        FlutterEvent(
          id: 'pkg1',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackage,
          tags: [],
          content: '',
        ),
      ];

      await _pump(tester);
      await hook.fetch();
      await tester.pump();
      expect(hook.state.packages.length, 1);

      mockApi.shouldThrowOnRefresh = true;
      final result = await hook.delete('pkg1');
      await tester.pump();

      expect(result.success, isFalse);
      expect(result.action, KeyPackageAction.delete);
      expect(hook.state.isLoading, isFalse);
    });

    testWidgets('sets deletingId while deleting specific package', (tester) async {
      mockApi.keyPackages = [
        FlutterEvent(
          id: 'pkg1',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackage,
          tags: [],
          content: '',
        ),
        FlutterEvent(
          id: 'pkg2',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackage,
          tags: [],
          content: '',
        ),
      ];

      await _pump(tester);
      await hook.fetch();
      await tester.pump();

      final deleteCompleter = Completer<void>();
      mockApi.deleteCompleter = deleteCompleter;

      final future = hook.delete('pkg1');
      await tester.pump();

      expect(hook.state.deletingId, 'pkg1');
      expect(hook.state.isLoading, isTrue);

      deleteCompleter.complete();
      await future;
      await tester.pump();

      expect(hook.state.deletingId, isNull);
      expect(hook.state.isLoading, isFalse);
    });
  });

  group('hasLegacyPackages', () {
    testWidgets('is false when packages list is empty', (tester) async {
      await _pump(tester);
      await hook.fetch();
      await tester.pump();

      expect(hook.state.hasLegacyPackages, isFalse);
    });

    testWidgets('is false when all packages are current kind', (tester) async {
      mockApi.keyPackages = [
        FlutterEvent(
          id: 'pkg1',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackage,
          tags: const [],
          content: '',
        ),
      ];

      await _pump(tester);
      await hook.fetch();
      await tester.pump();

      expect(hook.state.hasLegacyPackages, isFalse);
    });

    testWidgets('is true when any package is legacy kind', (tester) async {
      mockApi.keyPackages = [
        FlutterEvent(
          id: 'pkg1',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackage,
          tags: const [],
          content: '',
        ),
        FlutterEvent(
          id: 'pkg2',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackageLegacy,
          tags: const [],
          content: '',
        ),
      ];

      await _pump(tester);
      await hook.fetch();
      await tester.pump();

      expect(hook.state.hasLegacyPackages, isTrue);
    });
  });

  group('copyWith', () {
    test('preserves status when not provided', () {
      const state = KeyPackagesState(status: KeyPackagesLoading(KeyPackageAction.fetch));
      final newState = state.copyWith(packages: []);

      expect(newState.isLoading, isTrue);
      expect(newState.activeAction, KeyPackageAction.fetch);
    });

    test('transitions from loading to idle', () {
      const state = KeyPackagesState(status: KeyPackagesLoading(KeyPackageAction.fetch));
      final newState = state.copyWith(status: const KeyPackagesIdle());

      expect(newState.isLoading, isFalse);
      expect(newState.activeAction, isNull);
    });

    test('transitions from loading to error', () {
      const state = KeyPackagesState(status: KeyPackagesLoading(KeyPackageAction.publish));
      final newState = state.copyWith(status: const KeyPackagesError());

      expect(newState.hasError, isTrue);
      expect(newState.activeAction, isNull);
    });
  });

  group('deleteAllLegacy', () {
    testWidgets('removes only legacy packages and keeps current ones', (tester) async {
      mockApi.keyPackages = [
        FlutterEvent(
          id: 'pkg_legacy',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackageLegacy,
          tags: const [],
          content: '',
        ),
        FlutterEvent(
          id: 'pkg_current',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackage,
          tags: const [],
          content: '',
        ),
      ];

      await _pump(tester);
      await hook.fetch();
      await tester.pump();
      expect(hook.state.packages.length, 2);

      await hook.deleteAllLegacy();
      await tester.pump();

      expect(hook.state.packages.length, 1);
      expect(hook.state.packages.first.id, 'pkg_current');
      expect(hook.state.packages.first.kind, NostrEventKinds.mlsKeyPackage);
    });

    testWidgets('sets activeAction to deleteAllLegacy while loading', (tester) async {
      mockApi.deleteAllLegacyCompleter = Completer<void>();

      await _pump(tester);
      final future = hook.deleteAllLegacy();
      await tester.pump();

      expect(hook.state.isLoading, isTrue);
      expect(hook.state.activeAction, KeyPackageAction.deleteAllLegacy);

      mockApi.deleteAllLegacyCompleter!.complete();
      await future;
      await tester.pump();

      expect(hook.state.isLoading, isFalse);
      expect(hook.state.activeAction, isNull);
    });

    testWidgets('sets error on failure', (tester) async {
      mockApi.shouldThrow = true;

      await _pump(tester);
      await hook.deleteAllLegacy();
      await tester.pump();

      expect(hook.state.hasError, isTrue);
      expect(hook.state.activeAction, isNull);
    });

    testWidgets('returns fetch failure when delete succeeds but refresh fails', (tester) async {
      mockApi.keyPackages = [
        FlutterEvent(
          id: 'pkg1',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackageLegacy,
          tags: const [],
          content: '',
        ),
      ];

      await _pump(tester);
      await hook.fetch();
      await tester.pump();

      mockApi.shouldThrowOnRefresh = true;
      final result = await hook.deleteAllLegacy();
      await tester.pump();

      expect(result.success, isFalse);
      expect(result.action, KeyPackageAction.fetch);
      expect(hook.state.isLoading, isFalse);
      expect(hook.state.hasError, isFalse);
    });
  });
}
