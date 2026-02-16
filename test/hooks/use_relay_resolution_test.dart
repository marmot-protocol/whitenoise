import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_relay_resolution.dart';
import 'package:whitenoise/src/rust/api/accounts.dart'
    show LoginResult, LoginStatus, Account, AccountType;
import '../test_helpers.dart';

LoginResult _completeLoginResult() => LoginResult(
  account: Account(
    pubkey: testPubkeyA,
    accountType: AccountType.local,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  status: LoginStatus.complete,
);

LoginResult _needsRelayListsResult() => LoginResult(
  account: Account(
    pubkey: testPubkeyA,
    accountType: AccountType.local,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  status: LoginStatus.needsRelayLists,
);

class _TestWidget extends HookWidget {
  final PublishDefaultRelaysCallback publishDefaultRelays;
  final CustomRelayCallback customRelay;
  final CancelLoginCallback cancelLogin;
  final void Function(
    TextEditingController controller,
    RelayResolutionState state,
    Future<bool> Function() publishDefaults,
    Future<bool> Function() tryCustomRelay,
    Future<void> Function() cancel,
    void Function() clearError,
  )
  onBuild;

  const _TestWidget({
    required this.publishDefaultRelays,
    required this.customRelay,
    required this.cancelLogin,
    required this.onBuild,
  });

  @override
  Widget build(BuildContext context) {
    final (
      relayUrlController: controller,
      relayResolutionState: state,
      publishDefaults: publishDefaults,
      tryCustomRelay: tryCustomRelay,
      cancel: cancel,
      clearError: clearError,
    ) = useRelayResolution(
      pubkey: testPubkeyA,
      publishDefaultRelays: publishDefaultRelays,
      customRelay: customRelay,
      cancelLogin: cancelLogin,
    );
    onBuild(controller, state, publishDefaults, tryCustomRelay, cancel, clearError);
    return Column(
      children: [
        TextField(controller: controller),
        Text('loading: ${state.isLoading}'),
        Text('error: ${state.error ?? 'none'}'),
      ],
    );
  }
}

_TestWidget _buildTestWidget({
  PublishDefaultRelaysCallback? publishDefaultRelays,
  CustomRelayCallback? customRelay,
  CancelLoginCallback? cancelLogin,
  required void Function(
    TextEditingController controller,
    RelayResolutionState state,
    Future<bool> Function() publishDefaults,
    Future<bool> Function() tryCustomRelay,
    Future<void> Function() cancel,
    void Function() clearError,
  )
  onBuild,
}) {
  return _TestWidget(
    publishDefaultRelays: publishDefaultRelays ?? (_) async => _completeLoginResult(),
    customRelay: customRelay ?? (_, _) async => _completeLoginResult(),
    cancelLogin: cancelLogin ?? (_) async {},
    onBuild: onBuild,
  );
}

void main() {
  group('useRelayResolution', () {
    testWidgets('initializes with isLoading false', (tester) async {
      late RelayResolutionState capturedState;

      final widget = _buildTestWidget(
        onBuild: (controller, state, publishDefaults, tryCustomRelay, cancel, clearError) {
          capturedState = state;
        },
      );
      await mountWidget(widget, tester);

      expect(capturedState.isLoading, false);
    });

    testWidgets('initializes with null error', (tester) async {
      late RelayResolutionState capturedState;

      final widget = _buildTestWidget(
        onBuild: (controller, state, publishDefaults, tryCustomRelay, cancel, clearError) {
          capturedState = state;
        },
      );
      await mountWidget(widget, tester);

      expect(capturedState.error, isNull);
    });

    testWidgets('initializes with empty controller', (tester) async {
      late TextEditingController capturedController;

      final widget = _buildTestWidget(
        onBuild: (controller, state, publishDefaults, tryCustomRelay, cancel, clearError) {
          capturedController = controller;
        },
      );
      await mountWidget(widget, tester);

      expect(capturedController.text, isEmpty);
    });

    group('publishDefaults', () {
      testWidgets('sets isLoading true during call', (tester) async {
        late Completer<LoginResult> completer;
        late Future<bool> Function() capturedPublishDefaults;
        late RelayResolutionState capturedState;

        final widget = _buildTestWidget(
          publishDefaultRelays: (_) async {
            return completer.future;
          },
          onBuild: (controller, state, publishDefaults, tryCustomRelay, cancel, clearError) {
            capturedPublishDefaults = publishDefaults;
            capturedState = state;
          },
        );
        await mountWidget(widget, tester);

        completer = Completer<LoginResult>();
        final future = capturedPublishDefaults();
        await tester.pump();

        expect(capturedState.isLoading, true);

        completer.complete(_completeLoginResult());
        await future;
        await tester.pump();

        expect(capturedState.isLoading, false);
      });

      testWidgets('returns true on success', (tester) async {
        late Future<bool> Function() capturedPublishDefaults;

        final widget = _buildTestWidget(
          publishDefaultRelays: (_) async => _completeLoginResult(),
          onBuild: (controller, state, publishDefaults, tryCustomRelay, cancel, clearError) {
            capturedPublishDefaults = publishDefaults;
          },
        );
        await mountWidget(widget, tester);

        final result = await capturedPublishDefaults();
        expect(result, true);
      });

      testWidgets('returns false and sets error on failure', (tester) async {
        late Future<bool> Function() capturedPublishDefaults;
        late RelayResolutionState capturedState;

        final widget = _buildTestWidget(
          publishDefaultRelays: (_) async {
            throw Exception('Network error');
          },
          onBuild: (controller, state, publishDefaults, tryCustomRelay, cancel, clearError) {
            capturedPublishDefaults = publishDefaults;
            capturedState = state;
          },
        );
        await mountWidget(widget, tester);

        final result = await capturedPublishDefaults();
        await tester.pump();

        expect(result, false);
        expect(capturedState.error, 'loginErrorGeneric');
      });
    });

    group('tryCustomRelay', () {
      testWidgets('returns false when relay URL is empty', (tester) async {
        late Future<bool> Function() capturedTryCustomRelay;

        final widget = _buildTestWidget(
          onBuild: (controller, state, publishDefaults, tryCustomRelay, cancel, clearError) {
            capturedTryCustomRelay = tryCustomRelay;
          },
        );
        await mountWidget(widget, tester);

        final result = await capturedTryCustomRelay();
        expect(result, false);
      });

      testWidgets('returns true on LoginStatus.complete', (tester) async {
        late Future<bool> Function() capturedTryCustomRelay;

        final widget = _buildTestWidget(
          customRelay: (_, _) async => _completeLoginResult(),
          onBuild: (controller, state, publishDefaults, tryCustomRelay, cancel, clearError) {
            capturedTryCustomRelay = tryCustomRelay;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        final result = await capturedTryCustomRelay();

        expect(result, true);
      });

      testWidgets('returns false and sets relayResolutionNotFound on needsRelayLists', (
        tester,
      ) async {
        late Future<bool> Function() capturedTryCustomRelay;
        late RelayResolutionState capturedState;

        final widget = _buildTestWidget(
          customRelay: (_, _) async => _needsRelayListsResult(),
          onBuild: (controller, state, publishDefaults, tryCustomRelay, cancel, clearError) {
            capturedTryCustomRelay = tryCustomRelay;
            capturedState = state;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        final result = await capturedTryCustomRelay();
        await tester.pump();

        expect(result, false);
        expect(capturedState.error, 'relayResolutionNotFound');
      });

      testWidgets('returns false and sets error on exception', (tester) async {
        late Future<bool> Function() capturedTryCustomRelay;
        late RelayResolutionState capturedState;

        final widget = _buildTestWidget(
          customRelay: (_, _) async {
            throw Exception('Connection failed');
          },
          onBuild: (controller, state, publishDefaults, tryCustomRelay, cancel, clearError) {
            capturedTryCustomRelay = tryCustomRelay;
            capturedState = state;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        final result = await capturedTryCustomRelay();
        await tester.pump();

        expect(result, false);
        expect(capturedState.error, 'loginErrorGeneric');
      });
    });

    group('cancel', () {
      testWidgets('calls cancelLogin callback', (tester) async {
        bool cancelCalled = false;
        late Future<void> Function() capturedCancel;

        final widget = _buildTestWidget(
          cancelLogin: (_) async {
            cancelCalled = true;
          },
          onBuild: (controller, state, publishDefaults, tryCustomRelay, cancel, clearError) {
            capturedCancel = cancel;
          },
        );
        await mountWidget(widget, tester);

        await capturedCancel();
        expect(cancelCalled, true);
      });

      testWidgets('does not throw on callback failure', (tester) async {
        late Future<void> Function() capturedCancel;

        final widget = _buildTestWidget(
          cancelLogin: (_) async {
            throw Exception('Cancel failed');
          },
          onBuild: (controller, state, publishDefaults, tryCustomRelay, cancel, clearError) {
            capturedCancel = cancel;
          },
        );
        await mountWidget(widget, tester);

        await capturedCancel();
      });
    });

    group('clearError', () {
      testWidgets('clears the error state', (tester) async {
        late Future<bool> Function() capturedPublishDefaults;
        late void Function() capturedClearError;
        late RelayResolutionState capturedState;

        final widget = _buildTestWidget(
          publishDefaultRelays: (_) async {
            throw Exception('Failed');
          },
          onBuild: (controller, state, publishDefaults, tryCustomRelay, cancel, clearError) {
            capturedPublishDefaults = publishDefaults;
            capturedClearError = clearError;
            capturedState = state;
          },
        );
        await mountWidget(widget, tester);

        await capturedPublishDefaults();
        await tester.pump();

        expect(capturedState.error, isNotNull);

        capturedClearError();
        await tester.pump();

        expect(capturedState.error, isNull);
      });
    });
  });
}
