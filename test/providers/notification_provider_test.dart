import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/l10n/generated/app_localizations_en.dart';
import 'package:whitenoise/providers/notification_provider.dart';
import 'package:whitenoise/src/rust/api/notifications.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('Notification formatting', () {
    test('formats DM new message correctly', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: 'receiver123'),
        sender: const NotificationUser(pubkey: 'sender123', displayName: 'Alice'),
        content: 'Hello there',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(update, l10n);

      expect(title, equals('Alice'));
      expect(body, equals('Hello there'));
      expect(isInvite, isFalse);
    });

    test('formats group new message correctly', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        groupName: 'Friends Group',
        isDm: false,
        receiver: const NotificationUser(pubkey: 'receiver123'),
        sender: const NotificationUser(pubkey: 'sender123', displayName: 'Bob'),
        content: 'Hey everyone',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(update, l10n);

      expect(title, equals('Friends Group'));
      expect(body, equals('Bob: Hey everyone'));
      expect(isInvite, isFalse);
    });

    test('formats DM invite correctly', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: 'receiver123'),
        sender: const NotificationUser(pubkey: 'sender123', displayName: 'Carol'),
        content: '',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(update, l10n);

      expect(title, equals('Carol'));
      expect(body, equals('Has invited you to a secure chat'));
      expect(isInvite, isTrue);
    });

    test('formats group invite correctly', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: 'group123',
        groupName: 'New Project',
        isDm: false,
        receiver: const NotificationUser(pubkey: 'receiver123'),
        sender: const NotificationUser(pubkey: 'sender123', displayName: 'Dave'),
        content: '',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(update, l10n);

      expect(title, equals('New Project'));
      expect(body, equals('Dave has invited you to a secure chat'));
      expect(isInvite, isTrue);
    });

    test('uses Unknown user for sender without display name', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: 'receiver123'),
        sender: const NotificationUser(pubkey: 'sender123'),
        content: 'Anonymous message',
        timestamp: DateTime.now(),
      );

      final (title, _, _) = formatNotification(update, l10n);

      expect(title, equals('Unknown user'));
    });

    test('uses Unknown group for group without name', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        isDm: false,
        receiver: const NotificationUser(pubkey: 'receiver123'),
        sender: const NotificationUser(pubkey: 'sender123', displayName: 'Eve'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      final (title, _, _) = formatNotification(update, l10n);

      expect(title, equals('Unknown group'));
    });

    test('uses Unknown group for group invite without name', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: 'group123',
        isDm: false,
        receiver: const NotificationUser(pubkey: 'receiver123'),
        sender: const NotificationUser(pubkey: 'sender123', displayName: 'Frank'),
        content: '',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(update, l10n);

      expect(title, equals('Unknown group'));
      expect(body, equals('Frank has invited you to a secure chat'));
      expect(isInvite, isTrue);
    });

    test('uses Unknown user for DM invite without sender name', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: 'receiver123'),
        sender: const NotificationUser(pubkey: 'sender123'),
        content: '',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(update, l10n);

      expect(title, equals('Unknown user'));
      expect(body, equals('Has invited you to a secure chat'));
      expect(isInvite, isTrue);
    });
  });

  group('Notification formatting with receiver name (multi-account)', () {
    test('appends receiver name to DM message title', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: 'receiver123', displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: 'sender123', displayName: 'Alice'),
        content: 'Hello there',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(
        update,
        l10n,
        receiverName: 'MyAccount',
      );

      expect(title, equals('Alice (MyAccount)'));
      expect(body, equals('Hello there'));
      expect(isInvite, isFalse);
    });

    test('appends receiver name to group message title', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        groupName: 'Friends Group',
        isDm: false,
        receiver: const NotificationUser(pubkey: 'receiver123', displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: 'sender123', displayName: 'Bob'),
        content: 'Hey everyone',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(
        update,
        l10n,
        receiverName: 'MyAccount',
      );

      expect(title, equals('Friends Group (MyAccount)'));
      expect(body, equals('Bob: Hey everyone'));
      expect(isInvite, isFalse);
    });

    test('appends receiver name to DM invite title', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: 'receiver123', displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: 'sender123', displayName: 'Carol'),
        content: '',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(
        update,
        l10n,
        receiverName: 'MyAccount',
      );

      expect(title, equals('Carol (MyAccount)'));
      expect(body, equals('Has invited you to a secure chat'));
      expect(isInvite, isTrue);
    });

    test('appends receiver name to group invite title', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.groupInvite,
        mlsGroupId: 'group123',
        groupName: 'New Project',
        isDm: false,
        receiver: const NotificationUser(pubkey: 'receiver123', displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: 'sender123', displayName: 'Dave'),
        content: '',
        timestamp: DateTime.now(),
      );

      final (title, body, isInvite) = formatNotification(
        update,
        l10n,
        receiverName: 'MyAccount',
      );

      expect(title, equals('New Project (MyAccount)'));
      expect(body, equals('Dave has invited you to a secure chat'));
      expect(isInvite, isTrue);
    });

    test('does not append receiver name when not provided', () {
      final update = NotificationUpdate(
        trigger: NotificationTrigger.newMessage,
        mlsGroupId: 'group123',
        isDm: true,
        receiver: const NotificationUser(pubkey: 'receiver123', displayName: 'MyAccount'),
        sender: const NotificationUser(pubkey: 'sender123', displayName: 'Alice'),
        content: 'Hello',
        timestamp: DateTime.now(),
      );

      final (title, _, _) = formatNotification(update, l10n);

      expect(title, equals('Alice'));
    });
  });
}
