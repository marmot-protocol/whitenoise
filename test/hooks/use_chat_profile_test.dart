import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_chat_profile.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart' show UserUpdateTrigger;
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

const _pubkey = testPubkeyA;
const _groupId = otherTestGroupId;
const _otherPubkey = testPubkeyB;
const _pubkeyColor = AvatarColor.violet;
const _otherPubkeyColor = AvatarColor.amber;
const _groupIdColor = AvatarColor.cyan;

Group _group({required String name}) => Group(
  mlsGroupId: _groupId,
  nostrGroupId: 'nostr_$_groupId',
  name: name,
  description: '',
  adminPubkeys: const [],
  epoch: BigInt.zero,
  state: GroupState.active,
);

const _metadata = FlutterMetadata(
  displayName: 'Alice',
  name: 'alice',
  picture: 'https://example.com/alice.jpg',
  custom: {},
);

class _MockApi extends MockWnApi {
  bool isDm = false;
  String groupName = 'Test Group';
  List<String> members = [_pubkey, _otherPubkey];
  FlutterMetadata _currentMetadata = _metadata;
  FlutterMetadata get metadata => _currentMetadata;
  set metadata(FlutterMetadata value) {
    _currentMetadata = value;
    seedUserInitialSnapshot(_otherPubkey, metadata: value);
  }

  bool shouldError = false;

  @override
  Future<Group> crateApiGroupsGetGroup({
    required String accountPubkey,
    required String groupId,
  }) {
    if (shouldError) return Future.error(Exception('fail'));
    return Future.value(_group(name: groupName));
  }

  @override
  Future<bool> crateApiGroupsGroupIsDirectMessageType({
    required Group that,
    required String accountPubkey,
  }) => Future.value(isDm);

  @override
  Future<List<String>> crateApiGroupsGroupMembers({
    required String pubkey,
    required String groupId,
  }) => Future.value(members);

  @override
  Future<FlutterMetadata> crateApiUsersUserMetadata({
    required String pubkey,
    required bool blockingDataSync,
  }) => Future.value(_currentMetadata);

  @override
  Future<String?> crateApiGroupsGetGroupImagePath({
    required String accountPubkey,
    required String groupId,
  }) => Future.value('https://example.com/group.jpg');
}

final _api = _MockApi();

late AsyncSnapshot<ChatProfile> Function() getResult;

Future<void> _mountHook(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HookBuilder(
        builder: (context) {
          final result = useChatProfile(context, _pubkey, _groupId);
          getResult = () => result;
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() => RustLib.initMock(api: _api));

  setUp(() {
    _api.reset();
    _api.isDm = false;
    _api.groupName = 'Test Group';
    _api.members = [_pubkey, _otherPubkey];
    _api.metadata = _metadata;
    _api.shouldError = false;
  });

  group('useChatProfile', () {
    group('when is DM', () {
      setUp(() => _api.isDm = true);

      group('when other member has metadata', () {
        testWidgets('returns other member profile', (tester) async {
          await _mountHook(tester);

          expect(
            getResult().data,
            const ChatProfile(
              displayName: 'Alice',
              color: _otherPubkeyColor,
              pictureUrl: 'https://example.com/alice.jpg',
              otherMemberPubkey: _otherPubkey,
              isDm: true,
            ),
          );
        });

        testWidgets('falls back to name when displayName is null', (tester) async {
          _api.metadata = const FlutterMetadata(name: 'bob', custom: {});
          await _mountHook(tester);

          expect(
            getResult().data,
            const ChatProfile(
              displayName: 'bob',
              color: _otherPubkeyColor,
              otherMemberPubkey: _otherPubkey,
              isDm: true,
            ),
          );
        });
      });

      group('when other member metadata arrives after the initial snapshot', () {
        testWidgets('updates the DM profile without remounting', (tester) async {
          _api.metadata = const FlutterMetadata(custom: {});
          await _mountHook(tester);

          expect(
            getResult().data,
            const ChatProfile(
              color: _otherPubkeyColor,
              otherMemberPubkey: _otherPubkey,
              isDm: true,
            ),
          );

          _api.emitUserUpdate(
            _otherPubkey,
            trigger: UserUpdateTrigger.metadataChanged,
            metadata: _metadata,
          );
          await tester.pump();

          expect(
            getResult().data,
            const ChatProfile(
              displayName: 'Alice',
              color: _otherPubkeyColor,
              pictureUrl: 'https://example.com/alice.jpg',
              otherMemberPubkey: _otherPubkey,
              isDm: true,
            ),
          );
        });
      });

      group('when other member has no metadata', () {
        testWidgets('returns Unknown User profile', (tester) async {
          _api.metadata = const FlutterMetadata(custom: {});
          await _mountHook(tester);

          expect(
            getResult().data,
            const ChatProfile(
              color: _otherPubkeyColor,
              otherMemberPubkey: _otherPubkey,
              isDm: true,
            ),
          );
        });
      });

      group('when there is no other member', () {
        setUp(() => _api.members = [_pubkey]);

        testWidgets('returns Unknown User profile', (tester) async {
          await _mountHook(tester);

          expect(
            getResult().data,
            const ChatProfile(
              color: _groupIdColor,
              isDm: true,
            ),
          );
        });
      });
    });

    group('when is not DM', () {
      setUp(() => _api.isDm = false);

      testWidgets('returns group profile', (tester) async {
        _api.groupName = 'Cool Group';
        await _mountHook(tester);

        expect(
          getResult().data,
          const ChatProfile(
            displayName: 'Cool Group',
            color: _groupIdColor,
            pictureUrl: 'https://example.com/group.jpg',
            isDm: false,
          ),
        );
      });

      testWidgets('returns Unknown group when group name is empty', (tester) async {
        _api.groupName = '';
        await _mountHook(tester);

        expect(
          getResult().data,
          const ChatProfile(
            color: _groupIdColor,
            pictureUrl: 'https://example.com/group.jpg',
            isDm: false,
          ),
        );
      });

      group('on error', () {
        setUp(() {
          _api.shouldError = true;
        });

        testWidgets('returns error on failure', (tester) async {
          await _mountHook(tester);

          expect(getResult().hasError, isTrue);
        });
      });
    });
  });

  group('ChatProfile equality and hashCode', () {
    test('equal objects have equal hash codes', () {
      const profile1 = ChatProfile(
        displayName: 'Alice',
        color: _pubkeyColor,
        pictureUrl: 'https://example.com/alice.jpg',
        otherMemberPubkey: testPubkeyA,
        isDm: false,
      );
      const profile2 = ChatProfile(
        displayName: 'Alice',
        color: _pubkeyColor,
        pictureUrl: 'https://example.com/alice.jpg',
        otherMemberPubkey: testPubkeyA,
        isDm: false,
      );

      expect(profile1, profile2);
      expect(profile1.hashCode, profile2.hashCode);
    });

    test('equal objects with null pictureUrl have equal hash codes', () {
      const profile1 = ChatProfile(displayName: 'Bob', color: AvatarColor.blue, isDm: false);
      const profile2 = ChatProfile(displayName: 'Bob', color: AvatarColor.blue, isDm: false);

      expect(profile1, profile2);
      expect(profile1.hashCode, profile2.hashCode);
    });

    test('different displayNames produce different hash codes', () {
      const profile1 = ChatProfile(displayName: 'Alice', color: AvatarColor.blue, isDm: false);
      const profile2 = ChatProfile(displayName: 'Bob', color: AvatarColor.blue, isDm: false);

      expect(profile1, isNot(profile2));
      expect(profile1.hashCode, isNot(profile2.hashCode));
    });

    test('different pictureUrls produce different hash codes', () {
      const profile1 = ChatProfile(
        displayName: 'Alice',
        color: AvatarColor.blue,
        pictureUrl: 'https://example.com/pic1.jpg',
        isDm: false,
      );
      const profile2 = ChatProfile(
        displayName: 'Alice',
        color: AvatarColor.blue,
        pictureUrl: 'https://example.com/pic2.jpg',
        isDm: false,
      );

      expect(profile1, isNot(profile2));
      expect(profile1.hashCode, isNot(profile2.hashCode));
    });

    test('different otherMemberPubkeys produce different hash codes', () {
      const profile1 = ChatProfile(
        displayName: 'Alice',
        color: AvatarColor.blue,
        otherMemberPubkey: testPubkeyA,
        isDm: false,
      );
      const profile2 = ChatProfile(
        displayName: 'Alice',
        color: AvatarColor.blue,
        otherMemberPubkey: testPubkeyB,
        isDm: false,
      );

      expect(profile1, isNot(profile2));
      expect(profile1.hashCode, isNot(profile2.hashCode));
    });

    test('different colors produce different hash codes', () {
      const profile1 = ChatProfile(displayName: 'Alice', color: AvatarColor.blue, isDm: false);
      const profile2 = ChatProfile(displayName: 'Alice', color: AvatarColor.amber, isDm: false);

      expect(profile1, isNot(profile2));
      expect(profile1.hashCode, isNot(profile2.hashCode));
    });

    test('different isDm produce different hash codes', () {
      const profile1 = ChatProfile(displayName: 'Alice', color: AvatarColor.blue, isDm: false);
      const profile2 = ChatProfile(displayName: 'Alice', color: AvatarColor.blue, isDm: true);

      expect(profile1, isNot(profile2));
      expect(profile1.hashCode, isNot(profile2.hashCode));
    });
  });
}
