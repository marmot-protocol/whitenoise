import 'dart:async' show Completer, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_accounts.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockAuthNotifier extends AuthNotifier {
  String? _pubkey;
  bool shouldThrowOnSwitch = false;
  Completer<void>? switchProfileCompleter;

  _MockAuthNotifier(this._pubkey);

  @override
  Future<String?> build() async {
    if (_pubkey != null) {
      state = AsyncData(_pubkey);
    }
    return _pubkey;
  }

  @override
  Future<void> switchProfile(String pubkey) async {
    if (switchProfileCompleter != null) {
      await switchProfileCompleter!.future;
    }
    if (shouldThrowOnSwitch) {
      throw Exception('Switch failed');
    }
    _pubkey = pubkey;
    state = AsyncData(pubkey);
  }
}

class _TestWidget extends HookConsumerWidget {
  final String? currentPubkey;
  final void Function(
    AsyncSnapshot<List<Account>> accounts,
    AccountsState state,
    Future<void> Function(String) switchTo,
  )
  onBuild;

  const _TestWidget({
    required this.currentPubkey,
    required this.onBuild,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:accounts, :state, :switchTo) = useAccounts(context, ref, currentPubkey);
    onBuild(accounts, state, switchTo);
    return Column(
      children: [
        Text('connectionState: ${accounts.connectionState}'),
        Text('data: ${accounts.data?.length ?? 'null'}'),
        Text('isSwitching: ${state.isSwitching}'),
        Text('error: ${state.error ?? 'null'}'),
      ],
    );
  }
}

void main() {
  late MockWnApi mockApi;

  setUpAll(() {
    mockApi = MockWnApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
    mockApi.getAccountsCompleter = null;
    mockApi.accounts = [];
  });

  Future<void> mountTestWidget(
    WidgetTester tester, {
    required String currentPubkey,
    required void Function(
      AsyncSnapshot<List<Account>>,
      AccountsState,
      Future<void> Function(String),
    )
    onBuild,
  }) async {
    setUpTestView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(currentPubkey)),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: _TestWidget(
              currentPubkey: currentPubkey,
              onBuild: onBuild,
            ),
          ),
        ),
      ),
    );
  }

  group('AccountsState', () {
    test('copyWith preserves isSwitching when not provided', () {
      const state = AccountsState(isSwitching: true, error: 'test error');
      final newState = state.copyWith(error: 'new error');
      expect(newState.isSwitching, true);
      expect(newState.error, 'new error');
    });

    test('copyWith preserves error when not provided', () {
      const state = AccountsState(error: 'test error');
      final newState = state.copyWith(isSwitching: true);
      expect(newState.isSwitching, true);
      expect(newState.error, 'test error');
    });

    test('copyWith clears error when clearError is true', () {
      const state = AccountsState(isSwitching: true, error: 'test error');
      final newState = state.copyWith(clearError: true);
      expect(newState.isSwitching, true);
      expect(newState.error, isNull);
    });

    test('copyWith overrides all values when provided', () {
      const state = AccountsState(error: 'old error');
      final newState = state.copyWith(isSwitching: true, error: 'new error');
      expect(newState.isSwitching, true);
      expect(newState.error, 'new error');
    });
  });

  group('useAccounts', () {
    testWidgets('starts with waiting state', (tester) async {
      late AsyncSnapshot<List<Account>> capturedAccounts;
      mockApi.getAccountsCompleter = Completer<List<Account>>();

      await mountTestWidget(
        tester,
        currentPubkey: testPubkeyA,
        onBuild: (accounts, state, switchTo) {
          capturedAccounts = accounts;
        },
      );

      expect(capturedAccounts.connectionState, ConnectionState.waiting);
    });

    testWidgets('returns accounts when loaded', (tester) async {
      late AsyncSnapshot<List<Account>> capturedAccounts;
      mockApi.accounts = [
        Account(
          accountType: AccountType.local,
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Account(
          accountType: AccountType.local,
          pubkey: testPubkeyB,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await mountTestWidget(
        tester,
        currentPubkey: testPubkeyA,
        onBuild: (accounts, state, switchTo) {
          capturedAccounts = accounts;
        },
      );
      await tester.pumpAndSettle();

      expect(capturedAccounts.connectionState, ConnectionState.done);
      expect(capturedAccounts.data, isNotNull);
      expect(capturedAccounts.data!.length, 2);
      expect(capturedAccounts.data![0].pubkey, testPubkeyA);
      expect(capturedAccounts.data![1].pubkey, testPubkeyB);
    });

    testWidgets('returns empty list when no accounts', (tester) async {
      late AsyncSnapshot<List<Account>> capturedAccounts;
      mockApi.accounts = [];

      await mountTestWidget(
        tester,
        currentPubkey: testPubkeyA,
        onBuild: (accounts, state, switchTo) {
          capturedAccounts = accounts;
        },
      );
      await tester.pumpAndSettle();

      expect(capturedAccounts.connectionState, ConnectionState.done);
      expect(capturedAccounts.data, isNotNull);
      expect(capturedAccounts.data!.isEmpty, true);
    });

    testWidgets('starts with isSwitching false and no error', (tester) async {
      late AccountsState capturedState;
      mockApi.accounts = [];

      await mountTestWidget(
        tester,
        currentPubkey: testPubkeyA,
        onBuild: (accounts, state, switchTo) {
          capturedState = state;
        },
      );
      await tester.pumpAndSettle();

      expect(capturedState.isSwitching, false);
      expect(capturedState.error, isNull);
    });

    testWidgets('navigates back without switching when called with current pubkey', (
      tester,
    ) async {
      mockApi.accounts = [
        Account(
          accountType: AccountType.local,
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(testPubkeyA)),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
      );
      Routes.pushToSwitchProfile(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();

      expect(find.text('Profiles'), findsOneWidget);

      await tester.tap(find.text('Display $testPubkeyA'));
      await tester.pumpAndSettle();

      expect(find.text('Profiles'), findsNothing);
    });

    testWidgets('switchTo sets isSwitching true during operation and clears on success', (
      tester,
    ) async {
      final mockAuthNotifier = _MockAuthNotifier(testPubkeyA);
      mockAuthNotifier.switchProfileCompleter = Completer<void>();
      mockApi.accounts = [
        Account(
          accountType: AccountType.local,
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Account(
          accountType: AccountType.local,
          pubkey: testPubkeyB,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => mockAuthNotifier),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
      );
      Routes.pushToSettings(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();
      Routes.pushToSwitchProfile(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Display $testPubkeyB'));
      await tester.pump();

      expect(find.text('Profiles'), findsOneWidget);

      mockAuthNotifier.switchProfileCompleter!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Failed to switch profile. Please try again.'), findsNothing);
    });

    testWidgets('sets error state when switchProfile throws', (tester) async {
      late Future<void> Function(String) capturedSwitchTo;
      late AccountsState capturedState;
      final mockAuthNotifier = _MockAuthNotifier(testPubkeyA);
      mockAuthNotifier.shouldThrowOnSwitch = true;
      mockApi.accounts = [
        Account(
          accountType: AccountType.local,
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Account(
          accountType: AccountType.local,
          pubkey: testPubkeyB,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      setUpTestView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => mockAuthNotifier),
            secureStorageProvider.overrideWithValue(MockSecureStorage()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: _TestWidget(
                currentPubkey: testPubkeyA,
                onBuild: (accounts, state, switchTo) {
                  capturedSwitchTo = switchTo;
                  capturedState = state;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await capturedSwitchTo(testPubkeyB);
      await tester.pumpAndSettle();

      expect(capturedState.error, isNotNull);
      expect(capturedState.error, 'Failed to switch profile. Please try again.');
      expect(capturedState.isSwitching, false);
    });

    testWidgets('clears error when retrying switchTo', (tester) async {
      late Future<void> Function(String) capturedSwitchTo;
      late AccountsState capturedState;
      final mockAuthNotifier = _MockAuthNotifier(testPubkeyA);
      mockAuthNotifier.shouldThrowOnSwitch = true;
      mockApi.accounts = [
        Account(
          accountType: AccountType.local,
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Account(
          accountType: AccountType.local,
          pubkey: testPubkeyB,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      setUpTestView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => mockAuthNotifier),
            secureStorageProvider.overrideWithValue(MockSecureStorage()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: _TestWidget(
                currentPubkey: testPubkeyA,
                onBuild: (accounts, state, switchTo) {
                  capturedSwitchTo = switchTo;
                  capturedState = state;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await capturedSwitchTo(testPubkeyB);
      await tester.pumpAndSettle();
      expect(capturedState.error, isNotNull);
      expect(capturedState.isSwitching, false);

      mockAuthNotifier.shouldThrowOnSwitch = false;
      mockAuthNotifier.switchProfileCompleter = Completer<void>();
      unawaited(capturedSwitchTo(testPubkeyB));
      await tester.pump();

      expect(capturedState.error, isNull);
      expect(capturedState.isSwitching, true);

      mockAuthNotifier.switchProfileCompleter!.complete();
      await tester.pumpAndSettle();
    });
  });
}
