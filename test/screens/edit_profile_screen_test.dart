import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/screens/chat_list_screen.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_secure_storage.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockApi extends MockWnApi {
  FlutterMetadata? updatedMetadata;
  String? updatedPubkey;
  bool shouldThrowError = false;
  bool shouldThrowOnUpdate = false;
  Completer<void>? updateCompleter;

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required bool blockingDataSync,
    required String pubkey,
  }) async {
    if (shouldThrowError) {
      throw Exception('Failed to load profile');
    }
    return const FlutterMetadata(
      name: 'Test User',
      displayName: 'Test Display Name',
      about: 'Test About',
      nip05: 'test@example.com',
      custom: {},
    );
  }

  @override
  Future<void> crateApiAccountsUpdateAccountMetadata({
    required String pubkey,
    required FlutterMetadata metadata,
  }) async {
    if (shouldThrowOnUpdate) {
      throw Exception('Failed to update profile');
    }
    if (updateCompleter != null) {
      await updateCompleter!.future;
    }
    updatedPubkey = pubkey;
    updatedMetadata = metadata;
  }

  @override
  Future<String> crateApiAccountsUploadAccountProfilePicture({
    required String pubkey,
    required String serverUrl,
    required String filePath,
    required String imageType,
  }) async {
    return 'https://example.com/picture.jpg';
  }
}

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier([this._pubkey = testPubkeyA]);

  final String _pubkey;

  @override
  Future<String?> build() async {
    state = AsyncData(_pubkey);
    return _pubkey;
  }
}

void main() {
  late _MockApi mockApi;

  setUpAll(() {
    mockApi = _MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.shouldThrowError = false;
    mockApi.shouldThrowOnUpdate = false;
    mockApi.updatedMetadata = null;
    mockApi.updatedPubkey = null;
    mockApi.updateCompleter = null;
  });

  Future<void> pumpEditProfileScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [
        authProvider.overrideWith(() => _MockAuthNotifier()),
        secureStorageProvider.overrideWithValue(MockSecureStorage()),
      ],
    );
    Routes.pushToEditProfile(tester.element(find.byType(Scaffold)));
    await tester.pumpAndSettle();
  }

  group('EditProfileScreen', () {
    testWidgets('displays Edit profile title', (tester) async {
      await pumpEditProfileScreen(tester);
      expect(find.text('Edit profile'), findsOneWidget);
    });

    testWidgets('displays profile name field', (tester) async {
      await pumpEditProfileScreen(tester);
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('displays Nostr address field', (tester) async {
      await pumpEditProfileScreen(tester);
      expect(find.text('Nostr address (nip-05)'), findsOneWidget);
    });

    testWidgets('displays About you field', (tester) async {
      await pumpEditProfileScreen(tester);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('displays privacy notice', (tester) async {
      await pumpEditProfileScreen(tester);
      expect(find.text('Profile is public'), findsOneWidget);
    });

    testWidgets('tapping privacy notice toggle expands description', (tester) async {
      await pumpEditProfileScreen(tester);
      await tester.tap(find.byKey(const Key('callout_toggle')));
      await tester.pump();
      expect(find.textContaining('Name, photo, and bio are visible'), findsOneWidget);
    });

    testWidgets('tapping privacy notice toggle again collapses description', (tester) async {
      await pumpEditProfileScreen(tester);
      await tester.tap(find.byKey(const Key('callout_toggle')));
      await tester.pump();
      expect(find.textContaining('Name, photo, and bio are visible'), findsOneWidget);
      await tester.tap(find.byKey(const Key('callout_toggle')));
      await tester.pump();
      expect(find.textContaining('Name, photo, and bio are visible'), findsNothing);
    });

    testWidgets('tapping back icon returns to previous screen', (tester) async {
      await pumpEditProfileScreen(tester);
      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ChatListScreen), findsOneWidget);
    });

    testWidgets('loads and displays current profile data', (tester) async {
      await pumpEditProfileScreen(tester);
      await tester.pumpAndSettle();
      expect(find.text('Test Display Name'), findsOneWidget);
    });

    testWidgets('shows Save button', (tester) async {
      await pumpEditProfileScreen(tester);
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Save button is disabled when there are no changes', (tester) async {
      await pumpEditProfileScreen(tester);
      await tester.pumpAndSettle();
      final saveButton = find.widgetWithText(WnButton, 'Save');
      expect(saveButton, findsOneWidget);
      final button = tester.widget<WnButton>(saveButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('Save button is enabled when there are changes', (tester) async {
      await pumpEditProfileScreen(tester);
      await tester.pumpAndSettle();
      final displayNameField = find.text('Name');
      expect(displayNameField, findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'New Name');
      await tester.pump();
      final saveButton = find.widgetWithText(WnButton, 'Save');
      final button = tester.widget<WnButton>(saveButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('displays error message when profile loading fails', (tester) async {
      mockApi.shouldThrowError = true;
      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier()),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
      );
      Routes.pushToEditProfile(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Unable to load profile'), findsOneWidget);
    });

    testWidgets('Save button saves changes successfully', (tester) async {
      await pumpEditProfileScreen(tester);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Updated Name');
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Save'),
        50.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Profile updated successfully'), findsOneWidget);
      expect(mockApi.updatedMetadata, isNotNull);
    });

    testWidgets('Save button shows error when update fails', (tester) async {
      mockApi.shouldThrowOnUpdate = true;
      await pumpEditProfileScreen(tester);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Updated Name');
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Save'),
        50.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Unable to save profile'), findsOneWidget);
    });

    testWidgets('calls onChanged when profile name field is changed', (tester) async {
      await pumpEditProfileScreen(tester);
      await tester.pumpAndSettle();
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(3));
      await tester.enterText(textFields.at(0), 'New Profile Name');
      await tester.pump();
      final saveButton = find.widgetWithText(WnButton, 'Save');
      final button = tester.widget<WnButton>(saveButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('calls onChanged when Nostr address field is changed', (tester) async {
      await pumpEditProfileScreen(tester);
      await tester.pumpAndSettle();
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(3));
      await tester.enterText(textFields.at(1), 'new@example.com');
      await tester.pump();
      final saveButton = find.widgetWithText(WnButton, 'Save');
      final button = tester.widget<WnButton>(saveButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('calls onChanged when About you field is changed', (tester) async {
      await pumpEditProfileScreen(tester);
      await tester.pumpAndSettle();
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(3));
      await tester.enterText(textFields.at(2), 'New about text');
      await tester.pump();
      final saveButton = find.widgetWithText(WnButton, 'Save');
      final button = tester.widget<WnButton>(saveButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('hides buttons when loading', (tester) async {
      mockApi.shouldThrowError = false;
      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier()),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
      );
      Routes.pushToEditProfile(tester.element(find.byType(Scaffold)));
      await tester.pump();
      expect(find.text('Save'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('hides avatar edit button during save', (tester) async {
      mockApi.updateCompleter = Completer<void>();
      await pumpEditProfileScreen(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('avatar_edit_button')), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Updated Name');
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Save'),
        50.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.byKey(const Key('avatar_edit_button')), findsNothing);
      mockApi.updateCompleter!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('passes color derived from pubkey to avatar', (tester) async {
      await pumpEditProfileScreen(tester);

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, AvatarColor.violet);
    });

    testWidgets('different pubkey passes different avatar color', (tester) async {
      await mountTestApp(
        tester,
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(testPubkeyD)),
          secureStorageProvider.overrideWithValue(MockSecureStorage()),
        ],
      );
      Routes.pushToEditProfile(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();

      final avatar = tester.widget<WnAvatar>(find.byType(WnAvatar));
      expect(avatar.color, AvatarColor.cyan);
    });

    testWidgets('shows system notice when image picker fails', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/image_picker'),
        (MethodCall methodCall) async {
          throw PlatformException(code: 'error', message: 'Test error');
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/image_picker'),
          null,
        );
      });

      await pumpEditProfileScreen(tester);
      await tester.tap(find.byKey(const Key('avatar_edit_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Failed to pick image. Please try again.'), findsOneWidget);
    });

    testWidgets('dismisses notice after auto-hide duration', (tester) async {
      await pumpEditProfileScreen(tester);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Updated Name');
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Save'),
        50.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(WnSystemNotice), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsNothing);
    });
  });
}
