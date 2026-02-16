import 'dart:async' show Future;

import 'package:flutter/widgets.dart';
import 'package:whitenoise/providers/active_chat_provider.dart';

class ActiveChatRouteObserver extends NavigatorObserver {
  final ActiveChatNotifier _notifier;

  ActiveChatRouteObserver(this._notifier);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateFromRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateFromRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _updateFromRoute(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateFromRoute(previousRoute);
  }

  static final _chatPattern = RegExp(r'^/chats/(.+)$');
  static final _invitePattern = RegExp(r'^/invites/(.+)$');

  void _updateFromRoute(Route<dynamic>? route) {
    final path = route?.settings.name;
    if (path == null) {
      Future.microtask(() => _notifier.clear());
      return;
    }

    final chatMatch = _chatPattern.firstMatch(path);
    if (chatMatch != null) {
      Future.microtask(() => _notifier.set(chatMatch.group(1)!));
      return;
    }

    final inviteMatch = _invitePattern.firstMatch(path);
    if (inviteMatch != null) {
      Future.microtask(() => _notifier.set(inviteMatch.group(1)!));
      return;
    }

    Future.microtask(() => _notifier.clear());
  }
}
