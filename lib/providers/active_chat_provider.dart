import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveChatNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String groupId) {
    if (!ref.mounted) return;
    state = groupId;
  }

  void clear() {
    if (!ref.mounted) return;
    state = null;
  }
}

final activeChatProvider = NotifierProvider<ActiveChatNotifier, String?>(
  ActiveChatNotifier.new,
);
