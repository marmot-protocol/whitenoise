import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/l10n/generated/app_localizations_en.dart';
import 'package:whitenoise/widgets/offline_system_notice.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../test_helpers.dart';

void main() {
  group('OfflineSystemNotice', () {
    Future<void> pumpNotice(WidgetTester tester) async {
      await mountWidget(const OfflineSystemNotice(), tester);
      await tester.pumpAndSettle();
    }

    testWidgets('uses stable offline notice key', (tester) async {
      await pumpNotice(tester);
      expect(find.byKey(const Key('offline_notice')), findsOneWidget);
    });

    testWidgets('shows waiting-for-internet title', (tester) async {
      await pumpNotice(tester);
      expect(find.text(AppLocalizationsEn().waitingForInternet), findsOneWidget);
    });

    testWidgets('uses warning system notice type', (tester) async {
      await pumpNotice(tester);
      final notice = tester.widget<WnSystemNotice>(find.byType(WnSystemNotice));
      expect(notice.type, WnSystemNoticeType.warning);
    });

    testWidgets('uses expanded system notice variant', (tester) async {
      await pumpNotice(tester);
      final notice = tester.widget<WnSystemNotice>(find.byType(WnSystemNotice));
      expect(notice.variant, WnSystemNoticeVariant.expanded);
    });
  });
}
