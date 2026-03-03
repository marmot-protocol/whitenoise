import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_relay_resolution.dart';
import 'package:whitenoise/src/rust/api/accounts.dart'
    show LoginResult, LoginStatus, Account, AccountType;
import 'package:whitenoise/src/rust/api/error.dart';
import 'package:whitenoise/widgets/wn_icon.dart' show WnIcons;
import '../mocks/mock_clipboard_paste.dart';
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
    bool isRelayUrlValid,
    String? validationError,
    WnIcons trailingIcon,
    String trailingKey,
    void Function() handleTrailingAction,
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
      isRelayUrlValid: isRelayUrlValid,
      validationError: validationError,
      trailingIcon: trailingIcon,
      trailingKey: trailingKey,
      handleTrailingAction: handleTrailingAction,
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
    onBuild(
      controller,
      state,
      isRelayUrlValid,
      validationError,
      trailingIcon,
      trailingKey,
      handleTrailingAction,
      publishDefaults,
      tryCustomRelay,
      cancel,
      clearError,
    );
    return Column(
      children: [
        TextField(controller: controller),
        ElevatedButton(onPressed: handleTrailingAction, child: const Text('Trailing Action')),
        Text('isPublishingDefaults: ${state.isPublishingDefaults}'),
        Text('isSearchingRelay: ${state.isSearchingRelay}'),
        Text('isLoading: ${state.isLoading}'),
        Text('error: ${state.error ?? 'none'}'),
        Text('validationError: ${validationError ?? 'none'}'),
        Text('isRelayUrlValid: $isRelayUrlValid'),
        Text('trailingIcon: ${trailingIcon.name}'),
        Text('trailingKey: $trailingKey'),
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
    bool isRelayUrlValid,
    String? validationError,
    WnIcons trailingIcon,
    String trailingKey,
    void Function() handleTrailingAction,
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
        onBuild:
            (
              controller,
              state,
              isRelayUrlValid,
              validationError,
              trailingIcon,
              trailingKey,
              handleTrailingAction,
              publishDefaults,
              tryCustomRelay,
              cancel,
              clearError,
            ) {
              capturedState = state;
            },
      );
      await mountWidget(widget, tester);

      expect(capturedState.isLoading, false);
    });

    testWidgets('initializes with isPublishingDefaults false', (tester) async {
      late RelayResolutionState capturedState;

      final widget = _buildTestWidget(
        onBuild:
            (
              controller,
              state,
              isRelayUrlValid,
              validationError,
              trailingIcon,
              trailingKey,
              handleTrailingAction,
              publishDefaults,
              tryCustomRelay,
              cancel,
              clearError,
            ) {
              capturedState = state;
            },
      );
      await mountWidget(widget, tester);

      expect(capturedState.isPublishingDefaults, false);
    });

    testWidgets('initializes with isSearchingRelay false', (tester) async {
      late RelayResolutionState capturedState;

      final widget = _buildTestWidget(
        onBuild:
            (
              controller,
              state,
              isRelayUrlValid,
              validationError,
              trailingIcon,
              trailingKey,
              handleTrailingAction,
              publishDefaults,
              tryCustomRelay,
              cancel,
              clearError,
            ) {
              capturedState = state;
            },
      );
      await mountWidget(widget, tester);

      expect(capturedState.isSearchingRelay, false);
    });

    testWidgets('initializes with null error', (tester) async {
      late RelayResolutionState capturedState;

      final widget = _buildTestWidget(
        onBuild:
            (
              controller,
              state,
              isRelayUrlValid,
              validationError,
              trailingIcon,
              trailingKey,
              handleTrailingAction,
              publishDefaults,
              tryCustomRelay,
              cancel,
              clearError,
            ) {
              capturedState = state;
            },
      );
      await mountWidget(widget, tester);

      expect(capturedState.error, isNull);
    });

    testWidgets('initializes with null validationError', (tester) async {
      late String? capturedValidationError;

      final widget = _buildTestWidget(
        onBuild:
            (
              controller,
              state,
              isRelayUrlValid,
              validationError,
              trailingIcon,
              trailingKey,
              handleTrailingAction,
              publishDefaults,
              tryCustomRelay,
              cancel,
              clearError,
            ) {
              capturedValidationError = validationError;
            },
      );
      await mountWidget(widget, tester);

      expect(capturedValidationError, isNull);
    });

    testWidgets('initializes with wss:// prefilled controller', (tester) async {
      late TextEditingController capturedController;

      final widget = _buildTestWidget(
        onBuild:
            (
              controller,
              state,
              isRelayUrlValid,
              validationError,
              trailingIcon,
              trailingKey,
              handleTrailingAction,
              publishDefaults,
              tryCustomRelay,
              cancel,
              clearError,
            ) {
              capturedController = controller;
            },
      );
      await mountWidget(widget, tester);

      expect(capturedController.text, 'wss://');
    });

    testWidgets('initializes with isRelayUrlValid false', (tester) async {
      late bool capturedIsRelayUrlValid;

      final widget = _buildTestWidget(
        onBuild:
            (
              controller,
              state,
              isRelayUrlValid,
              validationError,
              trailingIcon,
              trailingKey,
              handleTrailingAction,
              publishDefaults,
              tryCustomRelay,
              cancel,
              clearError,
            ) {
              capturedIsRelayUrlValid = isRelayUrlValid;
            },
      );
      await mountWidget(widget, tester);

      expect(capturedIsRelayUrlValid, false);
    });

    testWidgets('initializes with paste trailing icon', (tester) async {
      late WnIcons capturedIcon;
      late String capturedKey;

      final widget = _buildTestWidget(
        onBuild:
            (
              controller,
              state,
              isRelayUrlValid,
              validationError,
              trailingIcon,
              trailingKey,
              handleTrailingAction,
              publishDefaults,
              tryCustomRelay,
              cancel,
              clearError,
            ) {
              capturedIcon = trailingIcon;
              capturedKey = trailingKey;
            },
      );
      await mountWidget(widget, tester);

      expect(capturedIcon, WnIcons.paste);
      expect(capturedKey, 'paste_button');
    });

    group('URL validation', () {
      testWidgets('validates URL after debounce and sets isRelayUrlValid true for valid URL', (
        tester,
      ) async {
        late bool capturedIsRelayUrlValid;
        late String? capturedValidationError;

        final widget = _buildTestWidget(
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedIsRelayUrlValid = isRelayUrlValid;
                capturedValidationError = validationError;
              },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));

        expect(capturedIsRelayUrlValid, true);
        expect(capturedValidationError, isNull);
      });

      testWidgets('sets validationError for invalid URL after debounce', (tester) async {
        late bool capturedIsRelayUrlValid;
        late String? capturedValidationError;

        final widget = _buildTestWidget(
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedIsRelayUrlValid = isRelayUrlValid;
                capturedValidationError = validationError;
              },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://invalid');
        await tester.pump(const Duration(milliseconds: 600));

        expect(capturedIsRelayUrlValid, false);
        expect(capturedValidationError, isNotNull);
      });

      testWidgets('clears validationError for valid URL', (tester) async {
        late String? capturedValidationError;

        final widget = _buildTestWidget(
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedValidationError = validationError;
              },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://invalid');
        await tester.pump(const Duration(milliseconds: 600));

        expect(capturedValidationError, isNotNull);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));

        expect(capturedValidationError, isNull);
      });

      testWidgets('isRelayUrlValid false immediately on text change before debounce completes', (
        tester,
      ) async {
        late bool capturedIsRelayUrlValid;

        final widget = _buildTestWidget(
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedIsRelayUrlValid = isRelayUrlValid;
              },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));

        expect(capturedIsRelayUrlValid, true);

        await tester.enterText(find.byType(TextField), 'wss://other.relay.com');
        await tester.pump();

        expect(capturedIsRelayUrlValid, false);
      });

      testWidgets(
        'clears validationError and sets isRelayUrlValid false when text cleared to prefix',
        (tester) async {
          late bool capturedIsRelayUrlValid;
          late String? capturedValidationError;

          final widget = _buildTestWidget(
            onBuild:
                (
                  controller,
                  state,
                  isRelayUrlValid,
                  validationError,
                  trailingIcon,
                  trailingKey,
                  handleTrailingAction,
                  publishDefaults,
                  tryCustomRelay,
                  cancel,
                  clearError,
                ) {
                  capturedIsRelayUrlValid = isRelayUrlValid;
                  capturedValidationError = validationError;
                },
          );
          await mountWidget(widget, tester);

          await tester.enterText(find.byType(TextField), 'wss://bad');
          await tester.pump(const Duration(milliseconds: 600));

          expect(capturedIsRelayUrlValid, false);
          expect(capturedValidationError, isNotNull);

          await tester.enterText(find.byType(TextField), 'wss://');
          await tester.pump(const Duration(milliseconds: 600));

          expect(capturedIsRelayUrlValid, false);
          expect(capturedValidationError, isNull);
        },
      );
    });

    group('trailing icon', () {
      testWidgets('shows clear icon when text entered', (tester) async {
        late WnIcons capturedIcon;
        late String capturedKey;

        final widget = _buildTestWidget(
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedIcon = trailingIcon;
                capturedKey = trailingKey;
              },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();

        expect(capturedIcon, WnIcons.closeSmall);
        expect(capturedKey, 'clear_button');
      });

      testWidgets('handleTrailingAction clears when hasText is true', (tester) async {
        late TextEditingController capturedController;

        final widget = _buildTestWidget(
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedController = controller;
              },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();

        await tester.tap(find.text('Trailing Action'));
        await tester.pump();

        expect(capturedController.text, 'wss://');
      });
    });

    group('publishDefaults', () {
      testWidgets('sets isPublishingDefaults true during call', (tester) async {
        late Completer<LoginResult> completer;
        late Future<bool> Function() capturedPublishDefaults;
        late RelayResolutionState capturedState;

        final widget = _buildTestWidget(
          publishDefaultRelays: (_) async {
            return completer.future;
          },
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedPublishDefaults = publishDefaults;
                capturedState = state;
              },
        );
        await mountWidget(widget, tester);

        completer = Completer<LoginResult>();
        final future = capturedPublishDefaults();
        await tester.pump();

        expect(capturedState.isPublishingDefaults, true);
        expect(capturedState.isSearchingRelay, false);
        expect(capturedState.isLoading, true);

        completer.complete(_completeLoginResult());
        await future;
        await tester.pump();

        expect(capturedState.isPublishingDefaults, false);
        expect(capturedState.isLoading, false);
      });

      testWidgets('returns true on success', (tester) async {
        late Future<bool> Function() capturedPublishDefaults;

        final widget = _buildTestWidget(
          publishDefaultRelays: (_) async => _completeLoginResult(),
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
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
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
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
      testWidgets('returns false when relay URL is bare wss:// prefix', (tester) async {
        late Future<bool> Function() capturedTryCustomRelay;

        final widget = _buildTestWidget(
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedTryCustomRelay = tryCustomRelay;
              },
        );
        await mountWidget(widget, tester);

        final result = await capturedTryCustomRelay();
        expect(result, false);
      });

      testWidgets('sets isSearchingRelay true during call', (tester) async {
        late Completer<LoginResult> completer;
        late Future<bool> Function() capturedTryCustomRelay;
        late RelayResolutionState capturedState;

        final widget = _buildTestWidget(
          customRelay: (_, _) async {
            return completer.future;
          },
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedTryCustomRelay = tryCustomRelay;
                capturedState = state;
              },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');

        completer = Completer<LoginResult>();
        final future = capturedTryCustomRelay();
        await tester.pump();

        expect(capturedState.isSearchingRelay, true);
        expect(capturedState.isPublishingDefaults, false);
        expect(capturedState.isLoading, true);

        completer.complete(_completeLoginResult());
        await future;
        await tester.pump();

        expect(capturedState.isSearchingRelay, false);
        expect(capturedState.isLoading, false);
      });

      testWidgets('returns true on LoginStatus.complete', (tester) async {
        late Future<bool> Function() capturedTryCustomRelay;

        final widget = _buildTestWidget(
          customRelay: (_, _) async => _completeLoginResult(),
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
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
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
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
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
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
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
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
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
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
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
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

    group('structured error mapping', () {
      testWidgets('publishDefaults maps LoginNoRelayConnections to specific key', (
        tester,
      ) async {
        late Future<bool> Function() capturedPublishDefaults;
        late RelayResolutionState capturedState;

        final widget = _buildTestWidget(
          publishDefaultRelays: (_) async {
            throw const ApiError.loginNoRelayConnections();
          },
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedPublishDefaults = publishDefaults;
                capturedState = state;
              },
        );
        await mountWidget(widget, tester);

        await capturedPublishDefaults();
        await tester.pump();

        expect(capturedState.error, 'loginErrorNoRelayConnections');
      });

      testWidgets('publishDefaults maps LoginTimeout to specific key', (tester) async {
        late Future<bool> Function() capturedPublishDefaults;
        late RelayResolutionState capturedState;

        final widget = _buildTestWidget(
          publishDefaultRelays: (_) async {
            throw const ApiError.loginTimeout(message: 'timed out');
          },
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedPublishDefaults = publishDefaults;
                capturedState = state;
              },
        );
        await mountWidget(widget, tester);

        await capturedPublishDefaults();
        await tester.pump();

        expect(capturedState.error, 'loginErrorTimeout');
      });

      testWidgets('publishDefaults maps LoginInternal to specific key', (tester) async {
        late Future<bool> Function() capturedPublishDefaults;
        late RelayResolutionState capturedState;

        final widget = _buildTestWidget(
          publishDefaultRelays: (_) async {
            throw const ApiError.loginInternal(message: 'internal error');
          },
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedPublishDefaults = publishDefaults;
                capturedState = state;
              },
        );
        await mountWidget(widget, tester);

        await capturedPublishDefaults();
        await tester.pump();

        expect(capturedState.error, 'loginErrorInternal');
      });

      testWidgets('tryCustomRelay maps LoginTimeout to specific key', (tester) async {
        late Future<bool> Function() capturedTryCustomRelay;
        late RelayResolutionState capturedState;

        final widget = _buildTestWidget(
          customRelay: (_, _) async {
            throw const ApiError.loginTimeout(message: 'timed out');
          },
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedTryCustomRelay = tryCustomRelay;
                capturedState = state;
              },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await capturedTryCustomRelay();
        await tester.pump();

        expect(capturedState.error, 'loginErrorTimeout');
      });

      testWidgets('tryCustomRelay maps LoginNoRelayConnections to specific key', (
        tester,
      ) async {
        late Future<bool> Function() capturedTryCustomRelay;
        late RelayResolutionState capturedState;

        final widget = _buildTestWidget(
          customRelay: (_, _) async {
            throw const ApiError.loginNoRelayConnections();
          },
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedTryCustomRelay = tryCustomRelay;
                capturedState = state;
              },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await capturedTryCustomRelay();
        await tester.pump();

        expect(capturedState.error, 'loginErrorNoRelayConnections');
      });
    });

    group('mounted guard', () {
      testWidgets('publishDefaults skips state update when unmounted', (tester) async {
        final completer = Completer<LoginResult>();
        late Future<bool> Function() capturedPublishDefaults;

        final widget = _buildTestWidget(
          publishDefaultRelays: (_) => completer.future,
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedPublishDefaults = publishDefaults;
              },
        );
        await mountWidget(widget, tester);

        final future = capturedPublishDefaults();

        await tester.pumpWidget(const SizedBox.shrink());

        completer.complete(_completeLoginResult());
        final result = await future;

        expect(result, false);
      });

      testWidgets('tryCustomRelay skips state update when unmounted', (tester) async {
        final completer = Completer<LoginResult>();
        late Future<bool> Function() capturedTryCustomRelay;

        final widget = _buildTestWidget(
          customRelay: (_, _) => completer.future,
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedTryCustomRelay = tryCustomRelay;
              },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        final future = capturedTryCustomRelay();

        await tester.pumpWidget(const SizedBox.shrink());

        completer.complete(_completeLoginResult());
        final result = await future;

        expect(result, false);
      });

      testWidgets('publishDefaults skips state update on error when unmounted', (tester) async {
        final completer = Completer<LoginResult>();
        late Future<bool> Function() capturedPublishDefaults;

        final widget = _buildTestWidget(
          publishDefaultRelays: (_) => completer.future,
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedPublishDefaults = publishDefaults;
              },
        );
        await mountWidget(widget, tester);

        final future = capturedPublishDefaults();

        await tester.pumpWidget(const SizedBox.shrink());

        completer.completeError(Exception('Network error'));
        final result = await future;

        expect(result, false);
      });

      testWidgets('tryCustomRelay skips state update on error when unmounted', (tester) async {
        final completer = Completer<LoginResult>();
        late Future<bool> Function() capturedTryCustomRelay;

        final widget = _buildTestWidget(
          customRelay: (_, _) => completer.future,
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedTryCustomRelay = tryCustomRelay;
              },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        final future = capturedTryCustomRelay();

        await tester.pumpWidget(const SizedBox.shrink());

        completer.completeError(Exception('Connection failed'));
        final result = await future;

        expect(result, false);
      });
    });

    group('paste via handleTrailingAction', () {
      late void Function(Map<String, dynamic>?) setClipboardData;
      late void Function() resetClipboard;

      setUp(() {
        final mock = mockClipboardPaste();
        setClipboardData = mock.setData;
        resetClipboard = mock.reset;
      });

      tearDown(() {
        resetClipboard();
      });

      testWidgets('handleTrailingAction pastes when hasText is false', (tester) async {
        late TextEditingController capturedController;

        final widget = _buildTestWidget(
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedController = controller;
              },
        );
        await mountWidget(widget, tester);

        setClipboardData({'text': 'wss://pasted.relay.com'});

        await tester.tap(find.text('Trailing Action'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(capturedController.text, 'wss://pasted.relay.com');
      });

      testWidgets('adds wss:// prefix when pasting non-websocket URL', (tester) async {
        late TextEditingController capturedController;

        final widget = _buildTestWidget(
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedController = controller;
              },
        );
        await mountWidget(widget, tester);

        setClipboardData({'text': 'relay.example.com'});

        await tester.tap(find.text('Trailing Action'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(capturedController.text, 'wss://relay.example.com');
      });

      testWidgets('handles empty clipboard gracefully', (tester) async {
        late TextEditingController capturedController;

        final widget = _buildTestWidget(
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedController = controller;
              },
        );
        await mountWidget(widget, tester);

        setClipboardData(null);

        await tester.tap(find.text('Trailing Action'));
        await tester.pumpAndSettle();

        expect(capturedController.text, 'wss://');
      });
    });

    group('clear via handleTrailingAction', () {
      testWidgets('resets controller to wss:// prefix', (tester) async {
        late TextEditingController capturedController;

        final widget = _buildTestWidget(
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedController = controller;
              },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));
        expect(capturedController.text, 'wss://relay.example.com');

        await tester.tap(find.text('Trailing Action'));
        await tester.pumpAndSettle();

        expect(capturedController.text, 'wss://');
      });

      testWidgets('resets isRelayUrlValid to false', (tester) async {
        late bool capturedIsValid;

        final widget = _buildTestWidget(
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedIsValid = isRelayUrlValid;
              },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));
        expect(capturedIsValid, true);

        await tester.tap(find.text('Trailing Action'));
        await tester.pumpAndSettle();

        expect(capturedIsValid, false);
      });

      testWidgets('clears validation error', (tester) async {
        late String? capturedValidationError;

        final widget = _buildTestWidget(
          onBuild:
              (
                controller,
                state,
                isRelayUrlValid,
                validationError,
                trailingIcon,
                trailingKey,
                handleTrailingAction,
                publishDefaults,
                tryCustomRelay,
                cancel,
                clearError,
              ) {
                capturedValidationError = validationError;
              },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'https://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));
        expect(capturedValidationError, 'invalidRelayUrlScheme');

        await tester.tap(find.text('Trailing Action'));
        await tester.pumpAndSettle();

        expect(capturedValidationError, isNull);
      });
    });
  });
}
