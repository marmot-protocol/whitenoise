import 'package:whitenoise/src/rust/api/chat_list.dart';

List<ChatSummary> filterChatsBySearch(List<ChatSummary> chats, String query) {
  if (query.isEmpty) return chats;
  final lowerQuery = query.toLowerCase();
  return chats.where((chat) {
    final name = chat.name?.toLowerCase() ?? '';
    return name.contains(lowerQuery);
  }).toList();
}

List<ChatSummary> filterChatsBySearchWithMessageMatches(
  List<ChatSummary> chats,
  String query,
  Set<String> messageMatchedGroupIds,
) {
  if (query.isEmpty) return chats;
  final lowerQuery = query.toLowerCase();
  return chats.where((chat) {
    final name = chat.name?.toLowerCase() ?? '';
    return name.contains(lowerQuery) || messageMatchedGroupIds.contains(chat.mlsGroupId);
  }).toList();
}
