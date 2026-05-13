import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rust_lib_whitenoise/src/rust/api/chat_summary.dart';
import 'package:rust_lib_whitenoise/src/rust/api/groups.dart' show GroupType;
import 'package:rust_lib_whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/hooks/use_chat_summary.dart';
import 'package:whitenoise/hooks/use_route_refresh.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _pubkey = testPubkeyA;
const _groupId = otherTestGroupId;

ChatSummary _summary({DateTime? removedAt}) => ChatSummary(
  mlsGroupId: _groupId,
  groupType: GroupType.directMessage,
  createdAt: DateTime(2024),
  pendingConfirmation: false,
  selfRemoved: false,
  unreadCount: BigInt.zero,
  removedAt: removedAt,
  dmPeerPubkey: testPubkeyB,
);

class _MockApi extends MockWnApi {
  bool shouldError = false;
  Completer<ChatSummary>? completer;
  DateTime? removedAt;
  int callCount = 0;

  @override
  Future<ChatSummary> crateApiChatSummaryGetChatSummary({
    required String accountPubkey,
    required String mlsGroupId,
  }) {
    callCount++;
    if (completer != null) return completer!.future;
    if (shouldError) return Future.error(Exception('fail'));
    return Future.value(_summary(removedAt: removedAt));
  }

  @override
  void reset() {
    super.reset();
    shouldError = false;
    completer = null;
    removedAt = null;
    callCount = 0;
  }
}

final _api = _MockApi();

late AsyncSnapshot<ChatSummary> Function() getResult;

Future<void> _mountHook(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      navigatorObservers: [routeObserver],
      home: HookBuilder(
        builder: (context) {
          final result = useChatSummary(context, _pubkey, _groupId);
          getResult = () => result;
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() => RustLib.initMock(api: _api));

  setUp(() {
    _api.reset();
  });

  group('useChatSummary', () {
    testWidgets('returns waiting snapshot initially', (tester) async {
      _api.completer = Completer<ChatSummary>();
      late AsyncSnapshot<ChatSummary> initialResult;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              final result = useChatSummary(context, _pubkey, _groupId);
              initialResult = result;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();

      expect(initialResult.connectionState, ConnectionState.waiting);
      expect(initialResult.data, isNull);
    });

    testWidgets('returns data with removedAt null on success', (tester) async {
      await _mountHook(tester);

      expect(getResult().hasData, isTrue);
      expect(getResult().data?.removedAt, isNull);
    });

    testWidgets('returns data with removedAt set on success', (tester) async {
      _api.removedAt = DateTime(2024, 6);
      await _mountHook(tester);

      expect(getResult().hasData, isTrue);
      expect(getResult().data?.removedAt, DateTime(2024, 6));
    });

    testWidgets('returns error snapshot on failure', (tester) async {
      _api.shouldError = true;
      await _mountHook(tester);

      expect(getResult().hasError, isTrue);
    });

    testWidgets('re-fetches when route returns', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [routeObserver],
          routes: {
            '/detail': (_) => const Scaffold(body: Text('Detail')),
          },
          home: HookBuilder(
            builder: (context) {
              final result = useChatSummary(context, _pubkey, _groupId);
              getResult = () => result;
              return Scaffold(
                body: Builder(
                  builder: (ctx) => TextButton(
                    onPressed: () => Navigator.of(ctx).pushNamed('/detail'),
                    child: const Text('Go'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final callsBefore = _api.callCount;

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_api.callCount, greaterThan(callsBefore));
    });
  });
}
