import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_route_refresh.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;
import 'package:whitenoise/src/rust/api/users.dart' as users_api;
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/utils/metadata.dart';

final _logger = Logger('useChatProfile');

class ChatProfile {
  final String? displayName;
  final String? pictureUrl;
  final String? otherMemberPubkey;
  final AvatarColor color;
  final bool isDm;

  const ChatProfile({
    this.displayName,
    required this.color,
    required this.isDm,

    this.pictureUrl,
    this.otherMemberPubkey,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatProfile &&
          runtimeType == other.runtimeType &&
          displayName == other.displayName &&
          pictureUrl == other.pictureUrl &&
          otherMemberPubkey == other.otherMemberPubkey &&
          color == other.color &&
          isDm == other.isDm;

  @override
  int get hashCode => Object.hash(
    displayName,
    pictureUrl,
    otherMemberPubkey,
    color,
    isDm,
  );
}

AsyncSnapshot<ChatProfile> useChatProfile(
  BuildContext context,
  String pubkey,
  String groupId,
) {
  final refreshKey = useState(0);

  useRouteRefresh(context, () => refreshKey.value++);

  final future = useMemoized(
    () => _fetchChatProfile(pubkey, groupId),
    [pubkey, groupId, refreshKey.value],
  );
  return useFuture(future);
}

Future<ChatProfile> _fetchChatProfile(String pubkey, String groupId) async {
  _logger.fine('Fetching chat profile for groupId: $groupId');

  final group = await groups_api.getGroup(
    accountPubkey: pubkey,
    groupId: groupId,
  );

  final isDm = await group.isDirectMessageType(accountPubkey: pubkey);

  if (isDm) {
    _logger.info('Fetching DM profile');
    return await _fetchDmProfile(group, pubkey);
  } else {
    _logger.info('Fetching group profile');
    return await _fetchGroupProfile(group, pubkey);
  }
}

Future<ChatProfile> _fetchGroupProfile(groups_api.Group group, String pubkey) async {
  _logger.info('Fetching group image path');
  final imagePath = await groups_api.getGroupImagePath(
    accountPubkey: pubkey,
    groupId: group.mlsGroupId,
  );
  _logger.fine('Group image path fetched');
  return ChatProfile(
    displayName: group.name.isEmpty ? null : group.name,
    pictureUrl: imagePath,
    color: AvatarColor.fromPubkey(group.mlsGroupId),
    isDm: false,
  );
}

Future<ChatProfile> _fetchDmProfile(
  groups_api.Group group,
  String pubkey,
) async {
  final groupId = group.mlsGroupId;
  _logger.info('Fetching group members');
  final memberPubkeys = await groups_api.groupMembers(
    pubkey: pubkey,
    groupId: groupId,
  );

  final otherMemberPubkey = memberPubkeys.where((p) => p != pubkey).firstOrNull;

  if (otherMemberPubkey == null) {
    _logger.warning('No other member found in DM group');
    return ChatProfile(
      color: AvatarColor.fromPubkey(groupId),
      isDm: true,
    );
  }

  final metadata = await users_api.userMetadata(
    pubkey: otherMemberPubkey,
    blockingDataSync: false,
  );

  return ChatProfile(
    displayName: presentName(metadata),
    pictureUrl: metadata.picture,
    otherMemberPubkey: otherMemberPubkey,
    color: AvatarColor.fromPubkey(otherMemberPubkey),
    isDm: true,
  );
}
