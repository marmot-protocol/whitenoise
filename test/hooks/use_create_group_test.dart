import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_create_group.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/src/rust/lib.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

User _createTestUser(String pubkey, {String? name}) {
  return User(
    pubkey: pubkey,
    metadata: FlutterMetadata(
      name: name,
      displayName: name,
      custom: const {},
    ),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

class _MockApi extends MockWnApi {
  bool createGroupCalled = false;
  String? createdGroupName;
  String? createdGroupDescription;
  List<String>? createdMemberPubkeys;
  List<String>? createdAdminPubkeys;
  final Map<String, KeyPackageStatus> userHasKeyPackageMap = {};
  bool shouldThrowOnUserHasKeyPackage = false;
  bool shouldThrowOnCreateGroup = false;
  bool shouldThrowOnUploadImage = false;
  bool shouldThrowOnUpdateGroupData = false;

  @override
  Future<Group> crateApiGroupsCreateGroup({
    required String creatorPubkey,
    required List<String> memberPubkeys,
    required List<String> adminPubkeys,
    required String groupName,
    required String groupDescription,
    required GroupType groupType,
  }) {
    if (shouldThrowOnCreateGroup) {
      throw Exception('Failed to create group');
    }
    createGroupCalled = true;
    createdGroupName = groupName;
    createdGroupDescription = groupDescription;
    createdMemberPubkeys = memberPubkeys;
    createdAdminPubkeys = adminPubkeys;

    return Future.value(
      Group(
        mlsGroupId: testGroupId,
        nostrGroupId: testNostrGroupId,
        name: groupName,
        description: groupDescription,
        adminPubkeys: adminPubkeys,
        epoch: BigInt.zero,
        state: GroupState.active,
      ),
    );
  }

  @override
  Future<KeyPackageStatus> crateApiUsersUserHasKeyPackage({
    required String pubkey,
    required bool blockingDataSync,
  }) {
    if (shouldThrowOnUserHasKeyPackage) {
      throw Exception('Failed to check key package');
    }
    return Future.value(
      userHasKeyPackageMap[pubkey] ?? KeyPackageStatus.notFound,
    );
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
  }) {
    if (shouldThrowOnUploadImage) {
      throw Exception('Failed to upload image');
    }
    return Future.value(
      UploadGroupImageResult(
        imageKey: U8Array32(Uint8List(32)),
        encryptedHash: U8Array32(Uint8List(32)),
        imageNonce: U8Array12(Uint8List(12)),
      ),
    );
  }

  @override
  Future<void> crateApiGroupsGroupUpdateGroupData({
    required Group that,
    required String accountPubkey,
    required FlutterGroupDataUpdate groupData,
  }) {
    if (shouldThrowOnUpdateGroupData) {
      throw Exception('Failed to update group data');
    }
    return Future.value();
  }
}

void main() {
  late _MockApi mockApi;

  setUpAll(() {
    mockApi = _MockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
    mockApi.createGroupCalled = false;
    mockApi.createdGroupName = null;
    mockApi.createdGroupDescription = null;
    mockApi.createdMemberPubkeys = null;
    mockApi.createdAdminPubkeys = null;
    mockApi.userHasKeyPackageMap.clear();
    mockApi.shouldThrowOnUserHasKeyPackage = false;
    mockApi.shouldThrowOnCreateGroup = false;
    mockApi.shouldThrowOnUploadImage = false;
    mockApi.shouldThrowOnUpdateGroupData = false;
  });

  group('useCreateGroup', () {
    testWidgets('initializes with empty state', (tester) async {
      late CreateGroupState state;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(const []);
          state = result.state;
          return Container();
        },
      );

      expect(state.groupName, isEmpty);
      expect(state.groupDescription, isEmpty);
      expect(state.selectedImagePath, isNull);
      expect(state.usersWithKeyPackage, isEmpty);
      expect(state.usersWithoutKeyPackage, isEmpty);
      expect(state.isCreating, isFalse);
      expect(state.isUploadingImage, isFalse);
      expect(state.error, isNull);
      expect(state.isFilteringUsers, isFalse);
    });

    testWidgets('groupNameController updates state', (tester) async {
      late CreateGroupState state;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(const []);
          state = result.state;
          return Container();
        },
      );

      state.groupNameController.text = 'Test Group';
      await tester.pump();

      expect(state.groupName, 'Test Group');
      expect(state.error, isNull);
    });

    testWidgets('groupDescriptionController updates state', (tester) async {
      late CreateGroupState state;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(const []);
          state = result.state;
          return Container();
        },
      );

      state.groupDescriptionController.text = 'Test Description';
      await tester.pump();

      expect(state.groupDescription, 'Test Description');
      expect(state.error, isNull);
    });

    testWidgets('updateSelectedImagePath updates state', (tester) async {
      late CreateGroupState state;
      late CreateGroupActions actions;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(const []);
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      actions.updateSelectedImagePath('/path/to/image.jpg');
      await tester.pump();

      expect(state.selectedImagePath, '/path/to/image.jpg');
      expect(state.error, isNull);
    });

    testWidgets('filters users by key package on init', (tester) async {
      mockApi.userHasKeyPackageMap[testPubkeyA] = KeyPackageStatus.valid;
      mockApi.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.notFound;

      final users = [
        _createTestUser(testPubkeyA, name: 'Alice'),
        _createTestUser(testPubkeyB, name: 'Bob'),
      ];

      late CreateGroupState state;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(users);
          state = result.state;
          return Container();
        },
      );
      await tester.pumpAndSettle();

      expect(state.usersWithKeyPackage, hasLength(1));
      expect(state.usersWithKeyPackage.first.pubkey, testPubkeyA);
      expect(state.usersWithoutKeyPackage, hasLength(1));
      expect(state.usersWithoutKeyPackage.first.pubkey, testPubkeyB);
    });

    testWidgets('createGroup returns null when group name is empty', (tester) async {
      late CreateGroupState state;
      late CreateGroupActions actions;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(const []);
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      final group = await actions.createGroup(testPubkeyA);
      await tester.pump();

      expect(group, isNull);
      expect(state.error, CreateGroupError.groupNameRequired);
      expect(mockApi.createGroupCalled, isFalse);
    });

    testWidgets('createGroup returns null when no users with key packages', (tester) async {
      late CreateGroupState state;
      late CreateGroupActions actions;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(const []);
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      state.groupNameController.text = 'Test Group';
      await tester.pump();

      final group = await actions.createGroup(testPubkeyA);
      await tester.pump();

      expect(group, isNull);
      expect(state.error, CreateGroupError.noUsersWithKeyPackages);
      expect(mockApi.createGroupCalled, isFalse);
    });

    testWidgets('createGroup creates group successfully', (tester) async {
      mockApi.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;
      mockApi.userHasKeyPackageMap[testPubkeyC] = KeyPackageStatus.valid;

      final users = [
        _createTestUser(testPubkeyB, name: 'Bob'),
        _createTestUser(testPubkeyC, name: 'Charlie'),
      ];

      late CreateGroupState state;
      late CreateGroupActions actions;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(users);
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      state.groupNameController.text = 'Test Group';
      state.groupDescriptionController.text = 'Test Description';
      await tester.pumpAndSettle();

      final group = await actions.createGroup(testPubkeyA);
      await tester.pumpAndSettle();

      expect(group, isNotNull);
      expect(group!.mlsGroupId, testGroupId);
      expect(mockApi.createGroupCalled, isTrue);
      expect(mockApi.createdGroupName, 'Test Group');
      expect(mockApi.createdGroupDescription, 'Test Description');
      expect(mockApi.createdMemberPubkeys, hasLength(2));
      expect(mockApi.createdAdminPubkeys, contains(testPubkeyA));
    });

    testWidgets('clearError clears error state', (tester) async {
      late CreateGroupState state;
      late CreateGroupActions actions;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(const []);
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      await actions.createGroup(testPubkeyA);
      await tester.pump();

      expect(state.error, isNotNull);

      actions.clearError();
      await tester.pump();

      expect(state.error, isNull);
    });

    testWidgets('reset clears all state', (tester) async {
      mockApi.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;

      final users = [_createTestUser(testPubkeyB, name: 'Bob')];

      late CreateGroupState state;
      late CreateGroupActions actions;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(users);
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      state.groupNameController.text = 'Test Group';
      state.groupDescriptionController.text = 'Test Description';
      actions.updateSelectedImagePath('/path/to/image.jpg');
      await tester.pumpAndSettle();

      expect(state.groupName, isNotEmpty);
      expect(state.groupDescription, isNotEmpty);
      expect(state.selectedImagePath, isNotNull);
      expect(state.usersWithKeyPackage, isNotEmpty);

      actions.reset();
      await tester.pump();

      expect(state.groupName, isEmpty);
      expect(state.groupDescription, isEmpty);
      expect(state.selectedImagePath, isNull);
      expect(state.usersWithKeyPackage, isEmpty);
      expect(state.usersWithoutKeyPackage, isEmpty);
      expect(state.isCreating, isFalse);
      expect(state.isUploadingImage, isFalse);
      expect(state.error, isNull);
      expect(state.isFilteringUsers, isFalse);
    });

    testWidgets('users without key packages are placed in correct list', (tester) async {
      final users = [
        _createTestUser(testPubkeyB, name: 'Bob'),
      ];

      late CreateGroupState state;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(users);
          state = result.state;
          return Container();
        },
      );
      await tester.pumpAndSettle();

      expect(state.usersWithoutKeyPackage, hasLength(1));
    });

    testWidgets('createGroup with image path sets uploading state', (tester) async {
      mockApi.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;

      final users = [_createTestUser(testPubkeyB, name: 'Bob')];

      late CreateGroupState state;
      late CreateGroupActions actions;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(users);
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      state.groupNameController.text = 'Test Group';
      actions.updateSelectedImagePath('/path/to/image.jpg');
      await tester.pumpAndSettle();

      final groupFuture = actions.createGroup(testPubkeyA);
      await tester.pump();

      await groupFuture;
      await tester.pumpAndSettle();

      expect(mockApi.createGroupCalled, isTrue);
    });

    testWidgets('key package check errors place users in without list', (tester) async {
      mockApi.shouldThrowOnUserHasKeyPackage = true;

      final users = [
        _createTestUser(testPubkeyA, name: 'Alice'),
        _createTestUser(testPubkeyB, name: 'Bob'),
      ];

      late CreateGroupState state;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(users);
          state = result.state;
          return Container();
        },
      );
      await tester.pumpAndSettle();

      expect(state.usersWithoutKeyPackage, hasLength(2));
      expect(state.usersWithKeyPackage, isEmpty);
    });

    testWidgets('createGroup handles errors and sets error state', (tester) async {
      mockApi.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;
      mockApi.shouldThrowOnCreateGroup = true;

      final users = [_createTestUser(testPubkeyB, name: 'Bob')];

      late CreateGroupState state;
      late CreateGroupActions actions;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(users);
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      state.groupNameController.text = 'Test Group';
      await tester.pumpAndSettle();

      final group = await actions.createGroup(testPubkeyA);
      await tester.pump();

      expect(group, isNull);
      expect(state.error, CreateGroupError.createGroupFailed);
    });

    testWidgets('createGroup with image upload success', (tester) async {
      mockApi.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;

      final users = [_createTestUser(testPubkeyB, name: 'Bob')];

      late CreateGroupState state;
      late CreateGroupActions actions;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(users);
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      state.groupNameController.text = 'Test Group';
      actions.updateSelectedImagePath('/path/to/image.jpg');
      await tester.pumpAndSettle();

      final group = await actions.createGroup(testPubkeyA);
      await tester.pumpAndSettle();

      expect(group, isNotNull);
      expect(state.isUploadingImage, isFalse);
      expect(mockApi.createGroupCalled, isTrue);
    });

    testWidgets('createGroup handles image upload failure gracefully', (tester) async {
      mockApi.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;
      mockApi.shouldThrowOnUploadImage = true;

      final users = [_createTestUser(testPubkeyB, name: 'Bob')];

      late CreateGroupState state;
      late CreateGroupActions actions;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(users);
          state = result.state;
          actions = result.actions;
          return Container();
        },
      );

      state.groupNameController.text = 'Test Group';
      actions.updateSelectedImagePath('/path/to/image.jpg');
      await tester.pumpAndSettle();

      final group = await actions.createGroup(testPubkeyA);
      await tester.pumpAndSettle();

      expect(group, isNotNull);
      expect(mockApi.createGroupCalled, isTrue);
    });

    testWidgets('empty selectedUsers results in empty key package lists', (tester) async {
      late CreateGroupState state;

      await mountHook(
        tester,
        () {
          final result = useCreateGroup(const []);
          state = result.state;
          return Container();
        },
      );
      await tester.pumpAndSettle();

      expect(state.usersWithKeyPackage, isEmpty);
      expect(state.usersWithoutKeyPackage, isEmpty);
    });

    testWidgets('re-filters when selectedUsers changes', (tester) async {
      mockApi.userHasKeyPackageMap[testPubkeyA] = KeyPackageStatus.valid;
      mockApi.userHasKeyPackageMap[testPubkeyB] = KeyPackageStatus.valid;

      late CreateGroupState state;
      late ValueNotifier<List<User>> usersNotifier;

      await mountHook(
        tester,
        () {
          usersNotifier = useState<List<User>>(
            [_createTestUser(testPubkeyA, name: 'Alice')],
          );
          final result = useCreateGroup(usersNotifier.value);
          state = result.state;
          return Container();
        },
      );
      await tester.pumpAndSettle();

      expect(state.usersWithKeyPackage, hasLength(1));
      expect(state.usersWithKeyPackage.first.pubkey, testPubkeyA);

      usersNotifier.value = [
        _createTestUser(testPubkeyA, name: 'Alice'),
        _createTestUser(testPubkeyB, name: 'Bob'),
      ];
      await tester.pumpAndSettle();

      expect(state.usersWithKeyPackage, hasLength(2));
    });
  });
}
