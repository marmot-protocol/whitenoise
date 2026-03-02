import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_edit_group.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/src/rust/lib.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

Group _testGroup({
  String? name,
  String? description,
}) {
  return Group(
    mlsGroupId: testGroupId,
    nostrGroupId: testNostrGroupId,
    name: name ?? 'Test Group',
    description: description ?? 'A test group',
    adminPubkeys: [testPubkeyA],
    epoch: BigInt.zero,
    state: GroupState.active,
  );
}

class _MockApi extends MockWnApi {
  Completer<Group>? getGroupCompleter;
  Completer<void>? updateGroupDataCompleter;
  Completer<UploadGroupImageResult>? uploadImageCompleter;
  Exception? getGroupError;
  Exception? updateGroupDataError;
  Exception? uploadImageError;
  Group? groupToReturn;
  String? imagePathToReturn;
  final getGroupCalls = <({String accountPubkey, String groupId})>[];
  final updateGroupDataCalls =
      <({Group group, String accountPubkey, FlutterGroupDataUpdate data})>[];
  final uploadImageCalls =
      <({String accountPubkey, String groupId, String filePath, String serverUrl})>[];

  @override
  Future<Group> crateApiGroupsGetGroup({
    required String accountPubkey,
    required String groupId,
  }) async {
    getGroupCalls.add((accountPubkey: accountPubkey, groupId: groupId));
    if (getGroupError != null) throw getGroupError!;
    if (getGroupCompleter != null) return getGroupCompleter!.future;
    return groupToReturn ?? _testGroup();
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
    uploadImageCalls.add((
      accountPubkey: accountPubkey,
      groupId: groupId,
      filePath: filePath,
      serverUrl: serverUrl,
    ));
    if (uploadImageCompleter != null) return uploadImageCompleter!.future;
    if (uploadImageError != null) throw uploadImageError!;
    return UploadGroupImageResult(
      encryptedHash: U8Array32(Uint8List(32)),
      imageKey: U8Array32(Uint8List(32)),
      imageNonce: U8Array12(Uint8List(12)),
    );
  }

  @override
  void reset() {
    super.reset();
    getGroupCompleter = null;
    updateGroupDataCompleter = null;
    uploadImageCompleter = null;
    getGroupError = null;
    updateGroupDataError = null;
    uploadImageError = null;
    groupToReturn = null;
    imagePathToReturn = null;
    getGroupCalls.clear();
    updateGroupDataCalls.clear();
    uploadImageCalls.clear();
  }
}

final _api = _MockApi();

typedef _HookResult = ({
  EditGroupState state,
  TextEditingController nameController,
  TextEditingController descriptionController,
  Future<void> Function() loadGroup,
  void Function(String imagePath) onImageSelected,
  Future<bool> Function() saveGroup,
  void Function() discardChanges,
});

void main() {
  late _HookResult Function() getResult;

  setUpAll(() => RustLib.initMock(api: _api));
  setUp(() => _api.reset());

  Future<void> pump(WidgetTester tester) async {
    getResult = await mountHook(
      tester,
      () => useEditGroup(
        accountPubkey: testPubkeyA,
        groupId: testGroupId,
      ),
    );
  }

  Future<void> pumpAndLoad(WidgetTester tester) async {
    await pump(tester);
    await getResult().loadGroup();
    await tester.pumpAndSettle();
  }

  group('useEditGroup', () {
    group('loading state', () {
      testWidgets('loadingState is idle initially', (tester) async {
        await pump(tester);

        expect(getResult().state.loadingState, EditGroupLoadingState.idle);
      });

      testWidgets('loadingState becomes idle after fetch completes', (tester) async {
        await pumpAndLoad(tester);

        expect(getResult().state.loadingState, EditGroupLoadingState.idle);
      });
    });

    group('loadGroup', () {
      testWidgets('calls API with correct parameters', (tester) async {
        await pumpAndLoad(tester);

        expect(_api.getGroupCalls.length, 1);
        expect(_api.getGroupCalls[0].accountPubkey, testPubkeyA);
        expect(_api.getGroupCalls[0].groupId, testGroupId);
      });

      testWidgets('populates text controllers with group data', (tester) async {
        _api.groupToReturn = _testGroup(name: 'My Group', description: 'Group description');
        await pumpAndLoad(tester);

        expect(getResult().nameController.text, 'My Group');
        expect(getResult().descriptionController.text, 'Group description');
      });

      testWidgets('populates state with group data', (tester) async {
        _api.groupToReturn = _testGroup(name: 'My Group', description: 'Group description');
        await pumpAndLoad(tester);

        expect(getResult().state.name, 'My Group');
        expect(getResult().state.description, 'Group description');
      });

      testWidgets('loads existing group image path', (tester) async {
        _api.imagePathToReturn = '/path/to/group/image.jpg';
        await pumpAndLoad(tester);

        expect(getResult().state.currentImagePath, '/path/to/group/image.jpg');
      });

      testWidgets('sets error when fetch fails', (tester) async {
        _api.getGroupError = Exception('Network error');
        await pumpAndLoad(tester);

        expect(getResult().state.loadingState, EditGroupLoadingState.idle);
        expect(getResult().state.error, isNotNull);
      });
    });

    group('onImageSelected', () {
      testWidgets('sets selectedImagePath in state', (tester) async {
        await pumpAndLoad(tester);

        expect(getResult().state.selectedImagePath, isNull);

        getResult().onImageSelected('/new/image.jpg');
        await tester.pump();

        expect(getResult().state.selectedImagePath, '/new/image.jpg');
      });

      testWidgets('clears error', (tester) async {
        _api.updateGroupDataError = Exception('Save failed');
        await pumpAndLoad(tester);

        getResult().nameController.text = 'Changed';
        await tester.pump();
        await getResult().saveGroup();
        await tester.pump();
        expect(getResult().state.error, isNotNull);

        getResult().onImageSelected('/new/image.jpg');
        await tester.pump();

        expect(getResult().state.error, isNull);
      });
    });

    group('hasUnsavedChanges', () {
      testWidgets('is false initially after load', (tester) async {
        await pumpAndLoad(tester);

        expect(getResult().state.hasUnsavedChanges, isFalse);
      });

      testWidgets('is true when image is selected', (tester) async {
        await pumpAndLoad(tester);

        getResult().onImageSelected('/new/image.jpg');
        await tester.pump();

        expect(getResult().state.hasUnsavedChanges, isTrue);
      });

      testWidgets('is true when name is changed', (tester) async {
        _api.groupToReturn = _testGroup(name: 'Original');
        await pumpAndLoad(tester);

        getResult().nameController.text = 'Changed';
        await tester.pump();

        expect(getResult().state.hasUnsavedChanges, isTrue);
      });

      testWidgets('is true when description is changed', (tester) async {
        _api.groupToReturn = _testGroup(description: 'Original');
        await pumpAndLoad(tester);

        getResult().descriptionController.text = 'Changed';
        await tester.pump();

        expect(getResult().state.hasUnsavedChanges, isTrue);
      });
    });

    group('pictureUrl', () {
      testWidgets('returns currentImagePath when no image selected', (tester) async {
        _api.imagePathToReturn = '/existing/image.jpg';
        await pumpAndLoad(tester);

        expect(getResult().state.pictureUrl, '/existing/image.jpg');
      });

      testWidgets('returns selectedImagePath when image selected', (tester) async {
        _api.imagePathToReturn = '/existing/image.jpg';
        await pumpAndLoad(tester);

        getResult().onImageSelected('/new/image.jpg');
        await tester.pump();

        expect(getResult().state.pictureUrl, '/new/image.jpg');
      });
    });

    group('saveGroup', () {
      testWidgets('calls updateGroupData with correct parameters', (tester) async {
        _api.groupToReturn = _testGroup(name: 'Old Name', description: 'Old Desc');
        await pumpAndLoad(tester);

        getResult().nameController.text = 'New Name';
        getResult().descriptionController.text = 'New Description';

        final result = await getResult().saveGroup();
        await tester.pump();

        expect(result, isTrue);
        expect(_api.updateGroupDataCalls.length, 1);
        expect(_api.updateGroupDataCalls[0].accountPubkey, testPubkeyA);
        expect(_api.updateGroupDataCalls[0].data.name, 'New Name');
        expect(_api.updateGroupDataCalls[0].data.description, 'New Description');
      });

      testWidgets('does not upload image when no image selected', (tester) async {
        _api.groupToReturn = _testGroup(name: 'Old');
        await pumpAndLoad(tester);

        getResult().nameController.text = 'New';
        await getResult().saveGroup();
        await tester.pump();

        expect(_api.uploadImageCalls, isEmpty);
      });

      testWidgets('uploads image when image is selected', (tester) async {
        await pumpAndLoad(tester);

        getResult().onImageSelected('/new/group/photo.jpg');
        await tester.pump();

        await getResult().saveGroup();
        await tester.pump();

        expect(_api.uploadImageCalls.length, 1);
        expect(_api.uploadImageCalls[0].accountPubkey, testPubkeyA);
        expect(_api.uploadImageCalls[0].groupId, testGroupId);
        expect(_api.uploadImageCalls[0].filePath, '/new/group/photo.jpg');
        expect(_api.uploadImageCalls[0].serverUrl, 'https://blossom.example.com');
      });

      testWidgets('clears selectedImagePath after successful save', (tester) async {
        await pumpAndLoad(tester);

        getResult().onImageSelected('/new/image.jpg');
        await tester.pump();
        expect(getResult().state.selectedImagePath, '/new/image.jpg');

        await getResult().saveGroup();
        await tester.pump();

        expect(getResult().state.selectedImagePath, isNull);
      });

      testWidgets('loadingState is saving during save', (tester) async {
        _api.updateGroupDataCompleter = Completer();
        _api.groupToReturn = _testGroup(name: 'Old');
        await pumpAndLoad(tester);

        getResult().nameController.text = 'New';
        final future = getResult().saveGroup();
        await tester.pump();

        expect(getResult().state.loadingState, EditGroupLoadingState.saving);

        _api.updateGroupDataCompleter!.complete();
        await future;
        await tester.pumpAndSettle();

        expect(getResult().state.loadingState, EditGroupLoadingState.idle);
      });

      testWidgets('returns false and sets error on failure', (tester) async {
        _api.updateGroupDataError = Exception('Save failed');
        _api.groupToReturn = _testGroup(name: 'Old');
        await pumpAndLoad(tester);

        getResult().nameController.text = 'New';
        final result = await getResult().saveGroup();
        await tester.pump();

        expect(result, isFalse);
        expect(getResult().state.error, isNotNull);
      });

      testWidgets('returns false and sets error on image upload failure', (tester) async {
        _api.uploadImageError = Exception('Upload failed');
        await pumpAndLoad(tester);

        getResult().onImageSelected('/new/image.jpg');
        await tester.pump();

        final result = await getResult().saveGroup();
        await tester.pump();

        expect(result, isFalse);
        expect(getResult().state.error, isNotNull);
      });

      testWidgets('returns true without saving if no unsaved changes', (tester) async {
        await pumpAndLoad(tester);

        final result = await getResult().saveGroup();
        await tester.pump();

        expect(result, isTrue);
        expect(_api.updateGroupDataCalls, isEmpty);
      });

      testWidgets('returns false and sets error when group not loaded', (tester) async {
        _api.getGroupError = Exception('Load failed');
        await pumpAndLoad(tester);

        getResult().nameController.text = 'Changed';
        await tester.pump();

        final result = await getResult().saveGroup();
        await tester.pump();

        expect(result, isFalse);
        expect(getResult().state.error, contains('Cannot update group'));
      });

      testWidgets('trims name and description before saving', (tester) async {
        _api.groupToReturn = _testGroup(name: 'Old');
        await pumpAndLoad(tester);

        getResult().nameController.text = '  Trimmed Name  ';
        getResult().descriptionController.text = '  Trimmed Desc  ';

        await getResult().saveGroup();
        await tester.pump();

        expect(_api.updateGroupDataCalls[0].data.name, 'Trimmed Name');
        expect(_api.updateGroupDataCalls[0].data.description, 'Trimmed Desc');
      });
    });

    group('discardChanges', () {
      testWidgets('resets controllers to loaded values', (tester) async {
        _api.groupToReturn = _testGroup(name: 'Original', description: 'Original Desc');
        await pumpAndLoad(tester);

        getResult().nameController.text = 'Changed';
        getResult().descriptionController.text = 'Changed Desc';
        getResult().onImageSelected('/new/image.jpg');
        await tester.pump();

        getResult().discardChanges();
        await tester.pump();

        expect(getResult().nameController.text, 'Original');
        expect(getResult().descriptionController.text, 'Original Desc');
        expect(getResult().state.selectedImagePath, isNull);
      });

      testWidgets('clears error', (tester) async {
        _api.updateGroupDataError = Exception('Save failed');
        _api.groupToReturn = _testGroup(name: 'Old');
        await pumpAndLoad(tester);

        getResult().nameController.text = 'New';
        await getResult().saveGroup();
        await tester.pump();
        expect(getResult().state.error, isNotNull);

        getResult().discardChanges();
        await tester.pump();

        expect(getResult().state.error, isNull);
      });

      testWidgets('does nothing if group not loaded', (tester) async {
        _api.getGroupError = Exception('Load failed');
        await pumpAndLoad(tester);

        getResult().discardChanges();
        await tester.pump();

        expect(getResult().state.name, isNull);
      });
    });
  });
}
