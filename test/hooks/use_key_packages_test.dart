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
  Completer<void>? publishCompleter;

  @override
  Future<List<FlutterEvent>> crateApiAccountsAccountKeyPackages({
    required String accountPubkey,
  }) async {
    if (shouldThrow) throw Exception('Network error');
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
        tags: [],
        content: '',
      ),
    );
  }

  @override
  Future<bool> crateApiAccountsDeleteAccountKeyPackage({
    required String accountPubkey,
    required String keyPackageId,
  }) async {
    if (shouldThrow) throw Exception('Network error');
    keyPackages.removeWhere((p) => p.id == keyPackageId);
    return true;
  }

  @override
  Future<BigInt> crateApiAccountsDeleteAccountKeyPackages({
    required String accountPubkey,
  }) async {
    if (shouldThrow) throw Exception('Network error');
    final count = keyPackages.length;
    keyPackages.clear();
    return BigInt.from(count);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

late ({
  KeyPackagesState state,
  Future<void> Function() fetch,
  Future<void> Function() publish,
  Future<void> Function(String id) delete,
  Future<void> Function() deleteAll,
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
    mockApi.publishCompleter = null;
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

    testWidgets('sets error on failure', (tester) async {
      mockApi.shouldThrow = true;

      await _pump(tester);
      await hook.fetch();
      await tester.pump();

      expect(hook.state.hasError, isTrue);
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

    testWidgets('sets error on failure', (tester) async {
      mockApi.shouldThrow = true;

      await _pump(tester);
      await hook.publish();
      await tester.pump();

      expect(hook.state.hasError, isTrue);
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
  });

  group('copyWith', () {
    test('preserves isLoading when not provided', () {
      const state = KeyPackagesState(isLoading: true);
      final newState = state.copyWith(packages: []);

      expect(newState.isLoading, isTrue);
    });
  });

  group('deleteAll', () {
    testWidgets('clears all packages', (tester) async {
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
      expect(hook.state.packages.length, 2);
      await hook.deleteAll();
      await tester.pump();

      expect(hook.state.packages, isEmpty);
    });

    testWidgets('sets error on failure', (tester) async {
      mockApi.shouldThrow = true;

      await _pump(tester);
      await hook.deleteAll();
      await tester.pump();

      expect(hook.state.hasError, isTrue);
    });
  });
}
