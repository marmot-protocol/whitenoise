import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_login_with_nsec.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
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

class _TestWidget extends HookWidget {
  final Future<LoginResult> Function(String) loginCallback;
  final void Function(
    TextEditingController controller,
    LoginWithNsecState state,
    Future<void> Function() paste,
    Future<LoginResult?> Function() submit,
    void Function() clearError,
  )
  onBuild;

  const _TestWidget({
    required this.loginCallback,
    required this.onBuild,
  });

  @override
  Widget build(BuildContext context) {
    final (
      nsecInputController: controller,
      loginWithNsecState: state,
      pasteNsec: paste,
      submitLoginWithNsec: submit,
      clearLoginWithNsecError: clearError,
    ) = useLoginWithNsec(
      loginCallback,
    );
    onBuild(controller, state, paste, submit, clearError);
    return Column(
      children: [
        TextField(controller: controller),
        Text('loading: ${state.isLoading}'),
        Text('error: ${state.error ?? 'none'}'),
        ElevatedButton(onPressed: paste, child: const Text('Paste')),
        ElevatedButton(onPressed: submit, child: const Text('Submit')),
        ElevatedButton(onPressed: clearError, child: const Text('Clear')),
      ],
    );
  }
}

void main() {
  group('useLoginWithNsec', () {
    testWidgets('initializes with empty controller', (tester) async {
      late TextEditingController capturedController;

      final widget = _TestWidget(
        loginCallback: (_) async => _completeLoginResult(),
        onBuild: (controller, state, paste, submit, clearError) {
          capturedController = controller;
        },
      );
      await mountWidget(widget, tester);

      expect(capturedController.text, isEmpty);
    });

    testWidgets('starts with not loading', (tester) async {
      late bool capturedIsLoading;

      final widget = _TestWidget(
        loginCallback: (_) async => _completeLoginResult(),
        onBuild: (controller, state, paste, submit, clearError) {
          capturedIsLoading = state.isLoading;
        },
      );
      await mountWidget(widget, tester);

      expect(capturedIsLoading, false);
    });

    testWidgets('starts with no error', (tester) async {
      late String? capturedError;

      final widget = _TestWidget(
        loginCallback: (_) async => _completeLoginResult(),
        onBuild: (controller, state, paste, submit, clearError) {
          capturedError = state.error;
        },
      );
      await mountWidget(widget, tester);

      expect(capturedError, isNull);
    });

    group('submit', () {
      testWidgets('returns null when nsec is empty', (tester) async {
        late Future<LoginResult?> Function() capturedSubmit;

        final widget = _TestWidget(
          loginCallback: (_) async => _completeLoginResult(),
          onBuild: (controller, state, paste, submit, clearError) {
            capturedSubmit = submit;
          },
        );
        await mountWidget(widget, tester);

        final result = await capturedSubmit();
        expect(result, isNull);
      });

      testWidgets('calls login callback with nsec', (tester) async {
        String? capturedNsec;
        late Future<LoginResult?> Function() capturedSubmit;

        final widget = _TestWidget(
          loginCallback: (nsec) async {
            capturedNsec = nsec;
            return _completeLoginResult();
          },
          onBuild: (controller, state, paste, submit, clearError) {
            capturedSubmit = submit;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'nsec1test');
        final result = await capturedSubmit();

        expect(capturedNsec, 'nsec1test');
        expect(result, isNotNull);
        expect(result!.status, LoginStatus.complete);
      });

      testWidgets('sets loading state during submit', (tester) async {
        bool loginCalled = false;
        late Completer<LoginResult> loginCompleter;
        late Future<LoginResult?> Function() capturedSubmit;
        late LoginWithNsecState capturedState;

        final widget = _TestWidget(
          loginCallback: (_) async {
            loginCalled = true;
            return loginCompleter.future;
          },
          onBuild: (controller, state, paste, submit, clearError) {
            capturedSubmit = submit;
            capturedState = state;
          },
        );
        await mountWidget(widget, tester);

        loginCompleter = Completer<LoginResult>();
        await tester.enterText(find.byType(TextField), 'nsec1test');

        final submitFuture = capturedSubmit();
        await tester.pump();

        expect(capturedState.isLoading, true);
        expect(loginCalled, true);

        loginCompleter.complete(_completeLoginResult());
        await submitFuture;
        await tester.pump();

        expect(capturedState.isLoading, false);
      });

      testWidgets('sets error message on failure', (tester) async {
        late Future<LoginResult?> Function() capturedSubmit;
        late LoginWithNsecState capturedState;

        final widget = _TestWidget(
          loginCallback: (_) async {
            throw Exception('Invalid key');
          },
          onBuild: (controller, state, paste, submit, clearError) {
            capturedSubmit = submit;
            capturedState = state;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'nsec1test');

        final result = await capturedSubmit();
        await tester.pump();

        expect(result, isNull);
        expect(capturedState.error, 'loginErrorGeneric');
      });

      testWidgets('returns LoginResult on success', (tester) async {
        late Future<LoginResult?> Function() capturedSubmit;

        final widget = _TestWidget(
          loginCallback: (_) async => _completeLoginResult(),
          onBuild: (controller, state, paste, submit, clearError) {
            capturedSubmit = submit;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'nsec1test');

        final result = await capturedSubmit();
        expect(result, isNotNull);
        expect(result!.status, LoginStatus.complete);
      });
    });

    group('paste', () {
      late void Function(Map<String, dynamic>?) setClipboardData;
      late void Function(Object) setClipboardException;
      late void Function() resetClipboard;

      setUp(() {
        final mock = mockClipboardPaste();
        setClipboardData = mock.setData;
        setClipboardException = mock.setException;
        resetClipboard = mock.reset;
      });

      tearDown(() {
        resetClipboard();
      });

      testWidgets('pastes clipboard text into controller', (tester) async {
        late TextEditingController capturedController;
        late Future<void> Function() capturedPaste;

        final widget = _TestWidget(
          loginCallback: (_) async => _completeLoginResult(),
          onBuild: (controller, state, paste, submit, clearError) {
            capturedController = controller;
            capturedPaste = paste;
          },
        );
        await mountWidget(widget, tester);

        setClipboardData({'text': 'nsec1pasted'});

        await capturedPaste();
        await tester.pumpAndSettle();

        expect(capturedController.text, 'nsec1pasted');
      });

      testWidgets('clears error when pasting', (tester) async {
        late Future<void> Function() capturedPaste;
        late Future<LoginResult?> Function() capturedSubmit;
        late LoginWithNsecState capturedState;

        final widget = _TestWidget(
          loginCallback: (_) async {
            throw Exception('Invalid key');
          },
          onBuild: (controller, state, paste, submit, clearError) {
            capturedPaste = paste;
            capturedSubmit = submit;
            capturedState = state;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'nsec1test');
        await capturedSubmit();
        await tester.pump();

        expect(capturedState.error, isNotNull);

        setClipboardData({'text': 'nsec1pasted'});
        await capturedPaste();
        await tester.pump();

        expect(capturedState.error, isNull);
      });

      testWidgets('handles null clipboard gracefully', (tester) async {
        late TextEditingController capturedController;
        late Future<void> Function() capturedPaste;

        final widget = _TestWidget(
          loginCallback: (_) async => _completeLoginResult(),
          onBuild: (controller, state, paste, submit, clearError) {
            capturedController = controller;
            capturedPaste = paste;
          },
        );
        await mountWidget(widget, tester);

        setClipboardData(null);

        await capturedPaste();
        await tester.pumpAndSettle();

        expect(capturedController.text, isEmpty);
      });

      testWidgets('trims whitespace from clipboard text', (tester) async {
        late TextEditingController capturedController;
        late Future<void> Function() capturedPaste;

        final widget = _TestWidget(
          loginCallback: (_) async => _completeLoginResult(),
          onBuild: (controller, state, paste, submit, clearError) {
            capturedController = controller;
            capturedPaste = paste;
          },
        );
        await mountWidget(widget, tester);

        setClipboardData({'text': '   nsec1pasted   '});

        await capturedPaste();
        await tester.pumpAndSettle();

        expect(capturedController.text, 'nsec1pasted');
      });

      testWidgets('shows error when clipboard contains only whitespace', (tester) async {
        late LoginWithNsecState capturedState;
        late Future<void> Function() capturedPaste;

        final widget = _TestWidget(
          loginCallback: (_) async => _completeLoginResult(),
          onBuild: (controller, state, paste, submit, clearError) {
            capturedPaste = paste;
            capturedState = state;
          },
        );
        await mountWidget(widget, tester);

        setClipboardData({'text': '   '});

        await capturedPaste();
        await tester.pumpAndSettle();

        expect(capturedState.error, 'loginPasteNothingToPaste');
      });

      testWidgets('shows error when clipboard is empty string', (tester) async {
        late LoginWithNsecState capturedState;
        late Future<void> Function() capturedPaste;

        final widget = _TestWidget(
          loginCallback: (_) async => _completeLoginResult(),
          onBuild: (controller, state, paste, submit, clearError) {
            capturedPaste = paste;
            capturedState = state;
          },
        );
        await mountWidget(widget, tester);

        setClipboardData({'text': ''});

        await capturedPaste();
        await tester.pumpAndSettle();

        expect(capturedState.error, 'loginPasteNothingToPaste');
      });

      testWidgets('handles clipboard exception gracefully', (tester) async {
        late LoginWithNsecState capturedState;
        late Future<void> Function() capturedPaste;

        final widget = _TestWidget(
          loginCallback: (_) async => _completeLoginResult(),
          onBuild: (controller, state, paste, submit, clearError) {
            capturedPaste = paste;
            capturedState = state;
          },
        );
        await mountWidget(widget, tester);

        setClipboardException(Exception('Clipboard not available'));

        await capturedPaste();
        await tester.pumpAndSettle();

        expect(capturedState.error, 'loginPasteFailed');
      });
    });

    group('clearError', () {
      testWidgets('clears error', (tester) async {
        late Future<LoginResult?> Function() capturedSubmit;
        late void Function() capturedClearError;
        late LoginWithNsecState capturedState;

        final widget = _TestWidget(
          loginCallback: (_) async {
            throw Exception('Invalid key');
          },
          onBuild: (controller, state, paste, submit, clearError) {
            capturedSubmit = submit;
            capturedClearError = clearError;
            capturedState = state;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'nsec1test');
        await capturedSubmit();
        await tester.pump();

        expect(capturedState.error, isNotNull);

        capturedClearError();
        await tester.pump();

        expect(capturedState.error, isNull);
      });
    });
  });
}
