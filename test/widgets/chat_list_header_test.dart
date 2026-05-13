import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rust_lib_whitenoise/src/rust/api/metadata.dart';
import 'package:rust_lib_whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/settings_screen.dart';
import 'package:whitenoise/screens/user_search_screen.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async => const FlutterMetadata(custom: {});
}

class _MockAuthNotifier extends AuthNotifier {
  final String _pubkey;
  _MockAuthNotifier([this._pubkey = testPubkeyA]);

  @override
  Future<String?> build() async {
    state = AsyncData(_pubkey);
    return _pubkey;
  }
}

void main() {
  setUpAll(() => RustLib.initMock(api: _MockApi()));

  Future<void> pumpChatListScreen(
    WidgetTester tester, {
    _MockAuthNotifier? authNotifier,
  }) async {
    setUpTestView(tester);
    final notifier = authNotifier ?? _MockAuthNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(() => notifier)],
        child: ScreenUtilInit(
          designSize: testDesignSize,
          builder: (_, _) => Consumer(
            builder: (context, ref, _) {
              return MaterialApp.router(
                routerConfig: Routes.build(ref),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
              );
            },
          ),
        ),
      ),
    );
    Routes.goToChatList(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('ChatListHeader', () {
    testWidgets('displays avatar', (tester) async {
      await pumpChatListScreen(tester);
      expect(find.byKey(const Key('avatar_button')), findsOneWidget);
    });

    testWidgets('displays chat icon', (tester) async {
      await pumpChatListScreen(tester);
      expect(find.byKey(const Key('chat_add_button')), findsOneWidget);
    });

    testWidgets('tapping avatar navigates to settings', (tester) async {
      await pumpChatListScreen(tester);
      await tester.tap(find.byKey(const Key('avatar_button')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('tapping chat add icon navigates to user search screen', (tester) async {
      await pumpChatListScreen(tester);
      await tester.tap(find.byKey(const Key('chat_add_button')));
      await tester.pumpAndSettle();
      expect(find.byType(UserSearchScreen), findsOneWidget);
    });

    testWidgets('passes color derived from pubkey to avatar', (tester) async {
      await pumpChatListScreen(tester);

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, AvatarColor.violet);
    });

    testWidgets('different pubkey passes different avatar color', (tester) async {
      await pumpChatListScreen(
        tester,
        authNotifier: _MockAuthNotifier(testPubkeyD),
      );

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, AvatarColor.cyan);
    });
  });
}
