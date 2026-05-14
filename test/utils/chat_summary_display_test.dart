import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/utils/chat_summary_display.dart';
import 'package:whitenoise_frb/src/rust/api/chat_summary.dart';
import 'package:whitenoise_frb/src/rust/api/groups.dart' show GroupType;

import '../test_helpers.dart';

const _groupId = testGroupId;
const _dmPeerPubkey = testPubkeyB;

ChatSummary _dmSummary({String? dmPeerPubkey = _dmPeerPubkey}) => ChatSummary(
  mlsGroupId: _groupId,
  groupType: GroupType.directMessage,
  createdAt: DateTime(2024),
  pendingConfirmation: false,
  selfRemoved: false,
  unreadCount: BigInt.zero,
  dmPeerPubkey: dmPeerPubkey,
  groupImageUrl: 'https://example.com/peer.jpg',
);

ChatSummary _groupSummary() => ChatSummary(
  mlsGroupId: _groupId,
  groupType: GroupType.group,
  name: 'Cool Group',
  createdAt: DateTime(2024),
  pendingConfirmation: false,
  selfRemoved: false,
  unreadCount: BigInt.zero,
  groupImagePath: '/path/to/group.jpg',
);

void main() {
  group('chatSummaryDisplay', () {
    group('color', () {
      test('uses dmPeerPubkey when isDm and dmPeerPubkey is set', () {
        final result = chatSummaryDisplay(_dmSummary(), _groupId);
        expect(result.color, AvatarColor.fromPubkey(_dmPeerPubkey));
      });

      test('falls back to groupId when isDm but dmPeerPubkey is null', () {
        final result = chatSummaryDisplay(_dmSummary(dmPeerPubkey: null), _groupId);
        expect(result.color, AvatarColor.fromPubkey(_groupId));
      });

      test('uses groupId when summary is null', () {
        final result = chatSummaryDisplay(null, _groupId);
        expect(result.color, AvatarColor.fromPubkey(_groupId));
      });

      test('uses groupId for groups', () {
        final result = chatSummaryDisplay(_groupSummary(), _groupId);
        expect(result.color, AvatarColor.fromPubkey(_groupId));
      });
    });

    group('pictureUrl', () {
      test('is groupImageUrl for DMs', () {
        final result = chatSummaryDisplay(_dmSummary(), _groupId);
        expect(result.pictureUrl, 'https://example.com/peer.jpg');
      });

      test('is groupImagePath for groups', () {
        final result = chatSummaryDisplay(_groupSummary(), _groupId);
        expect(result.pictureUrl, '/path/to/group.jpg');
      });

      test('is null when summary is null', () {
        final result = chatSummaryDisplay(null, _groupId);
        expect(result.pictureUrl, isNull);
      });
    });

    group('displayName', () {
      test('is null when summary is null', () {
        final result = chatSummaryDisplay(null, _groupId);
        expect(result.displayName, isNull);
      });

      test('is null when name is empty string', () {
        final summary = ChatSummary(
          mlsGroupId: _groupId,
          groupType: GroupType.group,
          name: '',
          createdAt: DateTime(2024),
          pendingConfirmation: false,
          selfRemoved: false,
          unreadCount: BigInt.zero,
        );
        final result = chatSummaryDisplay(summary, _groupId);
        expect(result.displayName, isNull);
      });

      test('returns name when non-empty', () {
        final result = chatSummaryDisplay(_groupSummary(), _groupId);
        expect(result.displayName, 'Cool Group');
      });
    });
  });
}
