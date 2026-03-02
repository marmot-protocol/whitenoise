import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/constants/nostr_event_kinds.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/developer_settings_screen.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_scroll_edge_effect.dart';

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

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async => const FlutterMetadata(name: 'Test', custom: {});

  @override
  Future<List<FlutterEvent>> crateApiAccountsAccountKeyPackages({
    required String accountPubkey,
  }) async {
    if (shouldThrowOnFetch) throw Exception('Network error');
    return keyPackages;
  }

  @override
  Future<void> crateApiAccountsPublishAccountKeyPackage({
    required String accountPubkey,
  }) async {
    if (shouldThrowOnPublish) throw Exception('publish error');
  }

  @override
  Future<bool> crateApiAccountsDeleteAccountKeyPackage({
    required String accountPubkey,
    required String keyPackageId,
  }) async {
    if (shouldThrowOnDelete) throw Exception('delete error');
    deletedKeyPackageId = keyPackageId;
    return true;
  }

  @override
  Future<BigInt> crateApiAccountsDeleteAccountKeyPackages({
    required String accountPubkey,
  }) async {
    if (shouldThrowOnDeleteAll) throw Exception('delete all error');
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
      tags: [],
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
    mockApi.keyPackages = [];
    mockApi.deletedKeyPackageId = null;
    mockApi.shouldThrowOnFetch = false;
    mockApi.shouldThrowOnPublish = false;
    mockApi.shouldThrowOnDeleteAll = false;
    mockApi.shouldThrowOnDelete = false;
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );
    Routes.pushToDeveloperSettings(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('DeveloperSettingsScreen', () {
    testWidgets('displays Developer Settings title', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Developer Settings'), findsOneWidget);
    });

    testWidgets('displays action buttons', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Publish New Key Package'), findsOneWidget);
      expect(find.text('Refresh Key Packages'), findsOneWidget);
      expect(find.text('Delete All Key Packages'), findsOneWidget);
    });

    testWidgets('displays key packages count', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Key Packages (0)'), findsOneWidget);
    });

    testWidgets('displays empty state when no packages', (tester) async {
      await pumpScreen(tester);
      expect(find.text('No key packages found'), findsOneWidget);
    });

    testWidgets('displays key packages when available', (tester) async {
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

      await pumpScreen(tester);
      expect(find.text('Package 1'), findsOneWidget);
    });

    testWidgets('tapping back icon returns to previous screen', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(DeveloperSettingsScreen), findsNothing);
    });

    testWidgets('notice auto-dismisses after some seconds', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Publish New Key Package'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Key package published'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Key package published'), findsNothing);
    });

    group('publish key package', () {
      group('on success', () {
        testWidgets('shows success message', (tester) async {
          await pumpScreen(tester);

          await tester.tap(find.text('Publish New Key Package'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Key package published'), findsOneWidget);
        });
      });
      group('on error', () {
        testWidgets('shows error message', (tester) async {
          mockApi.shouldThrowOnPublish = true;
          await pumpScreen(tester);

          await tester.tap(find.text('Publish New Key Package'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Failed to publish key package'), findsOneWidget);
        });
      });
    });

    group('refresh key package', () {
      group('on success', () {
        testWidgets('shows success message', (tester) async {
          await pumpScreen(tester);

          await tester.tap(find.text('Refresh Key Packages'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Key packages refreshed'), findsOneWidget);
        });
      });
      group('on error', () {
        testWidgets('shows error message', (tester) async {
          await pumpScreen(tester);
          mockApi.shouldThrowOnFetch = true;

          await tester.tap(find.text('Refresh Key Packages'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Failed to fetch key packages'), findsOneWidget);
        });
      });
    });

    group('delete all key packages', () {
      setUp(() {
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
      });
      group('on success', () {
        testWidgets('shows success message', (tester) async {
          await pumpScreen(tester);
          await tester.tap(find.text('Delete All Key Packages'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('All key packages deleted'), findsOneWidget);
        });
      });
      group('on error', () {
        testWidgets('shows error message', (tester) async {
          mockApi.shouldThrowOnDeleteAll = true;
          await pumpScreen(tester);

          await tester.tap(find.text('Delete All Key Packages'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Failed to delete key packages'), findsOneWidget);
        });
      });
    });

    group('delete key package', () {
      setUp(() {
        mockApi.keyPackages = [
          FlutterEvent(
            id: 'pkg_to_delete',
            pubkey: testPubkeyA,
            createdAt: DateTime.now(),
            kind: NostrEventKinds.mlsKeyPackage,
            tags: [],
            content: '',
          ),
        ];
      });

      group('on success', () {
        testWidgets('calls delete with expected key package id', (tester) async {
          await pumpScreen(tester);
          await tester.tap(find.byKey(const Key('delete_key_package_pkg_to_delete')));
          await tester.pump();
          expect(mockApi.deletedKeyPackageId, 'pkg_to_delete');
        });
        testWidgets('shows success message', (tester) async {
          await pumpScreen(tester);
          await tester.tap(find.byKey(const Key('delete_key_package_pkg_to_delete')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Key package deleted'), findsOneWidget);
        });
      });
      group('on error', () {
        testWidgets('shows error message', (tester) async {
          mockApi.shouldThrowOnDelete = true;
          await pumpScreen(tester);

          await tester.tap(find.byKey(const Key('delete_key_package_pkg_to_delete')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Failed to delete key package'), findsOneWidget);
        });
      });
    });

    testWidgets('shows error message on fetch failure', (tester) async {
      mockApi.shouldThrowOnFetch = true;

      await pumpScreen(tester);

      expect(find.text('Failed to fetch key packages'), findsOneWidget);
    });

    group('with many key packages', () {
      setUp(() {
        mockApi.keyPackages = _manyKeyPackages(12);
      });

      testWidgets('displays multiple key packages', (tester) async {
        await pumpScreen(tester);
        expect(find.text('Package 1'), findsOneWidget);
        expect(find.text('Package 2'), findsOneWidget);
      });

      testWidgets('shows bottom scroll edge effect when list is scrollable', (tester) async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        final effect = tester.widget<WnScrollEdgeEffect>(
          find.byType(WnScrollEdgeEffect).first,
        );
        expect(effect.position, ScrollEdgePosition.bottom);
        expect(effect.type, ScrollEdgeEffectType.slate);
      });

      testWidgets('shows top scroll edge effect when scrolled up', (tester) async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();

        final effects = find.byType(WnScrollEdgeEffect);
        expect(effects, findsNWidgets(2));
        final topEffect = tester
            .widgetList<WnScrollEdgeEffect>(effects)
            .firstWhere(
              (effect) => effect.position == ScrollEdgePosition.top,
            );
        expect(topEffect.type, ScrollEdgeEffectType.slate);
      });
    });
  });
}
