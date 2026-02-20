import 'package:whitenoise/src/rust/api/messages.dart';

List<ChatMessage> filterMessagesBySearch(List<ChatMessage> messages, String query) {
  final lowerQuery = query.toLowerCase();
  return messages.where((message) {
    if (message.isDeleted) return false;
    if (query.isEmpty) return true;
    return message.content.toLowerCase().contains(lowerQuery);
  }).toList();
}
