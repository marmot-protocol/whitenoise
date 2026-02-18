import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_confirmation_slate.dart';

import '../test_helpers.dart';

void main() {
  group('WnConfirmationSlate', () {
    testWidgets('displays title and message', (tester) async {
      await mountWidget(
        WnConfirmationSlate(
          title: 'Test Title',
          message: 'Test Message',
          confirmText: 'Confirm',
          cancelText: 'Cancel',
          onConfirm: () {},
          onCancel: () {},
        ),
        tester,
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
    });

    testWidgets('displays confirm and cancel buttons', (tester) async {
      await mountWidget(
        WnConfirmationSlate(
          title: 'Test Title',
          message: 'Test Message',
          confirmText: 'Confirm',
          cancelText: 'Cancel',
          onConfirm: () {},
          onCancel: () {},
        ),
        tester,
      );

      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('confirm button calls onConfirm', (tester) async {
      var confirmed = false;

      await mountWidget(
        WnConfirmationSlate(
          title: 'Test Title',
          message: 'Test Message',
          confirmText: 'Confirm',
          cancelText: 'Cancel',
          onConfirm: () => confirmed = true,
          onCancel: () {},
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pumpAndSettle();

      expect(confirmed, true);
    });

    testWidgets('cancel button calls onCancel', (tester) async {
      var cancelled = false;

      await mountWidget(
        WnConfirmationSlate(
          title: 'Test Title',
          message: 'Test Message',
          confirmText: 'Confirm',
          cancelText: 'Cancel',
          onConfirm: () {},
          onCancel: () => cancelled = true,
        ),
        tester,
      );

      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pumpAndSettle();

      expect(cancelled, true);
    });

    testWidgets('uses destructive button style when isDestructive is true', (tester) async {
      await mountWidget(
        WnConfirmationSlate(
          title: 'Test Title',
          message: 'Test Message',
          confirmText: 'Delete',
          cancelText: 'Cancel',
          onConfirm: () {},
          onCancel: () {},
          isDestructive: true,
        ),
        tester,
      );

      expect(find.text('Delete'), findsOneWidget);

      final confirmButton = tester.widget<WnButton>(find.byKey(const Key('confirm_button')));
      expect(confirmButton.type, WnButtonType.destructive);
    });

    testWidgets('loading state disables cancel button', (tester) async {
      await mountWidget(
        WnConfirmationSlate(
          title: 'Test Title',
          message: 'Test Message',
          confirmText: 'Confirm',
          cancelText: 'Cancel',
          onConfirm: () {},
          onCancel: () {},
          loading: true,
        ),
        tester,
      );

      final cancelButton = tester.widget<WnButton>(find.byKey(const Key('cancel_button')));
      expect(cancelButton.disabled, true);
    });

    testWidgets('loading state shows loading on confirm button', (tester) async {
      await mountWidget(
        WnConfirmationSlate(
          title: 'Test Title',
          message: 'Test Message',
          confirmText: 'Confirm',
          cancelText: 'Cancel',
          onConfirm: () {},
          onCancel: () {},
          loading: true,
        ),
        tester,
      );

      final confirmButton = tester.widget<WnButton>(find.byKey(const Key('confirm_button')));
      expect(confirmButton.loading, true);
      expect(confirmButton.disabled, true);
    });

    testWidgets('loading state hides back button', (tester) async {
      await mountWidget(
        WnConfirmationSlate(
          title: 'Test Title',
          message: 'Test Message',
          confirmText: 'Confirm',
          cancelText: 'Cancel',
          onConfirm: () {},
          onCancel: () {},
          loading: true,
        ),
        tester,
      );

      expect(find.byKey(const Key('slate_back_button')), findsNothing);
    });

    group('async confirmation', () {
      testWidgets('show with onConfirmAsync shows loading on confirm button', (tester) async {
        final completer = Completer<bool>();

        await mountTestApp(tester);

        final context = tester.element(find.byType(Scaffold));

        WnConfirmationSlate.show(
          context: context,
          title: 'Test Title',
          message: 'Test Message',
          confirmText: 'Confirm',
          cancelText: 'Cancel',
          onConfirmAsync: () => completer.future,
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm_button')));
        await tester.pump();

        final confirmButton = tester.widget<WnButton>(find.byKey(const Key('confirm_button')));
        expect(confirmButton.loading, true);

        completer.complete(true);
        await tester.pumpAndSettle();
      });

      testWidgets('show with onConfirmAsync returns true on success', (tester) async {
        bool? result;

        await mountTestApp(tester);

        final context = tester.element(find.byType(Scaffold));

        WnConfirmationSlate.show(
          context: context,
          title: 'Test Title',
          message: 'Test Message',
          confirmText: 'Confirm',
          cancelText: 'Cancel',
          onConfirmAsync: () async => true,
        ).then((value) => result = value);

        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm_button')));
        await tester.pumpAndSettle();

        expect(result, true);
      });

      testWidgets('show with onConfirmAsync returns false on failure', (tester) async {
        bool? result;

        await mountTestApp(tester);

        final context = tester.element(find.byType(Scaffold));

        WnConfirmationSlate.show(
          context: context,
          title: 'Test Title',
          message: 'Test Message',
          confirmText: 'Confirm',
          cancelText: 'Cancel',
          onConfirmAsync: () async => false,
        ).then((value) => result = value);

        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm_button')));
        await tester.pumpAndSettle();

        expect(result, false);
      });

      testWidgets('show with onConfirmAsync returns null on cancel', (tester) async {
        bool? result = true;

        await mountTestApp(tester);

        final context = tester.element(find.byType(Scaffold));

        WnConfirmationSlate.show(
          context: context,
          title: 'Test Title',
          message: 'Test Message',
          confirmText: 'Confirm',
          cancelText: 'Cancel',
          onConfirmAsync: () async => true,
        ).then((value) => result = value);

        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('cancel_button')));
        await tester.pumpAndSettle();

        expect(result, isNull);
      });

      testWidgets('show with onConfirmAsync disables dismiss during loading', (tester) async {
        final completer = Completer<bool>();

        await mountTestApp(tester);

        final context = tester.element(find.byType(Scaffold));

        WnConfirmationSlate.show(
          context: context,
          title: 'Test Title',
          message: 'Test Message',
          confirmText: 'Confirm',
          cancelText: 'Cancel',
          onConfirmAsync: () => completer.future,
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm_button')));
        await tester.pump();

        final cancelButton = tester.widget<WnButton>(find.byKey(const Key('cancel_button')));
        expect(cancelButton.disabled, true);

        expect(find.byKey(const Key('slate_back_button')), findsNothing);

        completer.complete(true);
        await tester.pumpAndSettle();
      });
    });
  });
}
