import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/l10n/generated/app_localizations.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/screens/user_profile_shade.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_user_profile_card.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  StreamController<UserStreamItem>? controller;

  @override
  void reset() {
    super.reset();
    controller?.close();
    controller = null;
  }

  @override
  Stream<UserStreamItem> crateApiUsersSubscribeToUser({required String pubkey}) {
    controller ??= StreamController<UserStreamItem>.broadcast();
    final now = DateTime.now();
    controller!.add(
      UserStreamItem.update(
        update: UserUpdate(
          trigger: UserUpdateTrigger.metadataChanged,
          user: User(
            pubkey: pubkey,
            metadata: const FlutterMetadata(displayName: 'Alice', name: 'alice', custom: {}),
            createdAt: now,
            updatedAt: now,
          ),
        ),
      ),
    );
    return controller!.stream;
  }
}

void main() {
  final api = _MockApi();
  setUpAll(() => RustLib.initMock(api: api));
  setUp(api.reset);

  Future<void> openShade(
    WidgetTester tester, {
    required String userPubkey,
    String? authenticatedAs,
  }) async {
    await mountWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => UserProfileShade.show(context, userPubkey: userPubkey),
          child: const Text('open'),
        ),
      ),
      tester,
      overrides: [
        if (authenticatedAs != null)
          authProvider.overrideWith(() => _StubAuthNotifier(authenticatedAs)),
      ],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows user profile card with metadata', (tester) async {
    await openShade(tester, userPubkey: testPubkeyA);
    expect(find.byType(UserProfileShade), findsOneWidget);
    expect(find.byType(WnUserProfileCard), findsOneWidget);
  });

  testWidgets('shows start-chat button when viewing another user', (tester) async {
    await openShade(tester, userPubkey: testPubkeyA, authenticatedAs: testPubkeyB);
    expect(find.byKey(const Key('user_profile_shade_start_chat')), findsOneWidget);
  });

  testWidgets('hides start-chat button when viewing self', (tester) async {
    await openShade(tester, userPubkey: testPubkeyA, authenticatedAs: testPubkeyA);
    expect(find.byKey(const Key('user_profile_shade_start_chat')), findsNothing);
  });

  testWidgets('public-key copy callback shows snackbar', (tester) async {
    await openShade(tester, userPubkey: testPubkeyA, authenticatedAs: testPubkeyB);
    final card = tester.widget<WnUserProfileCard>(find.byType(WnUserProfileCard));
    card.onPublicKeyCopied!();
    await tester.pump();
    expect(find.byType(SnackBar), findsWidgets);
  });

  testWidgets('public-key copy error callback shows snackbar', (tester) async {
    await openShade(tester, userPubkey: testPubkeyA, authenticatedAs: testPubkeyB);
    final card = tester.widget<WnUserProfileCard>(find.byType(WnUserProfileCard));
    card.onPublicKeyCopyError!();
    await tester.pump();
    expect(find.byType(SnackBar), findsWidgets);
  });

  testWidgets('header onNavigate dismisses the shade', (tester) async {
    await openShade(tester, userPubkey: testPubkeyA, authenticatedAs: testPubkeyB);
    final header = tester.widget<WnSlateNavigationHeader>(find.byType(WnSlateNavigationHeader));
    header.onNavigate!();
    await tester.pumpAndSettle();
    expect(find.byType(UserProfileShade), findsNothing);
  });

  testWidgets('start-chat button pops the shade then routes to start-chat', (tester) async {
    var startChatVisited = false;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UserProfileShade.show(context, userPubkey: testPubkeyA),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/start-chat/:userPubkey',
          name: 'startChat',
          builder: (_, _) {
            startChatVisited = true;
            return const Scaffold(body: Text('start chat'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(() => _StubAuthNotifier(testPubkeyB))],
        child: ScreenUtilInit(
          designSize: const Size(420, 912),
          builder: (_, _) => MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('user_profile_shade_start_chat')));
    await tester.pumpAndSettle();

    expect(find.byType(UserProfileShade), findsNothing);
    expect(startChatVisited, isTrue);
  });
}

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._pubkey);
  final String _pubkey;

  @override
  Future<String?> build() async => _pubkey;
}
