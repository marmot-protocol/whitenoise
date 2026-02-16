import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/constants/nostr_event_kinds.dart';
import 'package:whitenoise/services/android_signer_service.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_android_signer_channel.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _SignerCallbackCaptureMock extends MockWnApi {
  FutureOr<String> Function(String)? signEventCallback;
  FutureOr<String> Function(String, String)? nip04EncryptCallback;
  FutureOr<String> Function(String, String)? nip04DecryptCallback;
  FutureOr<String> Function(String, String)? nip44EncryptCallback;
  FutureOr<String> Function(String, String)? nip44DecryptCallback;

  @override
  Future<LoginResult> crateApiSignerLoginExternalSignerStart({
    required String pubkey,
    required FutureOr<String> Function(String) signEvent,
    required FutureOr<String> Function(String, String) nip04Encrypt,
    required FutureOr<String> Function(String, String) nip04Decrypt,
    required FutureOr<String> Function(String, String) nip44Encrypt,
    required FutureOr<String> Function(String, String) nip44Decrypt,
  }) async {
    signEventCallback = signEvent;
    nip04EncryptCallback = nip04Encrypt;
    nip04DecryptCallback = nip04Decrypt;
    nip44EncryptCallback = nip44Encrypt;
    nip44DecryptCallback = nip44Decrypt;
    return LoginResult(
      account: Account(
        pubkey: pubkey,
        accountType: AccountType.external_,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      status: LoginStatus.complete,
    );
  }

  @override
  Future<void> crateApiSignerRegisterExternalSigner({
    required String pubkey,
    required FutureOr<String> Function(String) signEvent,
    required FutureOr<String> Function(String, String) nip04Encrypt,
    required FutureOr<String> Function(String, String) nip04Decrypt,
    required FutureOr<String> Function(String, String) nip44Encrypt,
    required FutureOr<String> Function(String, String) nip44Decrypt,
  }) async {
    registerExternalSignerCalled = true;
    signEventCallback = signEvent;
    nip04EncryptCallback = nip04Encrypt;
    nip04DecryptCallback = nip04Decrypt;
    nip44EncryptCallback = nip44Encrypt;
    nip44DecryptCallback = nip44Decrypt;
  }
}

void main() {
  group('AndroidSignerException', () {
    test('toString returns formatted string', () {
      const exception = AndroidSignerException('TEST_CODE', 'Test message');
      expect(exception.toString(), 'AndroidSignerException(TEST_CODE): Test message');
    });

    test('exposes code and message', () {
      const exception = AndroidSignerException('USER_REJECTED', 'User rejected');
      expect(exception.code, 'USER_REJECTED');
      expect(exception.message, 'User rejected');
    });
  });

  group('AndroidSignerResponse', () {
    test('fromMap creates response with all fields', () {
      final response = AndroidSignerResponse.fromMap({
        'result': 'test_result',
        'package': 'org.parres.whitenoise.signer',
        'event': '{"id":"abc"}',
        'id': 'request_id',
      });

      expect(response.result, 'test_result');
      expect(response.packageName, 'org.parres.whitenoise.signer');
      expect(response.event, '{"id":"abc"}');
      expect(response.id, 'request_id');
    });

    test('fromMap handles null fields', () {
      final response = AndroidSignerResponse.fromMap({});

      expect(response.result, isNull);
      expect(response.packageName, isNull);
      expect(response.event, isNull);
      expect(response.id, isNull);
    });

    test('toString returns formatted string', () {
      const response = AndroidSignerResponse(
        result: 'test_result',
        packageName: 'org.parres.whitenoise.signer',
        id: 'req_id',
      );

      expect(
        response.toString(),
        'AndroidSignerResponse(result: test_result, package: org.parres.whitenoise.signer, id: req_id)',
      );
    });
  });

  group('SignerPermission', () {
    test('toJson includes type', () {
      const permission = SignerPermission(type: 'sign_event');
      expect(permission.toJson(), {'type': 'sign_event'});
    });

    test('toJson includes kind when provided', () {
      final permission = const SignerPermission(
        type: 'sign_event',
        kind: NostrEventKinds.mlsKeyPackage,
      );
      expect(permission.toJson(), {'type': 'sign_event', 'kind': NostrEventKinds.mlsKeyPackage});
    });
  });

  group('AndroidSignerService', () {
    late MockAndroidSignerChannel mockAndroidSigner;
    late _SignerCallbackCaptureMock signerMock;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      signerMock = _SignerCallbackCaptureMock();
      RustLib.initMock(api: signerMock);
    });

    setUp(() {
      mockAndroidSigner = mockAndroidSignerChannel();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDown(() {
      mockAndroidSigner.reset();
      debugDefaultTargetPlatformOverride = null;
    });

    group('isAvailable', () {
      group('on ios', () {
        setUp(() {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        });

        test('returns false', () async {
          const service = AndroidSignerService();
          final result = await service.isAvailable();
          expect(result, isFalse);
        });
      });

      group('when signer is available', () {
        setUp(() {
          mockAndroidSigner.setResult('isExternalSignerInstalled', true);
        });

        test('returns true', () async {
          const androidSignerService = AndroidSignerService();
          expect(await androidSignerService.isAvailable(), isTrue);
        });
      });

      group('when signer is not available', () {
        group('when signer returns null', () {
          setUp(() {
            mockAndroidSigner.setResult('isExternalSignerInstalled', null);
          });

          test('returns false', () async {
            const androidSignerService = AndroidSignerService();
            expect(await androidSignerService.isAvailable(), isFalse);
          });
        });

        group('when signer throws Platform error', () {
          setUp(() {
            mockAndroidSigner.setException(
              'isExternalSignerInstalled',
              PlatformException(code: 'ERROR', message: 'Signer check failed'),
            );
          });

          test('returns false', () async {
            const androidSignerService = AndroidSignerService();
            expect(await androidSignerService.isAvailable(), isFalse);
          });
        });

        group('when signer throws non-Platform error', () {
          setUp(() {
            mockAndroidSigner.setError(
              'isExternalSignerInstalled',
              StateError('channel failed'),
            );
          });

          test('returns false', () async {
            const androidSignerService = AndroidSignerService();
            expect(await androidSignerService.isAvailable(), isFalse);
          });
        });
      });
    });
    group('getPublicKey', () {
      test('returns pubkey when signer responds successfully', () async {
        mockAndroidSigner.setResult('getPublicKey', {
          'result': testPubkeyA,
          'package': 'com.amber.signer',
        });

        const service = AndroidSignerService();
        final pubkey = await service.getPublicKey();

        expect(pubkey, testPubkeyA);
        expect(mockAndroidSigner.log.length, 2);
        expect(mockAndroidSigner.log[0].method, 'getPublicKey');
        expect(mockAndroidSigner.log[1].method, 'setSignerPackageName');
      });

      test('sends default permissions in request', () async {
        mockAndroidSigner.setResult('getPublicKey', {'result': testPubkeyA});

        const service = AndroidSignerService();
        await service.getPublicKey();

        final permissionsJson = mockAndroidSigner.log.first.arguments['permissions'] as String?;
        expect(permissionsJson, isNotNull);
        expect(permissionsJson!, contains('sign_event'));
        expect(permissionsJson, contains('nip44_encrypt'));
        expect(permissionsJson, contains('nip44_decrypt'));
      });

      test('throws AndroidSignerException when result is null', () async {
        const service = AndroidSignerService();
        expect(
          () => service.getPublicKey(),
          throwsA(
            isA<AndroidSignerException>().having((e) => e.code, 'code', 'NO_RESPONSE'),
          ),
        );
      });

      test('throws AndroidSignerException when pubkey is empty', () async {
        mockAndroidSigner.setResult('getPublicKey', {'result': ''});

        const service = AndroidSignerService();
        expect(
          () => service.getPublicKey(),
          throwsA(
            isA<AndroidSignerException>().having((e) => e.code, 'code', 'NO_PUBKEY'),
          ),
        );
      });

      test('throws AndroidSignerException on PlatformException', () async {
        mockAndroidSigner.setException(
          'getPublicKey',
          PlatformException(code: 'USER_REJECTED', message: 'User rejected'),
        );

        const service = AndroidSignerService();
        expect(
          () => service.getPublicKey(),
          throwsA(
            isA<AndroidSignerException>().having((e) => e.code, 'code', 'USER_REJECTED'),
          ),
        );
      });
    });

    group('signEvent', () {
      test('returns response when signer responds with event', () async {
        mockAndroidSigner.setResult('signEvent', {'result': 'sig123', 'event': '{"signed":true}'});

        const service = AndroidSignerService();
        final response = await service.signEvent(eventJson: '{"test":true}');

        expect(response.result, 'sig123');
        expect(response.event, '{"signed":true}');
        expect(mockAndroidSigner.log.first.method, 'signEvent');
        expect(mockAndroidSigner.log.first.arguments['eventJson'], '{"test":true}');
      });

      test('passes currentUser and id to channel', () async {
        mockAndroidSigner.setResult('signEvent', {'result': 'sig', 'event': '{}'});

        const service = AndroidSignerService();
        await service.signEvent(
          eventJson: '{}',
          currentUser: testPubkeyA,
          id: 'req123',
        );

        expect(mockAndroidSigner.log.first.arguments['currentUser'], testPubkeyA);
        expect(mockAndroidSigner.log.first.arguments['id'], 'req123');
      });

      test('throws AndroidSignerException when result is null', () async {
        const service = AndroidSignerService();
        expect(
          () => service.signEvent(eventJson: '{}'),
          throwsA(
            isA<AndroidSignerException>().having((e) => e.code, 'code', 'NO_RESPONSE'),
          ),
        );
      });

      test('throws AndroidSignerException when no signature or event', () async {
        mockAndroidSigner.setResult('signEvent', {'result': '', 'event': ''});

        const service = AndroidSignerService();
        expect(
          () => service.signEvent(eventJson: '{}'),
          throwsA(
            isA<AndroidSignerException>().having((e) => e.code, 'code', 'NO_RESULT'),
          ),
        );
      });

      test('throws AndroidSignerException on PlatformException', () async {
        mockAndroidSigner.setException(
          'signEvent',
          PlatformException(code: 'USER_REJECTED', message: 'User rejected'),
        );

        const service = AndroidSignerService();
        expect(
          () => service.signEvent(eventJson: '{}'),
          throwsA(isA<AndroidSignerException>()),
        );
      });
    });

    group('nip04Encrypt', () {
      test('returns encrypted text on success', () async {
        mockAndroidSigner.setResult('nip04Encrypt', {'result': 'encrypted_text'});

        const service = AndroidSignerService();
        final result = await service.nip04Encrypt(
          plaintext: 'hello',
          pubkey: testPubkeyB,
        );

        expect(result, 'encrypted_text');
        expect(mockAndroidSigner.log.first.method, 'nip04Encrypt');
        expect(mockAndroidSigner.log.first.arguments['plaintext'], 'hello');
        expect(mockAndroidSigner.log.first.arguments['pubkey'], testPubkeyB);
      });

      test('throws AndroidSignerException when result is null', () async {
        const service = AndroidSignerService();
        expect(
          () => service.nip04Encrypt(plaintext: 'hello', pubkey: testPubkeyB),
          throwsA(
            isA<AndroidSignerException>().having((e) => e.code, 'code', 'NO_RESPONSE'),
          ),
        );
      });

      test('throws AndroidSignerException when result is empty', () async {
        mockAndroidSigner.setResult('nip04Encrypt', {'result': ''});

        const service = AndroidSignerService();
        expect(
          () => service.nip04Encrypt(plaintext: 'hello', pubkey: testPubkeyB),
          throwsA(
            isA<AndroidSignerException>().having((e) => e.code, 'code', 'NO_RESULT'),
          ),
        );
      });

      test('throws AndroidSignerException on PlatformException', () async {
        mockAndroidSigner.setException(
          'nip04Encrypt',
          PlatformException(code: 'ERROR', message: 'Failed'),
        );

        const service = AndroidSignerService();
        expect(
          () => service.nip04Encrypt(plaintext: 'hello', pubkey: testPubkeyB),
          throwsA(isA<AndroidSignerException>()),
        );
      });
    });

    group('nip04Decrypt', () {
      test('returns decrypted text on success', () async {
        mockAndroidSigner.setResult('nip04Decrypt', {'result': 'decrypted_text'});

        const service = AndroidSignerService();
        final result = await service.nip04Decrypt(
          encryptedText: 'encrypted',
          pubkey: testPubkeyB,
        );

        expect(result, 'decrypted_text');
        expect(mockAndroidSigner.log.first.method, 'nip04Decrypt');
      });

      test('throws AndroidSignerException when result is null', () async {
        const service = AndroidSignerService();
        expect(
          () => service.nip04Decrypt(encryptedText: 'enc', pubkey: testPubkeyB),
          throwsA(
            isA<AndroidSignerException>().having((e) => e.code, 'code', 'NO_RESPONSE'),
          ),
        );
      });

      test('throws AndroidSignerException when result is empty', () async {
        mockAndroidSigner.setResult('nip04Decrypt', {'result': ''});

        const service = AndroidSignerService();
        expect(
          () => service.nip04Decrypt(encryptedText: 'enc', pubkey: testPubkeyB),
          throwsA(
            isA<AndroidSignerException>().having((e) => e.code, 'code', 'NO_RESULT'),
          ),
        );
      });

      test('throws AndroidSignerException on PlatformException', () async {
        mockAndroidSigner.setException(
          'nip04Decrypt',
          PlatformException(code: 'ERROR', message: 'Failed'),
        );

        const service = AndroidSignerService();
        expect(
          () => service.nip04Decrypt(encryptedText: 'enc', pubkey: testPubkeyB),
          throwsA(isA<AndroidSignerException>()),
        );
      });
    });

    group('nip44Encrypt', () {
      test('returns encrypted text on success', () async {
        mockAndroidSigner.setResult('nip44Encrypt', {'result': 'encrypted_nip44'});

        const service = AndroidSignerService();
        final result = await service.nip44Encrypt(
          plaintext: 'hello',
          pubkey: testPubkeyB,
        );

        expect(result, 'encrypted_nip44');
        expect(mockAndroidSigner.log.first.method, 'nip44Encrypt');
      });

      test('throws AndroidSignerException when result is null', () async {
        const service = AndroidSignerService();
        expect(
          () => service.nip44Encrypt(plaintext: 'hello', pubkey: testPubkeyB),
          throwsA(
            isA<AndroidSignerException>().having((e) => e.code, 'code', 'NO_RESPONSE'),
          ),
        );
      });

      test('throws AndroidSignerException when result is empty', () async {
        mockAndroidSigner.setResult('nip44Encrypt', {'result': ''});

        const service = AndroidSignerService();
        expect(
          () => service.nip44Encrypt(plaintext: 'hello', pubkey: testPubkeyB),
          throwsA(
            isA<AndroidSignerException>().having((e) => e.code, 'code', 'NO_RESULT'),
          ),
        );
      });

      test('throws AndroidSignerException on PlatformException', () async {
        mockAndroidSigner.setException(
          'nip44Encrypt',
          PlatformException(code: 'ERROR', message: 'Failed'),
        );

        const service = AndroidSignerService();
        expect(
          () => service.nip44Encrypt(plaintext: 'hello', pubkey: testPubkeyB),
          throwsA(isA<AndroidSignerException>()),
        );
      });
    });

    group('nip44Decrypt', () {
      test('returns decrypted text on success', () async {
        mockAndroidSigner.setResult('nip44Decrypt', {'result': 'decrypted_nip44'});

        const service = AndroidSignerService();
        final result = await service.nip44Decrypt(
          encryptedText: 'encrypted',
          pubkey: testPubkeyB,
        );

        expect(result, 'decrypted_nip44');
        expect(mockAndroidSigner.log.first.method, 'nip44Decrypt');
      });

      test('throws AndroidSignerException when result is null', () async {
        const service = AndroidSignerService();
        expect(
          () => service.nip44Decrypt(encryptedText: 'enc', pubkey: testPubkeyB),
          throwsA(
            isA<AndroidSignerException>().having((e) => e.code, 'code', 'NO_RESPONSE'),
          ),
        );
      });

      test('throws AndroidSignerException when result is empty', () async {
        mockAndroidSigner.setResult('nip44Decrypt', {'result': ''});

        const service = AndroidSignerService();
        expect(
          () => service.nip44Decrypt(encryptedText: 'enc', pubkey: testPubkeyB),
          throwsA(
            isA<AndroidSignerException>().having((e) => e.code, 'code', 'NO_RESULT'),
          ),
        );
      });

      test('throws AndroidSignerException on PlatformException', () async {
        mockAndroidSigner.setException(
          'nip44Decrypt',
          PlatformException(code: 'ERROR', message: 'Failed'),
        );

        const service = AndroidSignerService();
        expect(
          () => service.nip44Decrypt(encryptedText: 'enc', pubkey: testPubkeyB),
          throwsA(isA<AndroidSignerException>()),
        );
      });
    });

    group('getSignerPackageName', () {
      test('returns package name on success', () async {
        mockAndroidSigner.setResult('getSignerPackageName', 'com.amber.signer');

        const service = AndroidSignerService();
        final result = await service.getSignerPackageName();

        expect(result, 'com.amber.signer');
        expect(mockAndroidSigner.log.first.method, 'getSignerPackageName');
      });

      test('returns null on PlatformException', () async {
        mockAndroidSigner.setException(
          'getSignerPackageName',
          PlatformException(code: 'ERROR', message: 'Failed'),
        );

        const service = AndroidSignerService();
        final result = await service.getSignerPackageName();

        expect(result, isNull);
      });
    });

    group('setSignerPackageName', () {
      test('calls channel with package name', () async {
        const service = AndroidSignerService();
        await service.setSignerPackageName('com.amber.signer');

        expect(mockAndroidSigner.log.first.method, 'setSignerPackageName');
        expect(mockAndroidSigner.log.first.arguments['packageName'], 'com.amber.signer');
      });

      test('handles PlatformException gracefully', () async {
        mockAndroidSigner.setException(
          'setSignerPackageName',
          PlatformException(code: 'ERROR', message: 'Failed'),
        );

        const service = AndroidSignerService();
        await service.setSignerPackageName('com.amber.signer');
      });
    });

    group('loginExternalSignerStart', () {
      setUp(() {
        mockAndroidSigner = mockAndroidSignerChannel();
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
      });

      tearDown(() {
        mockAndroidSigner.reset();
        debugDefaultTargetPlatformOverride = null;
      });

      test('returns LoginResult when signer responds successfully', () async {
        final result = await const AndroidSignerService().loginExternalSignerStart(testPubkeyA);
        expect(result.account.pubkey, testPubkeyA);
        expect(result.status, LoginStatus.complete);
      });

      test('signEvent callback returns signed event when signer returns event', () async {
        mockAndroidSigner.setResult('signEvent', {'event': 'signed_event_json'});
        await const AndroidSignerService().loginExternalSignerStart(testPubkeyA);
        final result = await signerMock.signEventCallback!('{}');
        expect(result, 'signed_event_json');
      });

      test(
        'signEvent callback throws NO_EVENT when signer returns signature but no event',
        () async {
          mockAndroidSigner.setResult('signEvent', {'result': 'sig_without_event'});
          await const AndroidSignerService().loginExternalSignerStart(testPubkeyA);
          expect(
            () => signerMock.signEventCallback!('{}'),
            throwsA(
              isA<AndroidSignerException>().having(
                (e) => e.code,
                'code',
                'NO_EVENT',
              ),
            ),
          );
        },
      );

      test('signEvent callback throws NO_RESULT when signer returns empty event', () async {
        mockAndroidSigner.setResult('signEvent', {'event': ''});
        await const AndroidSignerService().loginExternalSignerStart(testPubkeyA);
        expect(
          () => signerMock.signEventCallback!('{}'),
          throwsA(isA<AndroidSignerException>().having((e) => e.code, 'code', 'NO_RESULT')),
        );
      });

      test('nip04Encrypt callback returns ciphertext from signer', () async {
        mockAndroidSigner.setResult('nip04Encrypt', {'result': 'encrypted'});
        await const AndroidSignerService().loginExternalSignerStart(testPubkeyA);
        final result = await signerMock.nip04EncryptCallback!('plain', testPubkeyB);
        expect(result, 'encrypted');
      });

      test('nip04Decrypt callback returns plaintext from signer', () async {
        mockAndroidSigner.setResult('nip04Decrypt', {'result': 'decrypted'});
        await const AndroidSignerService().loginExternalSignerStart(testPubkeyA);
        final result = await signerMock.nip04DecryptCallback!('cipher', testPubkeyB);
        expect(result, 'decrypted');
      });

      test('nip44Encrypt callback returns ciphertext from signer', () async {
        mockAndroidSigner.setResult('nip44Encrypt', {'result': 'enc44'});
        await const AndroidSignerService().loginExternalSignerStart(testPubkeyA);
        final result = await signerMock.nip44EncryptCallback!('plain', testPubkeyB);
        expect(result, 'enc44');
      });

      test('nip44Decrypt callback returns plaintext from signer', () async {
        mockAndroidSigner.setResult('nip44Decrypt', {'result': 'dec44'});
        await const AndroidSignerService().loginExternalSignerStart(testPubkeyA);
        final result = await signerMock.nip44DecryptCallback!('cipher', testPubkeyB);
        expect(result, 'dec44');
      });
    });

    group('loginExternalSignerPublishDefaultRelays', () {
      test('returns LoginResult with complete status', () async {
        final result = await const AndroidSignerService().loginExternalSignerPublishDefaultRelays(
          testPubkeyA,
        );
        expect(result.account.pubkey, testPubkeyA);
        expect(result.status, LoginStatus.complete);
      });
    });

    group('loginExternalSignerWithCustomRelay', () {
      test('returns LoginResult with complete status', () async {
        final result = await const AndroidSignerService().loginExternalSignerWithCustomRelay(
          testPubkeyA,
          'wss://relay.example.com',
        );
        expect(result.account.pubkey, testPubkeyA);
        expect(result.status, LoginStatus.complete);
      });
    });

    group('registerExternalSigner', () {
      setUp(() {
        mockAndroidSigner = mockAndroidSignerChannel();
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        signerMock.registerExternalSignerCalled = false;
      });

      tearDown(() {
        mockAndroidSigner.reset();
        debugDefaultTargetPlatformOverride = null;
      });

      test('calls Rust API registerExternalSigner with callbacks', () async {
        await const AndroidSignerService().registerExternalSigner(testPubkeyA);
        expect(signerMock.registerExternalSignerCalled, isTrue);
        expect(signerMock.signEventCallback, isNotNull);
      });

      test('signEvent callback uses channel and returns signed event', () async {
        mockAndroidSigner.setResult('signEvent', {'event': 'signed_event_json'});
        await const AndroidSignerService().registerExternalSigner(testPubkeyA);
        final result = await signerMock.signEventCallback!('{}');
        expect(result, 'signed_event_json');
      });
    });
  });
}
