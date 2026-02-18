import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:whitenoise/providers/auth_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/src/rust/lib.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_input.dart';
import 'package:whitenoise/widgets/wn_input_text_area.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _testPubkey = testPubkeyA;

class _MockImagePickerPlatform extends ImagePickerPlatform with MockPlatformInterfaceMixin {
  XFile? imageToReturn;
  bool shouldThrow = false;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    if (shouldThrow) throw Exception('Picker error');
    return imageToReturn;
  }
}

class _MockApi extends MockWnApi {
  Group? groupToReturn;
  String? imagePathToReturn;
  Exception? getGroupError;
  Completer<void>? updateGroupDataCompleter;
  Exception? updateGroupDataError;
  final updateGroupDataCalls =
      <({Group group, String accountPubkey, FlutterGroupDataUpdate data})>[];

  @override
  Future<Group> crateApiGroupsGetGroup({
    required String accountPubkey,
    required String groupId,
  }) async {
    if (getGroupError != null) throw getGroupError!;
    return groupToReturn ??
        Group(
          mlsGroupId: testGroupId,
          nostrGroupId: testNostrGroupId,
          name: 'Test Group',
          description: 'A test description',
          adminPubkeys: [_testPubkey],
          epoch: BigInt.zero,
          state: GroupState.active,
        );
  }

  @override
  Future<String?> crateApiGroupsGetGroupImagePath({
    required String accountPubkey,
    required String groupId,
  }) async {
    return imagePathToReturn;
  }

  @override
  Future<void> crateApiGroupsGroupUpdateGroupData({
    required Group that,
    required String accountPubkey,
    required FlutterGroupDataUpdate groupData,
  }) async {
    updateGroupDataCalls.add((group: that, accountPubkey: accountPubkey, data: groupData));
    if (updateGroupDataCompleter != null) await updateGroupDataCompleter!.future;
    if (updateGroupDataError != null) throw updateGroupDataError!;
  }

  @override
  Future<UploadGroupImageResult> crateApiGroupsUploadGroupImage({
    required String accountPubkey,
    required String groupId,
    required String filePath,
    required String serverUrl,
  }) async {
    return UploadGroupImageResult(
      encryptedHash: U8Array32(Uint8List(32)),
      imageKey: U8Array32(Uint8List(32)),
      imageNonce: U8Array12(Uint8List(12)),
    );
  }

  @override
  void reset() {
    super.reset();
    groupToReturn = null;
    imagePathToReturn = null;
    getGroupError = null;
    updateGroupDataCompleter = null;
    updateGroupDataError = null;
    updateGroupDataCalls.clear();
  }
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<String?> build() async {
    state = const AsyncData(_testPubkey);
    return _testPubkey;
  }
}

final _api = _MockApi();
final _mockImagePicker = _MockImagePickerPlatform();

void main() {
  setUpAll(() {
    RustLib.initMock(api: _api);
    ImagePickerPlatform.instance = _mockImagePicker;
  });

  setUp(() {
    _api.reset();
    _mockImagePicker.imageToReturn = null;
    _mockImagePicker.shouldThrow = false;
  });

  Future<void> pumpEditGroupScreen(WidgetTester tester) async {
    await mountTestApp(
      tester,
      overrides: [authProvider.overrideWith(() => _MockAuthNotifier())],
    );
    await tester.pumpAndSettle();
    Routes.pushToEditGroup(
      tester.element(find.byType(Scaffold)),
      testGroupId,
    );
    await tester.pumpAndSettle();
  }

  group('EditGroupScreen', () {
    testWidgets('displays header with Edit Group title', (tester) async {
      await pumpEditGroupScreen(tester);

      expect(find.byType(WnSlateNavigationHeader), findsOneWidget);
      expect(find.text('Edit Group'), findsOneWidget);
    });

    testWidgets('populates name and description from loaded group', (tester) async {
      _api.groupToReturn = Group(
        mlsGroupId: testGroupId,
        nostrGroupId: testNostrGroupId,
        name: 'My Group',
        description: 'My description',
        adminPubkeys: [_testPubkey],
        epoch: BigInt.zero,
        state: GroupState.active,
      );
      await pumpEditGroupScreen(tester);

      final nameInput = tester.widget<WnInput>(find.byType(WnInput));
      expect(nameInput.controller?.text, 'My Group');

      final descInput = tester.widget<WnInputTextArea>(find.byType(WnInputTextArea));
      expect(descInput.controller?.text, 'My description');
    });

    testWidgets('navigates back when back button is pressed', (tester) async {
      await pumpEditGroupScreen(tester);

      await tester.tap(find.byKey(const Key('slate_back_button')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Group'), findsNothing);
    });

    testWidgets('cancel button discards changes and navigates back', (tester) async {
      await pumpEditGroupScreen(tester);

      await tester.enterText(find.byType(WnInput).last, 'Changed Name');
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Group'), findsNothing);
    });

    testWidgets('save button is disabled when no changes', (tester) async {
      await pumpEditGroupScreen(tester);

      final saveButton = tester.widget<WnButton>(
        find.widgetWithText(WnButton, 'Save'),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('save button is enabled after making changes', (tester) async {
      await pumpEditGroupScreen(tester);

      await tester.enterText(find.byType(WnInput).last, 'New Name');
      await tester.pump();

      final saveButton = tester.widget<WnButton>(
        find.widgetWithText(WnButton, 'Save'),
      );
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('shows success notice after saving', (tester) async {
      await pumpEditGroupScreen(tester);

      await tester.enterText(find.byType(WnInput).last, 'New Name');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);
      expect(find.text('Group updated successfully'), findsOneWidget);
    });

    testWidgets('shows error state when group fails to load', (tester) async {
      _api.getGroupError = Exception('Network error');
      await pumpEditGroupScreen(tester);

      expect(find.text('Unable to load group. Please try again.'), findsOneWidget);
    });

    testWidgets('shows save error when update fails', (tester) async {
      _api.updateGroupDataError = Exception('Save failed');
      await pumpEditGroupScreen(tester);

      await tester.enterText(find.byType(WnInput).last, 'New Name');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to save group. Please try again.'), findsOneWidget);
    });

    testWidgets('shows image picker error as system notice', (tester) async {
      _mockImagePicker.shouldThrow = true;
      await pumpEditGroupScreen(tester);

      await tester.tap(find.byKey(const Key('avatar_edit_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);
    });

    testWidgets('system notice auto-dismisses after timeout', (tester) async {
      await pumpEditGroupScreen(tester);

      await tester.enterText(find.byType(WnInput).last, 'New Name');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.byType(WnSystemNotice), findsNothing);
    });

    testWidgets('shows loading state during save', (tester) async {
      _api.updateGroupDataCompleter = Completer();
      await pumpEditGroupScreen(tester);

      await tester.enterText(find.byType(WnInput).last, 'New Name');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump();

      final saveButtons = tester.widgetList<WnButton>(find.byType(WnButton));
      final saveButton = saveButtons.firstWhere((b) => b.text == 'Save');
      expect(saveButton.loading, isTrue);

      _api.updateGroupDataCompleter!.complete();
      await tester.pumpAndSettle();
    });
  });
}
