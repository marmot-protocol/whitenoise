import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_add_relay.dart';
import 'package:whitenoise/utils/relay_url_validation.dart';
import '../mocks/mock_clipboard_paste.dart';
import '../test_helpers.dart';

class _TestWidget extends HookWidget {
  final void Function(
    TextEditingController controller,
    bool isValid,
    RelayValidationError? validationError,
    void Function() paste,
  )
  onBuild;

  const _TestWidget({required this.onBuild});

  @override
  Widget build(BuildContext context) {
    final (:controller, :isValid, :validationError, :paste) = useAddRelay();
    onBuild(controller, isValid, validationError, paste);
    return Column(
      children: [
        TextField(controller: controller),
        Text('valid: $isValid'),
        Text('error: ${validationError?.toString() ?? 'none'}'),
        ElevatedButton(onPressed: paste, child: const Text('Paste')),
      ],
    );
  }
}

void main() {
  group('useAddRelay', () {
    testWidgets('initializes with wss:// prefix', (tester) async {
      late TextEditingController capturedController;

      final widget = _TestWidget(
        onBuild: (controller, isValid, validationError, paste) {
          capturedController = controller;
        },
      );
      await mountWidget(widget, tester);

      expect(capturedController.text, 'wss://');
    });

    testWidgets('starts with invalid state', (tester) async {
      late bool capturedIsValid;

      final widget = _TestWidget(
        onBuild: (controller, isValid, validationError, paste) {
          capturedIsValid = isValid;
        },
      );
      await mountWidget(widget, tester);

      expect(capturedIsValid, false);
    });

    testWidgets('starts with no validation error', (tester) async {
      late RelayValidationError? capturedError;

      final widget = _TestWidget(
        onBuild: (controller, isValid, validationError, paste) {
          capturedError = validationError;
        },
      );
      await mountWidget(widget, tester);

      expect(capturedError, isNull);
    });

    testWidgets('validates URL after debounce', (tester) async {
      late bool capturedIsValid;

      final widget = _TestWidget(
        onBuild: (controller, isValid, validationError, paste) {
          capturedIsValid = isValid;
        },
      );
      await mountWidget(widget, tester);

      await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
      await tester.pump(const Duration(milliseconds: 600));

      expect(capturedIsValid, true);
    });

    testWidgets('sets isValid to false immediately on text change', (tester) async {
      late bool capturedIsValid;

      final widget = _TestWidget(
        onBuild: (controller, isValid, validationError, paste) {
          capturedIsValid = isValid;
        },
      );
      await mountWidget(widget, tester);

      await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
      await tester.pump(const Duration(milliseconds: 600));
      expect(capturedIsValid, true);

      await tester.enterText(find.byType(TextField), 'wss://relay.example.com/test');
      await tester.pump();

      expect(capturedIsValid, false);
    });

    testWidgets('returns error for invalid URL format', (tester) async {
      late RelayValidationError? capturedError;

      final widget = _TestWidget(
        onBuild: (controller, isValid, validationError, paste) {
          capturedError = validationError;
        },
      );
      await mountWidget(widget, tester);

      await tester.enterText(find.byType(TextField), 'https://relay.example.com');
      await tester.pump(const Duration(milliseconds: 600));

      expect(capturedError, RelayValidationError.invalidScheme);
    });

    testWidgets('returns error for double wss:// URL', (tester) async {
      late RelayValidationError? capturedError;

      final widget = _TestWidget(
        onBuild: (controller, isValid, validationError, paste) {
          capturedError = validationError;
        },
      );
      await mountWidget(widget, tester);

      await tester.enterText(find.byType(TextField), 'wss://wss://relay.example.com');
      await tester.pump(const Duration(milliseconds: 600));

      expect(capturedError, RelayValidationError.invalidUrl);
    });

    testWidgets('returns error for URL with invalid host format', (tester) async {
      late RelayValidationError? capturedError;

      final widget = _TestWidget(
        onBuild: (controller, isValid, validationError, paste) {
          capturedError = validationError;
        },
      );
      await mountWidget(widget, tester);

      await tester.enterText(find.byType(TextField), 'wss://localhost');
      await tester.pump(const Duration(milliseconds: 600));

      expect(capturedError, RelayValidationError.invalidUrl);
    });

    testWidgets('accepts valid ws:// URL', (tester) async {
      late bool capturedIsValid;

      final widget = _TestWidget(
        onBuild: (controller, isValid, validationError, paste) {
          capturedIsValid = isValid;
        },
      );
      await mountWidget(widget, tester);

      await tester.enterText(find.byType(TextField), 'ws://local.relay.com');
      await tester.pump(const Duration(milliseconds: 600));

      expect(capturedIsValid, true);
    });

    testWidgets('keeps invalid state for empty wss:// prefix', (tester) async {
      late bool capturedIsValid;
      late RelayValidationError? capturedError;

      final widget = _TestWidget(
        onBuild: (controller, isValid, validationError, paste) {
          capturedIsValid = isValid;
          capturedError = validationError;
        },
      );
      await mountWidget(widget, tester);

      await tester.enterText(find.byType(TextField), 'wss://');
      await tester.pump(const Duration(milliseconds: 600));

      expect(capturedIsValid, false);
      expect(capturedError, isNull);
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

      testWidgets('pastes wss:// URL directly', (tester) async {
        late TextEditingController capturedController;

        final widget = _TestWidget(
          onBuild: (controller, isValid, validationError, paste) {
            capturedController = controller;
          },
        );
        await mountWidget(widget, tester);

        setClipboardData({'text': 'wss://pasted.relay.com'});

        await tester.tap(find.text('Paste'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(capturedController.text, 'wss://pasted.relay.com');
      });

      testWidgets('adds wss:// prefix when pasting non-websocket URL', (tester) async {
        late TextEditingController capturedController;

        final widget = _TestWidget(
          onBuild: (controller, isValid, validationError, paste) {
            capturedController = controller;
          },
        );
        await mountWidget(widget, tester);

        setClipboardData({'text': 'relay.example.com'});

        await tester.tap(find.text('Paste'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(capturedController.text, 'wss://relay.example.com');
      });

      testWidgets('pastes ws:// URL directly', (tester) async {
        late TextEditingController capturedController;

        final widget = _TestWidget(
          onBuild: (controller, isValid, validationError, paste) {
            capturedController = controller;
          },
        );
        await mountWidget(widget, tester);

        setClipboardData({'text': 'ws://local.relay.com'});

        await tester.tap(find.text('Paste'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(capturedController.text, 'ws://local.relay.com');
      });

      testWidgets('handles empty clipboard gracefully', (tester) async {
        late TextEditingController capturedController;

        final widget = _TestWidget(
          onBuild: (controller, isValid, validationError, paste) {
            capturedController = controller;
          },
        );
        await mountWidget(widget, tester);

        setClipboardData(null);

        await tester.tap(find.text('Paste'));
        await tester.pumpAndSettle();

        expect(capturedController.text, 'wss://');
      });

      testWidgets('handles clipboard exception gracefully', (tester) async {
        late TextEditingController capturedController;

        final widget = _TestWidget(
          onBuild: (controller, isValid, validationError, paste) {
            capturedController = controller;
          },
        );
        await mountWidget(widget, tester);

        setClipboardException(Exception('Clipboard not available'));

        await tester.tap(find.text('Paste'));
        await tester.pumpAndSettle();

        expect(capturedController.text, 'wss://');
      });
    });
  });
}
