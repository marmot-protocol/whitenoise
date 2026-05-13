import 'package:rust_lib_whitenoise/src/rust/api/chat_summary.dart' show ChatSummary;

List<ChatSummary> filterChatsBySearchWithMessageMatches(
  List<ChatSummary> chats,
  String query,
  Set<String> messageMatchedGroupIds,
) {
  final trimmedQuery = query.trim();
  if (trimmedQuery.isEmpty) return chats;
  final lowerQuery = trimmedQuery.toLowerCase();
  return chats.where((chat) {
    final name = chat.name?.toLowerCase() ?? '';
    return name.contains(lowerQuery) || messageMatchedGroupIds.contains(chat.mlsGroupId);
  }).toList();
}
