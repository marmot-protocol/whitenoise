import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/observers/active_chat_route_observer.dart';
import 'package:whitenoise/providers/active_chat_provider.dart';

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('ActiveChatRouteObserver', () {
    late ProviderContainer container;
    late ActiveChatRouteObserver observer;

    setUp(() {
      container = ProviderContainer();
      observer = ActiveChatRouteObserver(container.read(activeChatProvider.notifier));
    });

    tearDown(() => container.dispose());

    Route<dynamic> fakeRoute(String? name) {
      return PageRouteBuilder<void>(
        settings: RouteSettings(name: name),
        pageBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    group('didPush', () {
      test('sets active chat for chat route', () async {
        observer.didPush(fakeRoute('/chats/group123'), null);
        await _flushMicrotasks();
        expect(container.read(activeChatProvider), 'group123');
      });

      test('sets active chat for invite route', () async {
        observer.didPush(fakeRoute('/invites/group456'), null);
        await _flushMicrotasks();
        expect(container.read(activeChatProvider), 'group456');
      });

      test('clears active chat for non-chat route', () async {
        container.read(activeChatProvider.notifier).set('group123');
        observer.didPush(fakeRoute('/settings'), null);
        await _flushMicrotasks();
        expect(container.read(activeChatProvider), isNull);
      });

      test('clears when route name is null', () async {
        container.read(activeChatProvider.notifier).set('group123');
        observer.didPush(fakeRoute(null), null);
        await _flushMicrotasks();
        expect(container.read(activeChatProvider), isNull);
      });
    });

    group('didPop', () {
      test('updates from previousRoute', () async {
        observer.didPop(fakeRoute('/chats/group123'), fakeRoute('/chats'));
        await _flushMicrotasks();
        expect(container.read(activeChatProvider), isNull);
      });

      test('sets active chat when popping to chat route', () async {
        observer.didPop(fakeRoute('/settings'), fakeRoute('/chats/group123'));
        await _flushMicrotasks();
        expect(container.read(activeChatProvider), 'group123');
      });

      test('clears when previousRoute is null', () async {
        container.read(activeChatProvider.notifier).set('group123');
        observer.didPop(fakeRoute('/chats/group123'), null);
        await _flushMicrotasks();
        expect(container.read(activeChatProvider), isNull);
      });
    });

    group('didReplace', () {
      test('updates from newRoute', () async {
        observer.didReplace(
          newRoute: fakeRoute('/chats/newGroup'),
          oldRoute: fakeRoute('/chats/oldGroup'),
        );
        await _flushMicrotasks();
        expect(container.read(activeChatProvider), 'newGroup');
      });

      test('clears for non-chat newRoute', () async {
        container.read(activeChatProvider.notifier).set('group123');
        observer.didReplace(
          newRoute: fakeRoute('/settings'),
          oldRoute: fakeRoute('/chats/group123'),
        );
        await _flushMicrotasks();
        expect(container.read(activeChatProvider), isNull);
      });

      test('clears when newRoute is null', () async {
        container.read(activeChatProvider.notifier).set('group123');
        observer.didReplace(oldRoute: fakeRoute('/chats/group123'));
        await _flushMicrotasks();
        expect(container.read(activeChatProvider), isNull);
      });
    });

    group('didRemove', () {
      test('updates from previousRoute', () async {
        container.read(activeChatProvider.notifier).set('group123');
        observer.didRemove(fakeRoute('/chats/group123'), fakeRoute('/chats'));
        await _flushMicrotasks();
        expect(container.read(activeChatProvider), isNull);
      });

      test('sets active chat when removing reveals invite route', () async {
        observer.didRemove(fakeRoute('/settings'), fakeRoute('/invites/group789'));
        await _flushMicrotasks();
        expect(container.read(activeChatProvider), 'group789');
      });

      test('clears when previousRoute is null', () async {
        container.read(activeChatProvider.notifier).set('group123');
        observer.didRemove(fakeRoute('/chats/group123'), null);
        await _flushMicrotasks();
        expect(container.read(activeChatProvider), isNull);
      });
    });
  });
}
