import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/constants/notification_server.dart';

void main() {
  group('notification server constants', () {
    test('notificationServerPubkey is a 64-character hex string', () {
      expect(notificationServerPubkey.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(notificationServerPubkey), isTrue);
    });

    test('notificationServerRelayHint is nullable', () {
      expect(notificationServerRelayHint, isNull);
    });
  });
}
