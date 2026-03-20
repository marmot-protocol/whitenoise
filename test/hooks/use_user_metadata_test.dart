import 'dart:async' show Completer;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_route_refresh.dart';
import 'package:whitenoise/hooks/use_user_metadata.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart' show testPubkeyA, testPubkeyB;

const _testMetadata = FlutterMetadata(
  name: 'Sloth',
  displayName: 'sloth',
  about: 'I live in costa rica',
  picture: 'https://example.com/sloth.jpg',
  banner: 'https://example.com/sloth-banner.jpg',
  website: 'https://sloth.com',
  nip05: 'sloth@example.com',
  custom: {},
);

const _updatedMetadata = FlutterMetadata(
  name: 'Updated Sloth',
  displayName: 'updated-sloth',
  picture: 'https://example.com/updated-sloth.jpg',
  custom: {},
);

late AsyncSnapshot<FlutterMetadata> Function() getResult;

Future<void> _mountHookWithNullablePubkey(WidgetTester tester, String? pubkey) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HookBuilder(
        builder: (context) {
          final result = useUserMetadata(context, pubkey);
          getResult = () => result;
          return const SizedBox();
        },
      ),
    ),
  );
}

Future<void> _mountHook(WidgetTester tester, String pubkey) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HookBuilder(
        builder: (context) {
          final result = useUserMetadata(context, pubkey);
          getResult = () => result;
          return const SizedBox();
        },
      ),
    ),
  );
}

Future<void> _mountHookWithNavigation(WidgetTester tester, String pubkey) async {
  await tester.pumpWidget(
    MaterialApp(
      navigatorObservers: [routeObserver],
      home: HookBuilder(
        builder: (context) {
          final result = useUserMetadata(context, pubkey);
          getResult = () => result;
          return ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const _SecondPage()),
            ),
            child: const Text('push'),
          );
        },
      ),
    ),
  );
}

class _SecondPage extends StatelessWidget {
  const _SecondPage();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('pop'),
    );
  }
}

enum _MockMode { loading, success, error }

class _MockApi extends MockWnApi {
  _MockMode mode = _MockMode.success;
  final calls = <String>[];

  void emitMetadataUpdate(String pubkey, FlutterMetadata metadata) {
    emitUserUpdate(
      pubkey,
      trigger: UserUpdateTrigger.metadataChanged,
      metadata: metadata,
    );
  }

  @override
  Stream<UserStreamItem> crateApiUsersSubscribeToUser({
    required String pubkey,
  }) {
    calls.add(pubkey);
    if (mode == _MockMode.loading) {
      return Completer<UserStreamItem>().future.asStream();
    }
    if (mode == _MockMode.error) {
      return Stream.error(Exception('fail'));
    }
    return super.crateApiUsersSubscribeToUser(pubkey: pubkey);
  }

  @override
  void reset() {
    super.reset();
    mode = _MockMode.success;
    calls.clear();
  }
}

final _api = _MockApi();

void main() {
  setUpAll(() => RustLib.initMock(api: _api));

  setUp(() {
    _api.reset();
    _api.seedUserInitialSnapshot(testPubkeyA, metadata: _testMetadata);
    _api.seedUserInitialSnapshot(testPubkeyB, metadata: _testMetadata);
  });

  group('useUserMetadata', () {
    group('loading', () {
      setUp(() => _api.mode = _MockMode.loading);

      testWidgets('is loading while waiting', (tester) async {
        await _mountHook(tester, testPubkeyA);

        expect(getResult().connectionState, equals(ConnectionState.waiting));
      });
    });

    group('success', () {
      testWidgets('returns expected metadata', (tester) async {
        await _mountHook(tester, testPubkeyA);
        await tester.pump();

        expect(getResult().data, equals(_testMetadata));
      });

      testWidgets('does not resubscribe when rebuilt with same pubkey', (tester) async {
        await _mountHook(tester, testPubkeyA);
        await _mountHook(tester, testPubkeyA);

        expect(_api.calls.length, 1);
      });

      testWidgets('resubscribes when pubkey changes', (tester) async {
        await _mountHook(tester, testPubkeyA);
        await _mountHook(tester, testPubkeyB);

        expect(_api.calls.length, 2);
      });

      testWidgets('updates when stream publishes new metadata without remounting', (tester) async {
        await _mountHook(tester, testPubkeyA);
        await tester.pump();

        expect(getResult().data, equals(_testMetadata));

        _api.emitMetadataUpdate(testPubkeyA, _updatedMetadata);
        await tester.pump();

        expect(getResult().data, equals(_updatedMetadata));
      });
    });

    group('error', () {
      setUp(() => _api.mode = _MockMode.error);

      testWidgets('returns error on failure', (tester) async {
        await _mountHook(tester, testPubkeyA);
        await tester.pump();

        expect(getResult().hasError, isTrue);
      });
    });

    group('refresh on route change', () {
      setUp(() => _api.mode = _MockMode.success);

      testWidgets('resubscribes when route changes', (tester) async {
        await _mountHookWithNavigation(tester, testPubkeyA);
        await tester.pumpAndSettle();
        await tester.tap(find.text('push'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('pop'));
        await tester.pumpAndSettle();

        expect(_api.calls.length, 2);
      });
    });

    group('nullable pubkey', () {
      testWidgets('returns none connection state when pubkey is null', (tester) async {
        await _mountHookWithNullablePubkey(tester, null);
        await tester.pump();

        expect(getResult().connectionState, equals(ConnectionState.none));
        expect(getResult().data, isNull);
      });

      testWidgets('does not make API call when pubkey is null', (tester) async {
        _api.calls.clear();
        await _mountHookWithNullablePubkey(tester, null);
        await tester.pump();

        expect(_api.calls, isEmpty);
      });
    });
  });
}
