import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/widgets/wn_scroll_edge_effect.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_content_transition.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import '../test_helpers.dart';

void main() {
  group('WnSlate', () {
    group('header', () {
      testWidgets('renders header widget when provided', (tester) async {
        await mountWidget(
          WnSlate(
            header: WnSlateNavigationHeader(
              title: 'Test Title',
              onNavigate: () {},
            ),
          ),
          tester,
        );

        final headerFinder = find.byType(WnSlateNavigationHeader);
        expect(headerFinder, findsOneWidget);
        final header = tester.widget<WnSlateNavigationHeader>(headerFinder);
        expect(header.type, WnSlateNavigationType.close);
        expect(header.title, 'Test Title');
      });

      testWidgets('renders without header when not provided', (tester) async {
        await mountWidget(
          const WnSlate(),
          tester,
        );

        expect(find.byType(WnSlateNavigationHeader), findsNothing);
      });

      testWidgets('accepts any widget as header', (tester) async {
        await mountWidget(
          const WnSlate(
            header: Text('Custom Header'),
          ),
          tester,
        );

        expect(find.text('Custom Header'), findsOneWidget);
      });
    });

    group('child', () {
      testWidgets('renders child widget', (tester) async {
        await mountWidget(
          const WnSlate(
            child: Text('Child Content'),
          ),
          tester,
        );

        expect(find.text('Child Content'), findsOneWidget);
      });

      testWidgets('renders both header and child', (tester) async {
        await mountWidget(
          WnSlate(
            header: WnSlateNavigationHeader(
              title: 'Header',
              onNavigate: () {},
            ),
            child: const Text('Child Content'),
          ),
          tester,
        );

        expect(find.byType(WnSlateNavigationHeader), findsOneWidget);
        expect(find.text('Child Content'), findsOneWidget);
      });
    });

    group('systemNotice', () {
      testWidgets('renders systemNotice when provided', (tester) async {
        await mountWidget(
          const WnSlate(
            systemNotice: Text('System Notice'),
          ),
          tester,
        );

        expect(find.text('System Notice'), findsOneWidget);
      });

      testWidgets('does not render systemNotice when not provided', (tester) async {
        await mountWidget(
          const WnSlate(),
          tester,
        );

        expect(find.byType(WnSlate), findsOneWidget);
      });

      group('without shrinkWrapContent', () {
        testWidgets('child uses all available space left after system notice', (tester) async {
          await mountWidget(
            SizedBox(
              height: 500.h,
              child: const WnSlate(
                systemNotice: SizedBox(height: 40, key: Key('system_notice')),
                child: SizedBox.expand(key: Key('child')),
              ),
            ),
            tester,
          );

          final noticeHeight = tester.getSize(find.byKey(const Key('system_notice'))).height;
          final childHeight = tester.getSize(find.byKey(const Key('child'))).height;
          expect(noticeHeight, 40);
          expect(childHeight, greaterThanOrEqualTo(450));
        });
      });
    });

    group('footer', () {
      testWidgets('renders footer when provided', (tester) async {
        await mountWidget(
          const WnSlate(
            footer: Text('Footer Content'),
          ),
          tester,
        );

        expect(find.text('Footer Content'), findsOneWidget);
      });

      testWidgets('renders footer below child', (tester) async {
        await mountWidget(
          const WnSlate(
            footer: Text('Footer Content'),
            child: Text('Child Content'),
          ),
          tester,
        );

        final childOffset = tester.getTopLeft(find.text('Child Content'));
        final footerOffset = tester.getTopLeft(find.text('Footer Content'));
        expect(footerOffset.dy, greaterThan(childOffset.dy));
      });

      testWidgets('does not render footer when not provided', (tester) async {
        await mountWidget(
          const WnSlate(
            child: Text('Child Content'),
          ),
          tester,
        );

        expect(find.text('Footer Content'), findsNothing);
      });
    });

    group('scroll edge effects', () {
      Widget buildScrollableSlate({
        bool showTopScrollEffect = false,
        bool showBottomScrollEffect = false,
      }) {
        return SizedBox(
          height: 200.h,
          child: WnSlate(
            showTopScrollEffect: showTopScrollEffect,
            showBottomScrollEffect: showBottomScrollEffect,
            child: ListView.builder(
              itemCount: 50,
              itemBuilder: (context, index) => SizedBox(
                height: 50.h,
                child: Text('Item $index'),
              ),
            ),
          ),
        );
      }

      testWidgets('shows top scroll effect when scrolled down', (tester) async {
        await mountStackedWidget(
          buildScrollableSlate(showTopScrollEffect: true),
          tester,
        );

        expect(find.byType(WnScrollEdgeEffect), findsNothing);

        await tester.drag(find.byType(ListView), Offset(0, -100.h));
        await tester.pumpAndSettle();

        final effectFinders = find.byType(WnScrollEdgeEffect);
        expect(effectFinders, findsOneWidget);

        final effect = tester.widget<WnScrollEdgeEffect>(effectFinders);
        expect(effect.position, ScrollEdgePosition.top);
        expect(effect.type, ScrollEdgeEffectType.slate);
      });

      testWidgets('shows bottom scroll effect when content extends below', (tester) async {
        await mountStackedWidget(
          buildScrollableSlate(showBottomScrollEffect: true),
          tester,
        );

        await tester.pump();

        final effectFinders = find.byType(WnScrollEdgeEffect);
        expect(effectFinders, findsOneWidget);

        final effect = tester.widget<WnScrollEdgeEffect>(effectFinders);
        expect(effect.position, ScrollEdgePosition.bottom);
        expect(effect.type, ScrollEdgeEffectType.slate);
      });

      testWidgets('hides bottom scroll effect when scrolled to end', (tester) async {
        await mountStackedWidget(
          buildScrollableSlate(showBottomScrollEffect: true),
          tester,
        );

        await tester.pumpAndSettle();
        expect(find.byType(WnScrollEdgeEffect), findsOneWidget);

        await tester.dragUntilVisible(
          find.text('Item 49'),
          find.byType(ListView),
          Offset(0, -100.h),
        );
        await tester.pumpAndSettle();

        expect(find.byType(WnScrollEdgeEffect), findsNothing);
      });

      testWidgets('shows both scroll effects when scrolled to middle', (tester) async {
        await mountStackedWidget(
          buildScrollableSlate(
            showTopScrollEffect: true,
            showBottomScrollEffect: true,
          ),
          tester,
        );

        await tester.drag(find.byType(ListView), Offset(0, -100.h));
        await tester.pumpAndSettle();

        final effectFinders = find.byType(WnScrollEdgeEffect);
        expect(effectFinders, findsNWidgets(2));
      });

      testWidgets('hides scroll effects by default', (tester) async {
        await mountWidget(
          const WnSlate(
            child: Text('Content'),
          ),
          tester,
        );

        expect(find.byType(WnScrollEdgeEffect), findsNothing);
      });

      testWidgets('does not show scroll effects without child', (tester) async {
        await mountWidget(
          const WnSlate(
            showTopScrollEffect: true,
            showBottomScrollEffect: true,
          ),
          tester,
        );

        expect(find.byType(WnScrollEdgeEffect), findsNothing);
      });
    });

    group('styling', () {
      testWidgets('renders with rounded corners', (tester) async {
        await mountWidget(
          const WnSlate(),
          tester,
        );

        final containerFinder = find.byType(Container).first;
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.borderRadius, isNotNull);
      });

      testWidgets('renders with box shadow', (tester) async {
        await mountWidget(
          const WnSlate(),
          tester,
        );

        final containerFinder = find.byType(Container).first;
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, 2);
      });

      testWidgets('renders with horizontal margin', (tester) async {
        await mountWidget(
          const WnSlate(),
          tester,
        );

        final containerFinder = find.byType(Container).first;
        final container = tester.widget<Container>(containerFinder);

        expect(container.margin, isNotNull);
        expect(
          container.margin,
          isA<EdgeInsets>().having((m) => m.left, 'left', greaterThan(0)),
        );
        expect(
          container.margin,
          isA<EdgeInsets>().having((m) => m.right, 'right', greaterThan(0)),
        );
      });

      testWidgets('applies custom padding when provided', (tester) async {
        await mountWidget(
          const WnSlate(
            padding: EdgeInsets.all(20),
          ),
          tester,
        );

        final containerFinder = find.byType(Container).first;
        final container = tester.widget<Container>(containerFinder);

        expect(container.padding, const EdgeInsets.all(20));
      });
    });

    group('hero animation', () {
      testWidgets('wraps content in Hero widget', (tester) async {
        await mountWidget(
          const WnSlate(),
          tester,
        );

        expect(find.byType(Hero), findsOneWidget);
      });

      testWidgets('uses default tag', (tester) async {
        await mountWidget(
          const WnSlate(),
          tester,
        );

        final hero = tester.widget<Hero>(find.byType(Hero));
        expect(hero.tag, 'wn-slate');
      });

      testWidgets('uses custom tag when provided', (tester) async {
        await mountWidget(
          const WnSlate(tag: 'custom-tag'),
          tester,
        );

        final hero = tester.widget<Hero>(find.byType(Hero));
        expect(hero.tag, 'custom-tag');
      });

      testWidgets('has flightShuttleBuilder for animation', (tester) async {
        await mountWidget(
          const WnSlate(),
          tester,
        );

        final hero = tester.widget<Hero>(find.byType(Hero));
        expect(hero.flightShuttleBuilder, isNotNull);
      });

      testWidgets('flightShuttleBuilder returns Material with Container', (tester) async {
        await mountWidget(
          WnSlate(padding: EdgeInsets.all(10.w)),
          tester,
        );

        final hero = tester.widget<Hero>(find.byType(Hero));
        final flightShuttleBuilder = hero.flightShuttleBuilder!;

        final shuttle = flightShuttleBuilder(
          tester.element(find.byType(Hero)),
          const AlwaysStoppedAnimation(0.5),
          HeroFlightDirection.push,
          tester.element(find.byType(Hero)),
          tester.element(find.byType(Hero)),
        );

        expect(shuttle, isA<Material>());
        final material = shuttle as Material;
        expect(material.type, MaterialType.transparency);
        expect(material.child, isA<Container>());

        final container = material.child! as Container;
        expect(container.margin, isNotNull);
        expect(container.padding, EdgeInsets.all(10.w));
        expect(container.decoration, isA<BoxDecoration>());
      });
    });

    group('WnScrollEdgeEffect constructors', () {
      testWidgets('canvasTop creates canvas type with top position', (tester) async {
        await mountStackedWidget(
          const WnScrollEdgeEffect.canvasTop(color: Colors.black),
          tester,
        );

        final effect = tester.widget<WnScrollEdgeEffect>(find.byType(WnScrollEdgeEffect));
        expect(effect.type, ScrollEdgeEffectType.canvas);
        expect(effect.position, ScrollEdgePosition.top);
      });

      testWidgets('canvasBottom creates canvas type with bottom position', (tester) async {
        await mountStackedWidget(
          const WnScrollEdgeEffect.canvasBottom(color: Colors.black),
          tester,
        );

        final effect = tester.widget<WnScrollEdgeEffect>(find.byType(WnScrollEdgeEffect));
        expect(effect.type, ScrollEdgeEffectType.canvas);
        expect(effect.position, ScrollEdgePosition.bottom);
      });

      testWidgets('dropdownTop creates dropdown type with top position', (tester) async {
        await mountStackedWidget(
          const WnScrollEdgeEffect.dropdownTop(color: Colors.black),
          tester,
        );

        final effect = tester.widget<WnScrollEdgeEffect>(find.byType(WnScrollEdgeEffect));
        expect(effect.type, ScrollEdgeEffectType.dropdown);
        expect(effect.position, ScrollEdgePosition.top);
      });

      testWidgets('dropdownBottom creates dropdown type with bottom position', (tester) async {
        await mountStackedWidget(
          const WnScrollEdgeEffect.dropdownBottom(color: Colors.black),
          tester,
        );

        final effect = tester.widget<WnScrollEdgeEffect>(find.byType(WnScrollEdgeEffect));
        expect(effect.type, ScrollEdgeEffectType.dropdown);
        expect(effect.position, ScrollEdgePosition.bottom);
      });
    });

    group('content transition', () {
      testWidgets('wraps content in WnSlateContentTransition', (tester) async {
        await mountWidget(
          const WnSlate(
            child: Text('Content'),
          ),
          tester,
        );

        expect(find.byType(WnSlateContentTransition), findsOneWidget);
      });

      testWidgets('content is inside WnSlateContentTransition', (tester) async {
        await mountWidget(
          const WnSlate(
            child: Text('Child Content'),
          ),
          tester,
        );

        final transitionFinder = find.byType(WnSlateContentTransition);
        expect(transitionFinder, findsOneWidget);

        expect(
          find.descendant(
            of: transitionFinder,
            matching: find.text('Child Content'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('header is inside WnSlateContentTransition', (tester) async {
        await mountWidget(
          WnSlate(
            header: WnSlateNavigationHeader(
              title: 'Header',
              onNavigate: () {},
            ),
          ),
          tester,
        );

        final transitionFinder = find.byType(WnSlateContentTransition);
        expect(transitionFinder, findsOneWidget);

        expect(
          find.descendant(
            of: transitionFinder,
            matching: find.byType(WnSlateNavigationHeader),
          ),
          findsOneWidget,
        );
      });

      testWidgets('does not animate content when animateContent is false', (tester) async {
        await mountWidget(
          const WnSlate(
            animateContent: false,
            child: Text('Content'),
          ),
          tester,
        );

        expect(find.byType(WnSlateContentTransition), findsNothing);
        expect(find.text('Content'), findsOneWidget);
      });

      testWidgets('animates content by default', (tester) async {
        await mountWidget(
          const WnSlate(
            child: Text('Content'),
          ),
          tester,
        );

        expect(find.byType(WnSlateContentTransition), findsOneWidget);
      });
    });
  });
}
