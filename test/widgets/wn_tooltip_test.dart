import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart'
    show Align, Alignment, Center, Colors, Key, Scaffold, SizedBox, Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_tooltip.dart'
    show ArrowPainter, WnTooltip, WnTooltipPosition, WnTooltipTriggerMode;
import '../test_helpers.dart' show mountWidget, setUpTestView, testDesignSize;

void main() {
  group('WnTooltip tests', () {
    group('basic functionality', () {
      testWidgets('displays child widget', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(message: 'Tooltip message', child: Text('Hover me'));
        await mountWidget(widget, tester);
        expect(find.text('Hover me'), findsOneWidget);
      });

      testWidgets('does not show tooltip initially', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(message: 'Tooltip message', child: Text('Hover me'));
        await mountWidget(widget, tester);
        expect(find.byKey(const Key('tooltip_content')), findsNothing);
      });

      testWidgets('shows tooltip on long press', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(message: 'Tooltip message', child: Text('Hover me'));
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Hover me'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);
        expect(find.text('Tooltip message'), findsOneWidget);
      });

      testWidgets('shows tooltip on mouse hover', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(
          message: 'Tooltip message',
          waitDuration: Duration(milliseconds: 100),
          child: Text('Hover me'),
        );
        await mountWidget(widget, tester);

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        await gesture.moveTo(tester.getCenter(find.text('Hover me')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();

        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);
      });

      testWidgets('hides tooltip when tapping outside after hover', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = SizedBox(
          width: 300,
          height: 300,
          child: WnTooltip(
            message: 'Tooltip message',
            waitDuration: Duration(milliseconds: 100),
            child: Text('Hover me'),
          ),
        );
        await mountWidget(widget, tester);

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        await gesture.moveTo(tester.getCenter(find.text('Hover me')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);

        await tester.tapAt(const Offset(250, 250));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsNothing);
      });
    });

    group('positions', () {
      testWidgets('renders tooltip at top position by default', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(message: 'Top tooltip', child: Text('Trigger'));
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.text('Top tooltip'), findsOneWidget);
      });

      testWidgets('renders tooltip at bottom position', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(
          message: 'Bottom tooltip',
          position: WnTooltipPosition.bottom,
          child: Text('Trigger'),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.text('Bottom tooltip'), findsOneWidget);
      });

      testWidgets('renders tooltip at left position', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = Center(
          child: WnTooltip(
            message: 'Left tooltip',
            position: WnTooltipPosition.left,
            child: Text('Trigger'),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.text('Left tooltip'), findsOneWidget);
      });

      testWidgets('renders tooltip at right position', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = Center(
          child: WnTooltip(
            message: 'Right tooltip',
            position: WnTooltipPosition.right,
            child: Text('Trigger'),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.text('Right tooltip'), findsOneWidget);
      });

      testWidgets('left position places tooltip to the left of trigger', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        const widget = Center(
          child: WnTooltip(
            message: 'Left',
            position: WnTooltipPosition.left,
            child: SizedBox(width: 50, height: 50, child: Text('T')),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('T'));
        await tester.pumpAndSettle();

        final tooltipBox = tester.getRect(find.byKey(const Key('tooltip_content')));
        final triggerBox = tester.getRect(find.text('T'));
        expect(tooltipBox.right, lessThanOrEqualTo(triggerBox.left + 10));
      });

      testWidgets('right position places tooltip to the right of trigger', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        const widget = Center(
          child: WnTooltip(
            message: 'Right',
            position: WnTooltipPosition.right,
            child: SizedBox(width: 50, height: 50, child: Text('T')),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('T'));
        await tester.pumpAndSettle();

        final tooltipBox = tester.getRect(find.byKey(const Key('tooltip_content')));
        final triggerBox = tester.getRect(find.text('T'));
        expect(tooltipBox.left, greaterThanOrEqualTo(triggerBox.right - 10));
      });
    });

    group('arrow', () {
      testWidgets('shows arrow by default for top position', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(message: 'With arrow', child: Text('Trigger'));
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_arrow')), findsOneWidget);
      });

      testWidgets('shows arrow by default for bottom position', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(
          message: 'With arrow',
          position: WnTooltipPosition.bottom,
          child: Text('Trigger'),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_arrow')), findsOneWidget);
      });

      testWidgets('shows arrow for left position', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = Center(
          child: WnTooltip(
            message: 'With arrow',
            position: WnTooltipPosition.left,
            child: Text('Trigger'),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_arrow')), findsOneWidget);
      });

      testWidgets('shows arrow for right position', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = Center(
          child: WnTooltip(
            message: 'With arrow',
            position: WnTooltipPosition.right,
            child: Text('Trigger'),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_arrow')), findsOneWidget);
      });

      testWidgets('hides arrow when showArrow is false', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(
          message: 'No arrow',
          showArrow: false,
          child: Text('Trigger'),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_arrow')), findsNothing);
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);
      });

      testWidgets('hides arrow for bottom position when showArrow is false', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        const widget = WnTooltip(
          message: 'No arrow',
          position: WnTooltipPosition.bottom,
          showArrow: false,
          child: Text('Trigger'),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_arrow')), findsNothing);
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);
      });

      testWidgets('hides arrow for left position when showArrow is false', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        const widget = Center(
          child: WnTooltip(
            message: 'No arrow',
            position: WnTooltipPosition.left,
            showArrow: false,
            child: Text('Trigger'),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_arrow')), findsNothing);
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);
      });

      testWidgets('hides arrow for right position when showArrow is false', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        const widget = Center(
          child: WnTooltip(
            message: 'No arrow',
            position: WnTooltipPosition.right,
            showArrow: false,
            child: Text('Trigger'),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_arrow')), findsNothing);
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);
      });

      testWidgets('showArrow defaults to true', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(message: 'Default', child: Text('Trigger'));
        await mountWidget(widget, tester);
        final tooltip = tester.widget<WnTooltip>(find.byType(WnTooltip));
        expect(tooltip.showArrow, isTrue);
      });
    });

    group('custom content', () {
      testWidgets('displays message text', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(message: 'Custom message', child: Text('Trigger'));
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.text('Custom message'), findsOneWidget);
      });

      testWidgets('displays custom content widget', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(
          message: '',
          content: SizedBox(
            key: Key('custom_content_widget'),
            width: 100,
            height: 50,
            child: Text('Custom Widget'),
          ),
          child: Text('Trigger'),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('custom_content_widget')), findsOneWidget);
        expect(find.text('Custom Widget'), findsOneWidget);
      });

      testWidgets('content widget takes precedence over message', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(
          message: 'Message text',
          content: Text('Content widget', key: Key('content_text')),
          child: Text('Trigger'),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('content_text')), findsOneWidget);
        expect(find.text('Content widget'), findsOneWidget);
      });
    });

    group('trigger behavior', () {
      testWidgets('tapping outside hides tooltip', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: WnTooltip(message: 'Tooltip', child: Text('Trigger')),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsNothing);
      });

      testWidgets('shows tooltip on tap when triggerMode is tap', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(
          message: 'Tap tooltip',
          child: Text('Tap me'),
        );
        await mountWidget(widget, tester);
        await tester.tap(find.text('Tap me'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);
        expect(find.text('Tap tooltip'), findsOneWidget);
      });

      testWidgets('does not show tooltip on tap when triggerMode is longPress', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        const widget = WnTooltip(
          message: 'Long press tooltip',
          triggerMode: WnTooltipTriggerMode.longPress,
          child: Text('Long press me'),
        );
        await mountWidget(widget, tester);
        await tester.tap(find.text('Long press me'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsNothing);
      });

      testWidgets('long press shows tooltip regardless of triggerMode', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        const widget = WnTooltip(
          message: 'Tooltip via long press',
          child: Text('Long press me'),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Long press me'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);
        expect(find.text('Tooltip via long press'), findsOneWidget);
      });

      testWidgets('defaults to tap trigger mode', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(message: 'Default tooltip', child: Text('Trigger'));
        await mountWidget(widget, tester);
        final tooltip = tester.widget<WnTooltip>(find.byType(WnTooltip));
        expect(tooltip.triggerMode, WnTooltipTriggerMode.tap);
      });
    });

    group('wait duration', () {
      testWidgets('respects custom wait duration', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(
          message: 'Delayed tooltip',
          waitDuration: Duration(milliseconds: 200),
          child: Text('Hover me'),
        );
        await mountWidget(widget, tester);

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        await gesture.moveTo(tester.getCenter(find.text('Hover me')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();
        expect(find.byKey(const Key('tooltip_content')), findsNothing);

        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);
      });
    });

    group('mouse exit behavior', () {
      testWidgets('hides tooltip when mouse exits', (WidgetTester tester) async {
        setUpTestView(tester);
        final widget = const SizedBox(
          width: 300,
          height: 300,
          child: Center(
            child: WnTooltip(
              message: 'Tooltip message',
              waitDuration: Duration(milliseconds: 100),
              child: SizedBox(width: 100, height: 50, child: Text('Hover me')),
            ),
          ),
        );
        await mountWidget(widget, tester);

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        await gesture.moveTo(tester.getCenter(find.text('Hover me')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);

        await gesture.moveTo(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsNothing);
      });

      testWidgets('allows tooltip to show again after mouse exits and re-enters', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        final widget = const SizedBox(
          width: 300,
          height: 300,
          child: Center(
            child: WnTooltip(
              message: 'Tooltip message',
              waitDuration: Duration(milliseconds: 100),
              child: SizedBox(width: 100, height: 50, child: Text('Hover me')),
            ),
          ),
        );
        await mountWidget(widget, tester);

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        await gesture.moveTo(tester.getCenter(find.text('Hover me')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsNothing);

        await gesture.moveTo(const Offset(10, 10));
        await tester.pumpAndSettle();

        await gesture.moveTo(tester.getCenter(find.text('Hover me')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);
      });

      testWidgets('tap reopens tooltip after dismiss without mouse exit', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        final widget = const SizedBox(
          width: 300,
          height: 300,
          child: Center(
            child: WnTooltip(
              message: 'Tooltip message',
              child: SizedBox(width: 100, height: 50, child: Text('Tap me')),
            ),
          ),
        );
        await mountWidget(widget, tester);

        await tester.tap(find.text('Tap me'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsNothing);

        await tester.tap(find.text('Tap me'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);
      });

      testWidgets('long press reopens tooltip after dismiss without mouse exit', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        final widget = const SizedBox(
          width: 300,
          height: 300,
          child: Center(
            child: WnTooltip(
              message: 'Tooltip message',
              triggerMode: WnTooltipTriggerMode.longPress,
              child: SizedBox(width: 100, height: 50, child: Text('Long press me')),
            ),
          ),
        );
        await mountWidget(widget, tester);

        await tester.longPress(find.text('Long press me'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsNothing);

        await tester.longPress(find.text('Long press me'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('tooltip_content')), findsOneWidget);
      });
    });

    group('screen edge awareness', () {
      testWidgets('tooltip near left edge shifts right to stay on screen', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        final widget = const Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: Align(
              alignment: Alignment.centerLeft,
              child: WnTooltip(
                message: 'This is a tooltip with long text',
                child: SizedBox(width: 20, height: 20, child: Text('L')),
              ),
            ),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('L'));
        await tester.pumpAndSettle();

        final tooltipContent = find.byKey(const Key('tooltip_content'));
        expect(tooltipContent, findsOneWidget);

        final tooltipBox = tester.getRect(tooltipContent);
        expect(tooltipBox.left, greaterThanOrEqualTo(0));
      });

      testWidgets('tooltip near right edge shifts left to stay on screen', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        final widget = const Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: Align(
              alignment: Alignment.centerRight,
              child: WnTooltip(
                message: 'This is a tooltip with long text',
                child: SizedBox(width: 20, height: 20, child: Text('R')),
              ),
            ),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('R'));
        await tester.pumpAndSettle();

        final tooltipContent = find.byKey(const Key('tooltip_content'));
        expect(tooltipContent, findsOneWidget);

        final tooltipBox = tester.getRect(tooltipContent);
        expect(tooltipBox.right, lessThanOrEqualTo(400));
      });

      testWidgets('arrow remains pointing at target when tooltip shifts', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        final widget = const Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: Align(
              alignment: Alignment.centerLeft,
              child: WnTooltip(
                message: 'This is a tooltip with long text',
                child: SizedBox(width: 20, height: 20, child: Text('L')),
              ),
            ),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('L'));
        await tester.pumpAndSettle();

        final arrow = find.byKey(const Key('tooltip_arrow'));
        expect(arrow, findsOneWidget);

        final arrowBox = tester.getRect(arrow);
        final triggerBox = tester.getRect(find.text('L'));

        final arrowCenterX = arrowBox.center.dx;
        final triggerCenterX = triggerBox.center.dx;
        expect((arrowCenterX - triggerCenterX).abs(), lessThanOrEqualTo(2));
      });

      testWidgets('tooltip near top edge shifts down for left-positioned tooltip', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        final widget = const Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: Align(
              alignment: Alignment.topLeft,
              child: WnTooltip(
                message: 'This is a tooltip with long text',
                position: WnTooltipPosition.left,
                child: SizedBox(width: 20, height: 20, child: Text('T')),
              ),
            ),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('T'));
        await tester.pumpAndSettle();

        final tooltipContent = find.byKey(const Key('tooltip_content'));
        expect(tooltipContent, findsOneWidget);

        final tooltipBox = tester.getRect(tooltipContent);
        expect(tooltipBox.top, greaterThanOrEqualTo(0));
      });

      testWidgets('tooltip near bottom edge shifts up for right-positioned tooltip', (
        WidgetTester tester,
      ) async {
        setUpTestView(tester);
        final widget = const Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: Align(
              alignment: Alignment.bottomRight,
              child: WnTooltip(
                message: 'This is a tooltip with long text',
                position: WnTooltipPosition.right,
                child: SizedBox(width: 20, height: 20, child: Text('B')),
              ),
            ),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('B'));
        await tester.pumpAndSettle();

        final tooltipContent = find.byKey(const Key('tooltip_content'));
        expect(tooltipContent, findsOneWidget);

        final tooltipBox = tester.getRect(tooltipContent);
        expect(tooltipBox.bottom, lessThanOrEqualTo(testDesignSize.height));
      });
    });

    group('arrow painter', () {
      testWidgets('renders arrow for top position tooltip', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(
          message: 'Tooltip',
          child: Text('Trigger'),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('tooltip_arrow')), findsOneWidget);
      });

      testWidgets('renders arrow for bottom position tooltip', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = WnTooltip(
          message: 'Tooltip',
          position: WnTooltipPosition.bottom,
          child: Text('Trigger'),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('tooltip_arrow')), findsOneWidget);
      });

      testWidgets('renders arrow for left position tooltip', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = Center(
          child: WnTooltip(
            message: 'Tooltip',
            position: WnTooltipPosition.left,
            child: Text('Trigger'),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('tooltip_arrow')), findsOneWidget);
      });

      testWidgets('renders arrow for right position tooltip', (WidgetTester tester) async {
        setUpTestView(tester);
        const widget = Center(
          child: WnTooltip(
            message: 'Tooltip',
            position: WnTooltipPosition.right,
            child: Text('Trigger'),
          ),
        );
        await mountWidget(widget, tester);
        await tester.longPress(find.text('Trigger'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('tooltip_arrow')), findsOneWidget);
      });

      test('shouldRepaint returns true when position changes', () {
        final painter1 = ArrowPainter(position: WnTooltipPosition.top, color: Colors.black);
        final painter2 = ArrowPainter(position: WnTooltipPosition.bottom, color: Colors.black);

        expect(painter2.shouldRepaint(painter1), isTrue);
      });

      test('shouldRepaint returns true when color changes', () {
        final painter1 = ArrowPainter(position: WnTooltipPosition.top, color: Colors.black);
        final painter2 = ArrowPainter(position: WnTooltipPosition.top, color: Colors.white);

        expect(painter2.shouldRepaint(painter1), isTrue);
      });

      test('shouldRepaint returns false when nothing changes', () {
        final painter1 = ArrowPainter(position: WnTooltipPosition.top, color: Colors.black);
        final painter2 = ArrowPainter(position: WnTooltipPosition.top, color: Colors.black);

        expect(painter2.shouldRepaint(painter1), isFalse);
      });

      test('shouldRepaint returns true when position changes to left', () {
        final painter1 = ArrowPainter(position: WnTooltipPosition.top, color: Colors.black);
        final painter2 = ArrowPainter(position: WnTooltipPosition.left, color: Colors.black);

        expect(painter2.shouldRepaint(painter1), isTrue);
      });

      test('shouldRepaint returns true when position changes to right', () {
        final painter1 = ArrowPainter(position: WnTooltipPosition.top, color: Colors.black);
        final painter2 = ArrowPainter(position: WnTooltipPosition.right, color: Colors.black);

        expect(painter2.shouldRepaint(painter1), isTrue);
      });
    });
  });
}
