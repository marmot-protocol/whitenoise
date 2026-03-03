import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_relay_input.dart';
import 'package:whitenoise/widgets/wn_icon.dart' show WnIcons;
import '../mocks/mock_clipboard_paste.dart';
import '../test_helpers.dart';

class _TestWidget extends HookWidget {
  final void Function(RelayInputResult result) onBuild;

  const _TestWidget({required this.onBuild});

  @override
  Widget build(BuildContext context) {
    final result = useRelayInput();
    onBuild(result);
    return Column(
      children: [
        TextField(controller: result.controller),
        Text('valid: ${result.isValid}'),
        Text('error: ${result.validationError ?? 'none'}'),
        Text('trailingIcon: ${result.trailingIcon.name}'),
        Text('trailingKey: ${result.trailingKey}'),
        ElevatedButton(
          key: Key(result.trailingKey),
          onPressed: result.handleTrailingAction,
          child: const Text('Trailing Action'),
        ),
      ],
    );
  }
}

void main() {
  group('useRelayInput', () {
    group('initial state', () {
      testWidgets('initializes with wss:// prefix', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        expect(capturedResult.controller.text, 'wss://');
      });

      testWidgets('starts with invalid state', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        expect(capturedResult.isValid, false);
      });

      testWidgets('starts with no validation error', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        expect(capturedResult.validationError, isNull);
      });

      testWidgets('starts with paste trailing icon', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        expect(capturedResult.trailingIcon, WnIcons.paste);
        expect(capturedResult.trailingKey, 'paste_button');
      });
    });

    group('validation', () {
      testWidgets('validates URL after debounce', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));

        expect(capturedResult.isValid, true);
      });

      testWidgets('sets isValid to false immediately on text change', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));
        expect(capturedResult.isValid, true);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com/test');
        await tester.pump();

        expect(capturedResult.isValid, false);
      });

      testWidgets('returns error for invalid URL format', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'https://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));

        expect(capturedResult.validationError, 'invalidRelayUrlScheme');
      });

      testWidgets('returns error for double wss:// URL', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));

        expect(capturedResult.validationError, 'invalidRelayUrl');
      });

      testWidgets('returns error for URL with invalid host format', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://localhost');
        await tester.pump(const Duration(milliseconds: 600));

        expect(capturedResult.validationError, 'invalidRelayUrl');
      });

      testWidgets('accepts valid ws:// URL', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'ws://local.relay.com');
        await tester.pump(const Duration(milliseconds: 600));

        expect(capturedResult.isValid, true);
      });

      testWidgets('keeps invalid state for empty wss:// prefix', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://');
        await tester.pump(const Duration(milliseconds: 600));

        expect(capturedResult.isValid, false);
        expect(capturedResult.validationError, isNull);
      });
    });

    group('trailing icon', () {
      testWidgets('shows paste icon when it has no text', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        expect(capturedResult.trailingIcon, WnIcons.paste);
        expect(capturedResult.trailingKey, 'paste_button');
      });

      testWidgets('shows clear icon when it has text', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();

        expect(capturedResult.trailingIcon, WnIcons.closeSmall);
        expect(capturedResult.trailingKey, 'clear_button');
      });
    });

    group('clear', () {
      testWidgets('resets controller to wss://', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump(const Duration(milliseconds: 600));

        expect(capturedResult.controller.text, 'wss://relay.example.com');
        expect(capturedResult.isValid, true);

        await tester.tap(find.byKey(const Key('clear_button')));
        await tester.pump();

        expect(capturedResult.controller.text, 'wss://');
        expect(capturedResult.isValid, false);
        expect(capturedResult.validationError, isNull);
      });

      testWidgets('clears validation error', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://invalid');
        await tester.pump(const Duration(milliseconds: 600));

        expect(capturedResult.validationError, isNotNull);

        await tester.tap(find.byKey(const Key('clear_button')));
        await tester.pump();

        expect(capturedResult.validationError, isNull);
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

      testWidgets('pastes wss:// URL directly', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        setClipboardData({'text': 'wss://pasted.relay.com'});

        await tester.tap(find.byKey(const Key('paste_button')));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(capturedResult.controller.text, 'wss://pasted.relay.com');
      });

      testWidgets('adds wss:// prefix when pasting non-websocket URL', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        setClipboardData({'text': 'relay.example.com'});

        await tester.tap(find.byKey(const Key('paste_button')));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(capturedResult.controller.text, 'wss://relay.example.com');
      });

      testWidgets('pastes ws:// URL directly', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        setClipboardData({'text': 'ws://local.relay.com'});

        await tester.tap(find.byKey(const Key('paste_button')));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(capturedResult.controller.text, 'ws://local.relay.com');
      });

      testWidgets('handles empty clipboard gracefully', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        setClipboardData(null);

        await tester.tap(find.byKey(const Key('paste_button')));
        await tester.pumpAndSettle();

        expect(capturedResult.controller.text, 'wss://');
      });

      testWidgets('handles clipboard exception gracefully', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        setClipboardException(Exception('Clipboard not available'));

        await tester.tap(find.byKey(const Key('paste_button')));
        await tester.pumpAndSettle();

        expect(capturedResult.controller.text, 'wss://');
      });
    });

    group('handleTrailingAction', () {
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

      testWidgets('calls paste when it has no text', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        setClipboardData({'text': 'wss://pasted.relay.com'});

        await tester.tap(find.byKey(const Key('paste_button')));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(capturedResult.controller.text, 'wss://pasted.relay.com');
      });

      testWidgets('calls clear when it has text', (tester) async {
        late RelayInputResult capturedResult;

        final widget = _TestWidget(
          onBuild: (result) {
            capturedResult = result;
          },
        );
        await mountWidget(widget, tester);

        await tester.enterText(find.byType(TextField), 'wss://relay.example.com');
        await tester.pump();

        await tester.tap(find.byKey(const Key('clear_button')));
        await tester.pump();

        expect(capturedResult.controller.text, 'wss://');
      });
    });
  });
}
