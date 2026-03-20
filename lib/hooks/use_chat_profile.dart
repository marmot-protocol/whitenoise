import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/hooks/use_route_refresh.dart';
import 'package:whitenoise/services/user_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;
import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise/utils/metadata.dart';

final _logger = Logger('useChatProfile');

typedef _ChatProfileBase = ({
  groups_api.Group group,
  bool isDm,
  String? groupImagePath,
  String? otherMemberPubkey,
});

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

  final baseFuture = useMemoized(
    () => _fetchChatProfileBase(pubkey, groupId),
    [pubkey, groupId, refreshKey.value],
  );
  final baseSnapshot = useFuture(baseFuture);
  final metadataStream = useMemoized(() {
    final base = baseSnapshot.data;
    if (base == null || !base.isDm || base.otherMemberPubkey == null) {
      return null;
    }
    return UserService(base.otherMemberPubkey!).watchMetadata();
  }, [baseSnapshot.data?.isDm, baseSnapshot.data?.otherMemberPubkey]);
  final metadataSnapshot = useStream(metadataStream);

  if (baseSnapshot.hasError) {
    return AsyncSnapshot<ChatProfile>.withError(
      baseSnapshot.connectionState,
      baseSnapshot.error!,
      baseSnapshot.stackTrace ?? StackTrace.empty,
    );
  }

  final base = baseSnapshot.data;
  if (base == null) {
    return switch (baseSnapshot.connectionState) {
      ConnectionState.waiting => const AsyncSnapshot<ChatProfile>.waiting(),
      _ => const AsyncSnapshot<ChatProfile>.nothing(),
    };
  }

  if (!base.isDm) {
    return AsyncSnapshot<ChatProfile>.withData(
      baseSnapshot.connectionState,
      ChatProfile(
        displayName: base.group.name.isEmpty ? null : base.group.name,
        pictureUrl: base.groupImagePath,
        color: AvatarColor.fromPubkey(base.group.mlsGroupId),
        isDm: false,
      ),
    );
  }

  if (base.otherMemberPubkey == null) {
    return AsyncSnapshot<ChatProfile>.withData(
      baseSnapshot.connectionState,
      ChatProfile(
        color: AvatarColor.fromPubkey(base.group.mlsGroupId),
        isDm: true,
      ),
    );
  }

  if (metadataSnapshot.hasError) {
    return AsyncSnapshot<ChatProfile>.withError(
      metadataSnapshot.connectionState,
      metadataSnapshot.error!,
      metadataSnapshot.stackTrace ?? StackTrace.empty,
    );
  }

  if (!metadataSnapshot.hasData && metadataSnapshot.connectionState == ConnectionState.waiting) {
    return const AsyncSnapshot<ChatProfile>.waiting();
  }

  final metadata = metadataSnapshot.data;
  return AsyncSnapshot<ChatProfile>.withData(
    metadataSnapshot.connectionState,
    ChatProfile(
      displayName: presentName(metadata),
      pictureUrl: metadata?.picture,
      otherMemberPubkey: base.otherMemberPubkey,
      color: AvatarColor.fromPubkey(base.otherMemberPubkey!),
      isDm: true,
    ),
  );
}

Future<_ChatProfileBase> _fetchChatProfileBase(String pubkey, String groupId) async {
  _logger.fine('Fetching chat profile for groupId: $groupId');

  final group = await groups_api.getGroup(
    accountPubkey: pubkey,
    groupId: groupId,
  );

  final isDm = await group.isDirectMessageType(accountPubkey: pubkey);

  if (isDm) {
    _logger.info('Fetching DM profile base');
    final memberPubkeys = await groups_api.groupMembers(
      pubkey: pubkey,
      groupId: group.mlsGroupId,
    );

    return (
      group: group,
      isDm: true,
      groupImagePath: null,
      otherMemberPubkey: memberPubkeys.where((p) => p != pubkey).firstOrNull,
    );
  }

  _logger.info('Fetching group profile base');
  final groupImagePath = await groups_api.getGroupImagePath(
    accountPubkey: pubkey,
    groupId: group.mlsGroupId,
  );
  _logger.fine('Group image path fetched');
  return (
    group: group,
    isDm: false,
    groupImagePath: groupImagePath,
    otherMemberPubkey: null,
  );
}
