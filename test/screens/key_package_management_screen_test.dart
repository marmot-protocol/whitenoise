import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/constants/nostr_event_kinds.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/providers/offline_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_scroll_edge_effect.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  List<FlutterEvent> keyPackages = [];
  String? deletedKeyPackageId;
  bool shouldThrowOnFetch = false;
  bool shouldThrowOnPublish = false;
  bool shouldThrowOnDeleteAll = false;
  bool shouldThrowOnDelete = false;
  bool shouldThrowOnRefreshAfterDelete = false;
  Completer<List<FlutterEvent>>? fetchCompleter;
  Completer<bool>? deleteKeyPackageCompleter;
  int keyPackagesFetchCallCount = 0;
  int keyPackagesPublishCallCount = 0;
  int keyPackagesDeleteAllCallCount = 0;

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async => const FlutterMetadata(name: 'Test', custom: {});

  @override
  Future<List<FlutterEvent>> crateApiAccountsAccountKeyPackages({
    required String accountPubkey,
  }) async {
    keyPackagesFetchCallCount++;
    if (fetchCompleter != null) {
      return fetchCompleter!.future;
    }
    if (shouldThrowOnFetch || shouldThrowOnRefreshAfterDelete) {
      throw Exception('Network error');
    }
    return keyPackages;
  }

  @override
  Future<void> crateApiAccountsPublishAccountKeyPackage({
    required String accountPubkey,
  }) async {
    keyPackagesPublishCallCount++;
    if (shouldThrowOnPublish) {
      throw Exception('publish error');
    }
  }

  @override
  Future<bool> crateApiAccountsDeleteAccountKeyPackage({
    required String accountPubkey,
    required String keyPackageId,
  }) async {
    if (shouldThrowOnDelete) {
      throw Exception('delete error');
    }
    deletedKeyPackageId = keyPackageId;
    if (deleteKeyPackageCompleter != null) {
      return deleteKeyPackageCompleter!.future;
    }
    return true;
  }

  @override
  Future<BigInt> crateApiAccountsDeleteAccountKeyPackages({
    required String accountPubkey,
  }) async {
    keyPackagesDeleteAllCallCount++;
    if (shouldThrowOnDeleteAll) {
      throw Exception('delete all error');
    }
    return BigInt.from(keyPackages.length);
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}

List<FlutterEvent> _manyKeyPackages(int count) {
  return List.generate(
    count,
    (i) => FlutterEvent(
      id: 'pkg${i + 1}',
      pubkey: testPubkeyA,
      createdAt: DateTime.now(),
      kind: NostrEventKinds.mlsKeyPackage,
      tags: const [],
      content: '',
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
    mockApi.reset();
    mockApi.keyPackages = [];
    mockApi.deletedKeyPackageId = null;
    mockApi.shouldThrowOnFetch = false;
    mockApi.shouldThrowOnPublish = false;
    mockApi.shouldThrowOnDeleteAll = false;
    mockApi.shouldThrowOnDelete = false;
    mockApi.shouldThrowOnRefreshAfterDelete = false;
    mockApi.fetchCompleter = null;
    mockApi.deleteKeyPackageCompleter = null;
    mockApi.keyPackagesFetchCallCount = 0;
    mockApi.keyPackagesPublishCallCount = 0;
    mockApi.keyPackagesDeleteAllCallCount = 0;
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );
    Routes.pushToKeyPackageManagement(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('KeyPackageManagementScreen', () {
    testWidgets('displays title and action buttons', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Key Package Management'), findsOneWidget);
      expect(find.text('Publish New Key Package'), findsOneWidget);
      expect(find.text('Refresh Key Packages'), findsOneWidget);
      expect(find.text('Delete All Key Packages'), findsOneWidget);
    });

    testWidgets('displays empty state when no packages', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Key Packages (0)'), findsOneWidget);
      expect(find.text('No key packages found'), findsOneWidget);
    });

    testWidgets('displays key packages when available', (tester) async {
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

      await pumpScreen(tester);

      expect(find.text('Package 1'), findsOneWidget);
    });

    testWidgets('tapping back icon returns to previous screen', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();

      expect(find.text('Key Package Management'), findsNothing);
    });

    testWidgets('notice auto-dismisses after success', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Publish New Key Package'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Key package published'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Key package published'), findsNothing);
    });

    testWidgets('publish success shows notice', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Publish New Key Package'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Key package published'), findsOneWidget);
    });

    testWidgets('publish error shows message', (tester) async {
      mockApi.shouldThrowOnPublish = true;
      await pumpScreen(tester);

      await tester.tap(find.text('Publish New Key Package'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(
        find.text('Failed to publish key package. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('refresh success shows notice', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Refresh Key Packages'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Key packages refreshed'), findsOneWidget);
    });

    testWidgets('refresh error shows message', (tester) async {
      await pumpScreen(tester);
      mockApi.shouldThrowOnFetch = true;

      await tester.tap(find.text('Refresh Key Packages'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(
        find.text('Failed to refresh key packages. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('delete all success shows notice', (tester) async {
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
      await pumpScreen(tester);

      await tester.tap(find.text('Delete All Key Packages'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('All key packages deleted'), findsOneWidget);
    });

    testWidgets('delete all error shows message', (tester) async {
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
      mockApi.shouldThrowOnDeleteAll = true;
      await pumpScreen(tester);

      await tester.tap(find.text('Delete All Key Packages'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(
        find.text('Failed to delete all key packages. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('delete key package uses expected id', (tester) async {
      mockApi.keyPackages = [
        FlutterEvent(
          id: 'pkg_to_delete',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackage,
          tags: const [],
          content: '',
        ),
      ];
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('delete_key_package_pkg_to_delete')));
      await tester.pump();

      expect(mockApi.deletedKeyPackageId, 'pkg_to_delete');
    });

    testWidgets('delete key package error shows message', (tester) async {
      mockApi.keyPackages = [
        FlutterEvent(
          id: 'pkg_to_delete',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackage,
          tags: const [],
          content: '',
        ),
      ];
      mockApi.shouldThrowOnDelete = true;
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('delete_key_package_pkg_to_delete')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(
        find.text('Failed to delete key package. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error message on initial fetch failure', (tester) async {
      mockApi.shouldThrowOnFetch = true;

      await pumpScreen(tester);

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(
        find.text('Failed to refresh key packages. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows scroll edge effects for many key packages', (tester) async {
      mockApi.keyPackages = _manyKeyPackages(12);

      await pumpScreen(tester);
      await tester.pumpAndSettle();

      final effect = tester.widget<WnScrollEdgeEffect>(find.byType(WnScrollEdgeEffect).first);
      expect(effect.position, ScrollEdgePosition.bottom);
      expect(effect.type, ScrollEdgeEffectType.slate);
    });

    testWidgets('handles scroll notifications while list is scrolled', (tester) async {
      mockApi.keyPackages = _manyKeyPackages(20);

      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('no error notice during initial loading', (tester) async {
      mockApi.fetchCompleter = Completer<List<FlutterEvent>>();

      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier()),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
      );
      Routes.pushToKeyPackageManagement(tester.element(find.byType(Scaffold)));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(WnSystemNotice), findsNothing);

      mockApi.fetchCompleter!.complete([]);
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsNothing);
    });

    testWidgets('shows loading indicator while refreshing packages', (tester) async {
      await pumpScreen(tester);

      mockApi.fetchCompleter = Completer<List<FlutterEvent>>();

      await tester.tap(find.text('Refresh Key Packages'));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('loading_indicator')), findsOneWidget);

      mockApi.fetchCompleter!.complete([]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loading_indicator')), findsNothing);
    });

    testWidgets('delete button shows loading indicator while deleting', (tester) async {
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
          kind: NostrEventKinds.mlsKeyPackage,
          tags: const [],
          content: '',
        ),
      ];
      mockApi.deleteKeyPackageCompleter = Completer<bool>();
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('delete_key_package_pkg1')));
      await tester.pump();

      final pkg1Card = find.byKey(const Key('key_package_card_pkg1'));
      final pkg2Card = find.byKey(const Key('key_package_card_pkg2'));

      final loadingInPkg1 = find.descendant(
        of: pkg1Card,
        matching: find.byKey(const Key('loading_indicator')),
      );
      expect(loadingInPkg1, findsOneWidget);

      final loadingInPkg2 = find.descendant(
        of: pkg2Card,
        matching: find.byKey(const Key('loading_indicator')),
      );
      expect(loadingInPkg2, findsNothing);

      mockApi.deleteKeyPackageCompleter!.complete(true);
      await tester.pumpAndSettle();
    });

    testWidgets('shows error when delete succeeds but refresh fails', (tester) async {
      mockApi.keyPackages = [
        FlutterEvent(
          id: 'pkg_to_delete',
          pubkey: testPubkeyA,
          createdAt: DateTime.now(),
          kind: NostrEventKinds.mlsKeyPackage,
          tags: const [],
          content: '',
        ),
      ];
      await pumpScreen(tester);

      mockApi.shouldThrowOnRefreshAfterDelete = true;

      await tester.tap(find.byKey(const Key('delete_key_package_pkg_to_delete')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(
        find.text('Failed to delete key package. Please try again.'),
        findsOneWidget,
      );
    });

    group('when offline', () {
      testWidgets('does not fetch key packages on initial offline mount', (tester) async {
        await mountTestApp(
          tester,
          overrides: [
            authProvider.overrideWith(() => _MockAuthNotifier()),
            secureStorageProvider.overrideWithValue(MockSecureStorage()),
            offlineProvider.overrideWith((ref) => Stream.value(true)),
          ],
        );
        await tester.pumpAndSettle();
        Routes.pushToKeyPackageManagement(tester.element(find.byType(Scaffold)));
        await tester.pumpAndSettle();

        expect(mockApi.keyPackagesFetchCallCount, 0);
        expect(find.byKey(const Key('offline_notice')), findsOneWidget);
        expect(find.text('No key packages found'), findsOneWidget);
      });

      testWidgets(
        'disables screen actions and key package delete after transitioning to offline',
        (tester) async {
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
          final offlineStream = StreamController<bool>();
          addTearDown(offlineStream.close);

          await mountTestApp(
            tester,
            overrides: [
              authProvider.overrideWith(() => _MockAuthNotifier()),
              secureStorageProvider.overrideWithValue(MockSecureStorage()),
              offlineProvider.overrideWith((ref) => offlineStream.stream),
            ],
          );
          offlineStream.add(false);
          await tester.pumpAndSettle();
          Routes.pushToKeyPackageManagement(tester.element(find.byType(Scaffold)));
          await tester.pumpAndSettle();

          offlineStream.add(true);
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('offline_notice')), findsOneWidget);

          WnButton findWnButtonByLabel(String label) => tester.widget<WnButton>(
            find.ancestor(of: find.text(label), matching: find.byType(WnButton)),
          );

          expect(findWnButtonByLabel('Refresh Key Packages').disabled, isTrue);
          expect(findWnButtonByLabel('Publish New Key Package').disabled, isTrue);
          expect(findWnButtonByLabel('Delete All Key Packages').disabled, isTrue);
          expect(
            tester.widget<WnButton>(find.byKey(const Key('delete_key_package_pkg1'))).disabled,
            isTrue,
          );
        },
      );
    });
  });
}
