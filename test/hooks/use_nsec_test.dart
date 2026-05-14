import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_nsec.dart';
import 'package:whitenoise_frb/src/rust/api/accounts.dart';
import 'package:whitenoise_frb/src/rust/frb_generated.dart';

import '../test_helpers.dart';

class _MockApi implements RustLibApi {
  bool shouldThrow = false;
  bool shouldThrowGetAccount = false;
  AccountType accountType = AccountType.local;

  @override
  Future<String> crateApiAccountsExportAccountNsec({required String pubkey}) async {
    if (shouldThrow) {
      throw Exception('Export error');
    }
    return 'nsec1test${pubkey.substring(0, 10)}';
  }

  @override
  Future<Account> crateApiAccountsGetAccount({required String pubkey}) async {
    if (shouldThrowGetAccount) {
      throw Exception('getAccount failed');
    }
    return Account(
      pubkey: pubkey,
      accountType: accountType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

late ({NsecState nsecState}) result;

Future<void> _pump(WidgetTester tester, String? pubkey) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HookBuilder(
        builder: (context) {
          result = useNsec(pubkey);
          return const SizedBox();
        },
      ),
    ),
  );
}

void main() {
  late _MockApi mockApi;

  setUpAll(() {
    mockApi = _MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.shouldThrow = false;
    mockApi.shouldThrowGetAccount = false;
    mockApi.accountType = AccountType.local;
  });

  group('NsecState', () {
    test('copyWith preserves isLoading when not explicitly set', () {
      const state = NsecState(isLoading: true);
      final copied = state.copyWith(nsec: 'test_nsec');
      expect(copied.isLoading, isTrue);
      expect(copied.nsec, 'test_nsec');
    });

    test('copyWith can override isLoading', () {
      const state = NsecState(isLoading: true);
      final copied = state.copyWith(isLoading: false);
      expect(copied.isLoading, isFalse);
    });
  });

  group('useNsec', () {
    testWidgets('initial state with pubkey is already loading nsec', (tester) async {
      await _pump(tester, testPubkeyA);

      expect(result.nsecState.isLoading, isTrue);
    });

    testWidgets('loadNsec loads nsec successfully', (tester) async {
      await _pump(tester, testPubkeyA);
      await tester.pumpAndSettle();

      expect(result.nsecState.nsec, startsWith('nsec1'));
      expect(result.nsecState.isLoading, isFalse);
      expect(result.nsecState.error, isNull);
      expect(result.nsecState.nsecStorage, NsecStorage.local);
    });

    testWidgets('loadNsec handles errors', (tester) async {
      mockApi.shouldThrow = true;
      await _pump(tester, testPubkeyA);
      await tester.pumpAndSettle();

      expect(result.nsecState.nsec, isNull);
      expect(result.nsecState.isLoading, isFalse);
      expect(result.nsecState.error, equals('nsec_load_failed'));
    });

    testWidgets('state is cleared when pubkey changes', (tester) async {
      await _pump(tester, testPubkeyA);
      await tester.pumpAndSettle();

      expect(result.nsecState.nsec, isNotNull);
      expect(result.nsecState.nsec, startsWith('nsec1'));
      expect(result.nsecState.nsecStorage, NsecStorage.local);

      await _pump(tester, testPubkeyB);
      await tester.pumpAndSettle();

      expect(result.nsecState.nsec, startsWith('nsec1testb2c3d4e5f6'));
      expect(result.nsecState.isLoading, isFalse);
      expect(result.nsecState.error, isNull);
    });

    testWidgets('handles null pubkey gracefully', (tester) async {
      await _pump(tester, null);
      await tester.pump();

      expect(result.nsecState.nsec, isNull);
      expect(result.nsecState.isLoading, isFalse);
      expect(result.nsecState.error, isNull);
      expect(result.nsecState.nsecStorage, isNull);
    });

    testWidgets('loadNsec is no-op when pubkey is null', (tester) async {
      await _pump(tester, null);
      await tester.pumpAndSettle();

      expect(result.nsecState.nsec, isNull);
      expect(result.nsecState.isLoading, isFalse);
      expect(result.nsecState.error, isNull);
    });

    testWidgets('nsec remains null when error occurs on fresh state', (tester) async {
      mockApi.shouldThrow = true;
      await _pump(tester, testPubkeyA);
      await tester.pumpAndSettle();

      expect(result.nsecState.nsec, isNull);
      expect(result.nsecState.error, equals('nsec_load_failed'));
    });

    testWidgets('storage is local after effect settles when not external signer', (tester) async {
      await _pump(tester, testPubkeyA);
      await tester.pumpAndSettle();

      expect(result.nsecState.nsecStorage, NsecStorage.local);
    });

    testWidgets('storage is externalSigner when using external signer', (tester) async {
      mockApi.accountType = AccountType.external_;
      await _pump(tester, testPubkeyA);
      await tester.pumpAndSettle();

      expect(result.nsecState.nsecStorage, NsecStorage.externalSigner);
      expect(result.nsecState.nsec, isNull);
    });

    testWidgets('does not load nsec when storage is externalSigner', (tester) async {
      mockApi.accountType = AccountType.external_;
      await _pump(tester, testPubkeyA);
      await tester.pumpAndSettle();

      expect(result.nsecState.nsecStorage, NsecStorage.externalSigner);
      expect(result.nsecState.nsec, isNull);
      expect(result.nsecState.isLoading, isFalse);
    });

    testWidgets('falls back to local and completes when getAccount throws non-ApiError', (
      tester,
    ) async {
      mockApi.shouldThrowGetAccount = true;
      await _pump(tester, testPubkeyA);
      await tester.pumpAndSettle();

      expect(result.nsecState.isLoading, isFalse);
      expect(result.nsecState.nsecStorage, NsecStorage.local);
      expect(result.nsecState.nsec, startsWith('nsec1'));
      expect(result.nsecState.error, isNull);
    });
  });
}
