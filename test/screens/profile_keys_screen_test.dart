import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_clipboard_guard.dart' show cancelClipboardGuardTimer;
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_copyable_field.dart' show WnCopyableField;
import 'package:whitenoise/widgets/wn_icon.dart';

import '../mocks/mock_clipboard.dart' show clearClipboardMock, mockClipboard;
import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  AccountType _accountType = AccountType.local;
  bool _exportNsecThrows = false;

  void setAccountType(AccountType type) {
    _accountType = type;
  }

  void setExportNsecThrows(bool value) {
    _exportNsecThrows = value;
  }

  @override
  Future<String> crateApiAccountsExportAccountNsec({required String pubkey}) async {
    if (_exportNsecThrows) {
      throw Exception('Export error');
    }
    return 'nsec1test${pubkey.substring(0, 10)}';
  }

  @override
  Future<Account> crateApiAccountsGetAccount({required String pubkey}) async {
    return Account(
      pubkey: pubkey,
      accountType: _accountType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}

void main() {
  late _MockApi mockApi;

  setUpAll(() {
    mockApi = _MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.setAccountType(AccountType.local);
    mockApi.setExportNsecThrows(false);
  });

  tearDown(() {
    cancelClipboardGuardTimer();
  });

  Future<void> pumpProfileKeysScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );
    Routes.pushToProfileKeys(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('ProfileKeysScreen', () {
    testWidgets('displays Profile keys title', (tester) async {
      await pumpProfileKeysScreen(tester);
      expect(find.text('Profile keys'), findsOneWidget);
    });

    testWidgets('displays public key label', (tester) async {
      await pumpProfileKeysScreen(tester);
      expect(find.text('Public key'), findsOneWidget);
    });

    testWidgets('displays private key label', (tester) async {
      await pumpProfileKeysScreen(tester);
      expect(find.text('Private Key'), findsOneWidget);
    });

    testWidgets('displays public key description', (tester) async {
      await pumpProfileKeysScreen(tester);
      expect(
        find.text(
          'Your public key is your identifier on Nostr. Share it so others can find, recognize, and connect with you.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays private key description', (tester) async {
      await pumpProfileKeysScreen(tester);
      expect(
        find.text(
          'Your private key works like a secret password that grants access to your Nostr identity.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays warning callout title', (tester) async {
      await pumpProfileKeysScreen(tester);
      expect(find.text('Keep your private key safe!'), findsOneWidget);
    });

    testWidgets('warning callout description is hidden by default', (tester) async {
      await pumpProfileKeysScreen(tester);
      expect(
        find.text(
          "Don't share your private key publicly, and use it only to log in to other Nostr apps.",
        ),
        findsNothing,
      );
    });

    testWidgets('tapping warning callout toggle shows description', (tester) async {
      await pumpProfileKeysScreen(tester);
      await tester.tap(find.byKey(const Key('callout_toggle')));
      await tester.pump();
      expect(
        find.text(
          "Don't share your private key publicly, and use it only to log in to other Nostr apps.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping warning callout toggle twice hides description again', (tester) async {
      await pumpProfileKeysScreen(tester);
      await tester.tap(find.byKey(const Key('callout_toggle')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('callout_toggle')));
      await tester.pump();
      expect(
        find.text(
          "Don't share your private key publicly, and use it only to log in to other Nostr apps.",
        ),
        findsNothing,
      );
    });

    testWidgets('tapping back icon returns to previous screen', (tester) async {
      await pumpProfileKeysScreen(tester);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });

    testWidgets('loads and displays public key field', (tester) async {
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();
      final publicKeyFields = find.byType(WnCopyableField);
      expect(publicKeyFields, findsNWidgets(2));
    });

    testWidgets('loads and displays private key field', (tester) async {
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();
      final privateKeyFields = find.byType(WnCopyableField);
      expect(privateKeyFields, findsNWidgets(2));
    });

    testWidgets('tapping copy button on public key copies to clipboard', (tester) async {
      final getClipboard = mockClipboard();
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();
      final copyButtons = find.byKey(const Key('copy_button'));
      expect(copyButtons, findsNWidgets(2));
      await tester.tap(copyButtons.first);
      await tester.pump();
      expect(getClipboard(), startsWith('npub1'));
    });

    testWidgets('tapping copy button on private key copies to clipboard', (tester) async {
      final getClipboard = mockClipboard();
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();
      final copyButtons = find.byKey(const Key('copy_button'));
      expect(copyButtons, findsNWidgets(2));
      await tester.tap(copyButtons.last);
      await tester.pump();
      expect(getClipboard(), startsWith('nsec1'));
      cancelClipboardGuardTimer();
    });

    testWidgets('shows success message when copying public key', (tester) async {
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();
      final copyButtons = find.byKey(const Key('copy_button'));
      await tester.tap(copyButtons.first);
      await tester.pump();
      expect(find.text('Public key copied to clipboard'), findsOneWidget);
    });

    testWidgets('shows success message when copying private key', (tester) async {
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();
      final copyButtons = find.byKey(const Key('copy_button'));
      await tester.tap(copyButtons.last);
      await tester.pump();
      expect(find.text('Private key copied to clipboard'), findsOneWidget);
      cancelClipboardGuardTimer();
    });

    testWidgets('private key field remains after copying', (tester) async {
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();
      final privateKeyFields = find.byType(WnCopyableField);
      expect(privateKeyFields, findsNWidgets(2));

      final copyButtons = find.byKey(const Key('copy_button'));
      await tester.tap(copyButtons.last);
      await tester.pump();

      expect(find.byType(WnCopyableField), findsNWidgets(2));
      cancelClipboardGuardTimer();
    });

    testWidgets('tapping visibility toggle shows/hides private key', (tester) async {
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();
      final visibilityToggle = find.byKey(const Key('visibility_toggle'));
      expect(visibilityToggle, findsOneWidget);

      final visibilityIcon = find.descendant(
        of: visibilityToggle,
        matching: find.byType(WnIcon),
      );
      expect(tester.widget<WnIcon>(visibilityIcon).icon, WnIcons.view);

      await tester.tap(visibilityToggle);
      await tester.pump();

      expect(tester.widget<WnIcon>(visibilityIcon).icon, WnIcons.viewOff);

      await tester.tap(visibilityToggle);
      await tester.pump();

      expect(tester.widget<WnIcon>(visibilityIcon).icon, WnIcons.view);
    });

    testWidgets('hides private key section when using external signer', (tester) async {
      mockApi.setAccountType(AccountType.external_);
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Private Key'), findsNothing);
      expect(
        find.text(
          'Your private key works like a secret password that grants access to your Nostr identity.',
        ),
        findsNothing,
      );
      expect(find.text('Keep your private key safe!'), findsNothing);
    });

    testWidgets('shows only public key field when using external signer', (tester) async {
      mockApi.setAccountType(AccountType.external_);
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();

      final copyableFields = find.byType(WnCopyableField);
      expect(copyableFields, findsOneWidget);
      expect(find.text('Public key'), findsOneWidget);
    });

    testWidgets('displays external signer callout title when nsec storage is external', (
      tester,
    ) async {
      mockApi.setAccountType(AccountType.external_);
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Private key is stored in external signer'), findsOneWidget);
    });

    testWidgets('displays external signer callout description when nsec storage is external', (
      tester,
    ) async {
      mockApi.setAccountType(AccountType.external_);
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Your private key isn\'t available in White Noise. Open your signer to view or manage it.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows error notice when private key fails to load', (tester) async {
      mockApi.setExportNsecThrows(true);
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Could not load private key. Please try again.'), findsOneWidget);
    });

    testWidgets('clears clipboard 60 seconds after copying private key', (tester) async {
      final getClipboard = mockClipboard();
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();

      final copyButtons = find.byKey(const Key('copy_button'));
      await tester.tap(copyButtons.last);
      await tester.pump();
      expect(getClipboard(), startsWith('nsec1'));

      await tester.pump(const Duration(seconds: 59));
      expect(getClipboard(), startsWith('nsec1'));

      await tester.pump(const Duration(seconds: 1));
      expect(getClipboard(), '');
      clearClipboardMock();
    });

    testWidgets('success notice auto-dismisses after timeout', (tester) async {
      await pumpProfileKeysScreen(tester);
      await tester.pumpAndSettle();

      final copyButtons = find.byKey(const Key('copy_button'));
      await tester.tap(copyButtons.first);
      await tester.pump();

      expect(find.text('Public key copied to clipboard'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Public key copied to clipboard'), findsNothing);
    });
  });
}
