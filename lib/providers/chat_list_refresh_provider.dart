import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatListRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void requestRefresh() {
    state++;
  }
}

final chatListRefreshProvider = NotifierProvider<ChatListRefreshNotifier, int>(
  ChatListRefreshNotifier.new,
);
