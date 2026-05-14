import 'package:whitenoise/utils/avatar_color.dart';
import 'package:whitenoise_frb/src/rust/api/chat_summary.dart';
import 'package:whitenoise_frb/src/rust/api/groups.dart' show GroupType;

typedef ChatSummaryDisplay = ({
  String? displayName,
  String? pictureUrl,
  AvatarColor color,
});

ChatSummaryDisplay chatSummaryDisplay(ChatSummary? summary, String groupId) {
  final isDm = summary == null || summary.groupType == GroupType.directMessage;
  final colorKey = isDm ? (summary?.dmPeerPubkey ?? groupId) : groupId;
  final name = summary?.name?.isNotEmpty == true ? summary!.name : null;
  return (
    displayName: name,
    pictureUrl: isDm ? summary?.groupImageUrl : summary.groupImagePath,
    color: AvatarColor.fromPubkey(colorKey),
  );
}
