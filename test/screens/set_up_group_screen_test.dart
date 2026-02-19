import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/src/rust/lib.dart';
import 'package:whitenoise/widgets/wn_avatar.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_input.dart';
import 'package:whitenoise/widgets/wn_input_text_area.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _MockImagePickerPlatform extends ImagePickerPlatform with MockPlatformInterfaceMixin {
  XFile? imageToReturn;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return imageToReturn;
  }
}

User _userFactory(String pubkey, {String? displayName}) => User(
  pubkey: pubkey,
  metadata: FlutterMetadata(displayName: displayName, custom: const {}),
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

class _MockApi extends MockWnApi {
  bool createGroupCalled = false;
  bool uploadImageCalled = false;
  final Map<String, KeyPackageStatus> userHasKeyPackageMap = {};
  bool shouldDelayCreateGroup = false;
  bool shouldDelayUploadImage = false;
  bool shouldDelayUserHasKeyPackage = false;
  bool shouldThrowOnCreateGroup = false;

  @override
  Future<Group> crateApiGroupsCreateGroup({
    required String creatorPubkey,
    required List<String> memberPubkeys,
    required List<String> adminPubkeys,
    required String groupName,
    required String groupDescription,
    required GroupType groupType,
  }) async {
    createGroupCalled = true;
    if (shouldThrowOnCreateGroup) {
      throw Exception('Failed to create group');
    }
    if (shouldDelayCreateGroup) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return Group(
      mlsGroupId: testGroupId,
      nostrGroupId: testNostrGroupId,
      name: groupName,
      description: groupDescription,
      adminPubkeys: adminPubkeys,
      epoch: BigInt.zero,
      state: GroupState.active,
    );
  }

  @override
  Future<KeyPackageStatus> crateApiUsersUserHasKeyPackage({
    required String pubkey,
    required bool blockingDataSync,
  }) async {
    if (shouldDelayUserHasKeyPackage) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return userHasKeyPackageMap[pubkey] ?? KeyPackageStatus.notFound;
  }

  @override
  Future<String> crateApiUtilsGetDefaultBlossomServerUrl() {
    return Future.value('https://blossom.example.com');
  }

  @override
  Future<UploadGroupImageResult> crateApiGroupsUploadGroupImage({
    required String accountPubkey,
    required String groupId,
    required String filePath,
    required String serverUrl,
  }) async {
    uploadImageCalled = true;
    if (shouldDelayUploadImage) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return UploadGroupImageResult(
      imageKey: U8Array32(Uint8List(32)),
      encryptedHash: U8Array32(Uint8List(32)),
      imageNonce: U8Array12(Uint8List(12)),
    );
  }

  @override
  Future<void> crateApiGroupsGroupUpdateGroupData({
    required Group that,
    required String accountPubkey,
    required FlutterGroupDataUpdate groupData,
  }) {
    return Future.value();
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(testPubkeyA);
    return testPubkeyA;
  }
}

final _api = _MockApi();
late _MockImagePickerPlatform _mockImagePicker;
late ImagePickerPlatform _originalImagePickerPlatform;

void main() {
  setUpAll(() {
    RustLib.initMock(api: _api);
    _originalImagePickerPlatform = ImagePickerPlatform.instance;
  });

  setUp(() {
    _api.reset();
    _api.createGroupCalled = false;
    _api.uploadImageCalled = false;
    _api.userHasKeyPackageMap.clear();
    _api.shouldDelayCreateGroup = false;
    _api.shouldDelayUploadImage = false;
    _api.shouldDelayUserHasKeyPackage = false;
    _api.shouldThrowOnCreateGroup = false;
    _mockImagePicker = _MockImagePickerPlatform();
    ImagePickerPlatform.instance = _mockImagePicker;
  });

  tearDown(() {
    ImagePickerPlatform.instance = _originalImagePickerPlatform;
  });

  Future<void> pumpSetUpGroupScreen(
    WidgetTester tester,
    List<User> selectedUsers,
  ) async {
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    Routes.pushToSetUpGroup(
      tester.element(find.byType(Scaffold)),
      selectedUsers,
    );
    await tester.pumpAndSettle();
  }

  group('SetUpGroupScreen', () {
    testWidgets('displays slate container', (tester) async {
      final users = [_userFactory(testPubkeyB, displayName: 'Bob')];
      await pumpSetUpGroupScreen(tester, users);
      expect(find.byType(WnSlate), findsOneWidget);
    });

    testWidgets('displays screen header with title', (tester) async {
      final users = [_userFactory(testPubkeyB, displayName: 'Bob')];
      await pumpSetUpGroupScreen(tester, users);
      expect(find.byType(WnSlateNavigationHeader), findsOneWidget);
      expect(find.text('Set up group'), findsOneWidget);
    });

    testWidgets('displays group name input', (tester) async {
      final users = [_userFactory(testPubkeyB, displayName: 'Bob')];
      await pumpSetUpGroupScreen(tester, users);
      expect(find.text('Group Name'), findsOneWidget);
      expect(find.widgetWithText(WnInput, 'Enter group name'), findsOneWidget);
    });

    testWidgets('displays group description input', (tester) async {
      final users = [_userFactory(testPubkeyB, displayName: 'Bob')];
      await pumpSetUpGroupScreen(tester, users);
      expect(find.text('Description'), findsOneWidget);
      expect(
        find.widgetWithText(WnInputTextArea, 'What is this group for?'),
        findsOneWidget,
      );
    });

    testWidgets('displays avatar', (tester) async {
      final users = [_userFactory(testPubkeyB, displayName: 'Bob')];
      await pumpSetUpGroupScreen(tester, users);
      expect(find.byType(WnAvatar), findsWidgets);
    });

    testWidgets('displays create group button in footer', (tester) async {
      final users = [_userFactory(testPubkeyB, displayName: 'Bob')];
      await pumpSetUpGroupScreen(tester, users);
      expect(find.text('Create group'), findsOneWidget);
    });

    testWidgets('create button is disabled when group name is empty', (tester) async {
      _api.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;
      final users = [_userFactory(testPubkeyB, displayName: 'Bob')];

      await pumpSetUpGroupScreen(tester, users);

      final button = tester.widget<WnButton>(find.widgetWithText(WnButton, 'Create group'));
      expect(button.onPressed, isNull);
    });

    testWidgets('filters users by key package on init', (tester) async {
      _api.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;
      _api.userHasKeyPackageMap[testPubkeyC] = KeyPackageStatus.notFound;

      final users = [
        _userFactory(testPubkeyB, displayName: 'Bob'),
        _userFactory(testPubkeyC, displayName: 'Charlie'),
      ];

      await pumpSetUpGroupScreen(tester, users);

      expect(find.text('Inviting member:'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('displays users without key packages message', (tester) async {
      _api.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;
      _api.userHasKeyPackageMap[testPubkeyC] = KeyPackageStatus.notFound;

      final users = [
        _userFactory(testPubkeyB, displayName: 'Bob'),
        _userFactory(testPubkeyC, displayName: 'Charlie'),
      ];

      await pumpSetUpGroupScreen(tester, users);

      expect(find.textContaining('This user is not on White Noise:'), findsOneWidget);
    });

    testWidgets('entering group name enables create button', (tester) async {
      _api.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;
      final users = [_userFactory(testPubkeyB, displayName: 'Bob')];

      await pumpSetUpGroupScreen(tester, users);

      await tester.enterText(find.widgetWithText(WnInput, 'Enter group name'), 'My Group');
      await tester.pumpAndSettle();

      final button = tester.widget<WnButton>(find.widgetWithText(WnButton, 'Create group'));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('displays member list with avatars', (tester) async {
      _api.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;
      _api.userHasKeyPackageMap[testPubkeyC] = KeyPackageStatus.valid;

      final users = [
        _userFactory(testPubkeyB, displayName: 'Bob'),
        _userFactory(testPubkeyC, displayName: 'Charlie'),
      ];

      await pumpSetUpGroupScreen(tester, users);

      expect(find.text('Inviting members:'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    });

    testWidgets('displays users without key packages with strikethrough', (tester) async {
      _api.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;
      _api.userHasKeyPackageMap[testPubkeyC] = KeyPackageStatus.notFound;

      final users = [
        _userFactory(testPubkeyB, displayName: 'Bob'),
        _userFactory(testPubkeyC, displayName: 'Charlie'),
      ];

      await pumpSetUpGroupScreen(tester, users);

      expect(find.text('Charlie'), findsOneWidget);
      expect(find.textContaining('This user is not on White Noise:'), findsOneWidget);
    });

    testWidgets('displays user without display name using pubkey', (tester) async {
      _api.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;

      final users = [
        User(
          pubkey: testPubkeyB,
          metadata: const FlutterMetadata(custom: {}),
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];

      await pumpSetUpGroupScreen(tester, users);

      expect(find.text('Inviting member:'), findsOneWidget);
    });

    testWidgets('displays user without display name in excluded list', (tester) async {
      _api.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.notFound;

      final users = [
        User(
          pubkey: testPubkeyB,
          metadata: const FlutterMetadata(custom: {}),
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ];

      await pumpSetUpGroupScreen(tester, users);

      expect(find.textContaining('This user is not on White Noise:'), findsOneWidget);
    });

    testWidgets('tapping create button calls createGroup', (tester) async {
      _api.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;
      final users = [_userFactory(testPubkeyB, displayName: 'Bob')];

      await pumpSetUpGroupScreen(tester, users);

      await tester.enterText(find.widgetWithText(WnInput, 'Enter group name'), 'My Group');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(WnButton, 'Create group'));
      await tester.pumpAndSettle();

      expect(_api.createGroupCalled, isTrue);
    });

    testWidgets('tapping edit icon triggers image picker', (tester) async {
      _mockImagePicker.imageToReturn = XFile('/fake/path/image.jpg');
      final users = [_userFactory(testPubkeyB, displayName: 'Bob')];
      await pumpSetUpGroupScreen(tester, users);

      final editIcon = find.byKey(const Key('edit_group_image_icon'));
      expect(editIcon, findsOneWidget);

      await tester.tap(editIcon);
      await tester.pumpAndSettle();
    });

    testWidgets('shows error notice when createGroup fails', (tester) async {
      _api.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;
      _api.shouldThrowOnCreateGroup = true;
      final users = [_userFactory(testPubkeyB, displayName: 'Bob')];

      await pumpSetUpGroupScreen(tester, users);

      await tester.enterText(find.widgetWithText(WnInput, 'Enter group name'), 'My Group');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(WnButton, 'Create group'));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Failed to create group'), findsOneWidget);
    });

    testWidgets('tapping back button navigates back', (tester) async {
      final users = [_userFactory(testPubkeyB, displayName: 'Bob')];
      await pumpSetUpGroupScreen(tester, users);

      expect(find.byType(WnSlateNavigationHeader), findsOneWidget);

      final backButton = find.byKey(const Key('slate_back_button'));
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(WnSlateNavigationHeader), findsNothing);
    });
  });
}
