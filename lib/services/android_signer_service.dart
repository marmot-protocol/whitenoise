import 'dart:convert';
import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/constants/nostr_event_kinds.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/signer.dart' as signer_api;

final _logger = Logger('AndroidSignerService');

// NIP-55 (https://github.com/nostr-protocol/nips/blob/master/55.md)
final _defaultSignerPermissions = [
  const SignerPermission(type: 'sign_event', kind: NostrEventKinds.mlsKeyPackage),
  const SignerPermission(type: 'sign_event', kind: NostrEventKinds.mlsWelcome),
  const SignerPermission(type: 'sign_event', kind: NostrEventKinds.mlsGroupMessage),
  const SignerPermission(type: 'sign_event', kind: NostrEventKinds.giftWrap),
  const SignerPermission(type: 'sign_event', kind: NostrEventKinds.relayListMetadata),
  const SignerPermission(type: 'sign_event', kind: NostrEventKinds.inboxRelays),
  const SignerPermission(type: 'sign_event', kind: NostrEventKinds.mlsKeyPackageRelays),
  const SignerPermission(type: 'nip44_encrypt'),
  const SignerPermission(type: 'nip44_decrypt'),
];

class AndroidSignerResponse {
  final String? result;
  final String? packageName;
  final String? event;
  final String? id;

  const AndroidSignerResponse({
    this.result,
    this.packageName,
    this.event,
    this.id,
  });

  factory AndroidSignerResponse.fromMap(Map<Object?, Object?> map) {
    return AndroidSignerResponse(
      result: map['result'] as String?,
      packageName: map['package'] as String?,
      event: map['event'] as String?,
      id: map['id'] as String?,
    );
  }

  @override
  String toString() => 'AndroidSignerResponse(result: $result, package: $packageName, id: $id)';
}

class SignerPermission {
  final String type;
  final int? kind;

  const SignerPermission({
    required this.type,
    this.kind,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'type': type};
    if (kind != null) {
      map['kind'] = kind;
    }
    return map;
  }
}

class AndroidSignerException implements Exception {
  final String code;
  final String message;

  const AndroidSignerException(this.code, this.message);

  @override
  String toString() => 'AndroidSignerException($code): $message';
}

//  Android signer service (NIP-55) (https://github.com/nostr-protocol/nips/blob/master/55.md)
class AndroidSignerService {
  static const _channel = MethodChannel('org.parres.whitenoise/android_signer');

  const AndroidSignerService();

  Future<bool> isAvailable() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isExternalSignerInstalled');
      _logger.fine('External signer available: $result');
      return result ?? false;
    } catch (e, stackTrace) {
      _logger.warning('Failed to check signer availability', e, stackTrace);
      return false;
    }
  }

  Future<String> getPublicKey() async {
    _logger.info('Requesting public key from signer');

    try {
      final args = {
        'permissions': jsonEncode(_defaultSignerPermissions.map((p) => p.toJson()).toList()),
      };

      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getPublicKey', args);
      if (result == null) {
        throw const AndroidSignerException('NO_RESPONSE', 'No response from signer');
      }

      final response = AndroidSignerResponse.fromMap(result);
      final preview = response.result?.substring(0, min(8, response.result!.length)) ?? '';
      _logger.info('Got public key from signer: $preview...');

      if (response.result == null || response.result!.isEmpty) {
        throw const AndroidSignerException('NO_PUBKEY', 'Signer did not return a public key');
      }

      await _persistSignerPackageNameIfReturned(response);

      return response.result!;
    } on PlatformException catch (e) {
      _logger.warning('Failed to get public key: ${e.code} - ${e.message}');
      throw AndroidSignerException(e.code, e.message ?? 'Unknown error');
    }
  }

  Future<AndroidSignerResponse> signEvent({
    required String eventJson,
    String? id,
    String? currentUser,
  }) async {
    _logger.info('Requesting event signature from signer');

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('signEvent', {
        'eventJson': eventJson,
        'id': id ?? '',
        'currentUser': currentUser ?? '',
      });

      if (result == null) {
        throw const AndroidSignerException('NO_RESPONSE', 'No response from signer');
      }

      final response = AndroidSignerResponse.fromMap(result);
      _validateSignerResponse(response);

      _logger.fine('Got signer response');
      return response;
    } on PlatformException catch (e) {
      _logger.warning('Failed to sign event: ${e.code} - ${e.message}');
      throw AndroidSignerException(e.code, e.message ?? 'Unknown error');
    }
  }

  Future<String> nip04Encrypt({
    required String plaintext,
    required String pubkey,
    String? currentUser,
    String? id,
  }) async {
    _logger.info('Requesting NIP-04 encryption from signer');

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('nip04Encrypt', {
        'plaintext': plaintext,
        'pubkey': pubkey,
        'currentUser': currentUser ?? '',
        'id': id ?? '',
      });

      if (result == null) {
        throw const AndroidSignerException('NO_RESPONSE', 'No response from signer');
      }

      final response = AndroidSignerResponse.fromMap(result);
      if (response.result == null || response.result!.isEmpty) {
        throw const AndroidSignerException('NO_RESULT', 'Signer did not return encrypted text');
      }

      return response.result!;
    } on PlatformException catch (e) {
      _logger.warning('Failed to encrypt (NIP-04): ${e.code} - ${e.message}');
      throw AndroidSignerException(e.code, e.message ?? 'Unknown error');
    }
  }

  Future<String> nip04Decrypt({
    required String encryptedText,
    required String pubkey,
    String? currentUser,
    String? id,
  }) async {
    _logger.info('Requesting NIP-04 decryption from signer');

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('nip04Decrypt', {
        'encryptedText': encryptedText,
        'pubkey': pubkey,
        'currentUser': currentUser ?? '',
        'id': id ?? '',
      });

      if (result == null) {
        throw const AndroidSignerException('NO_RESPONSE', 'No response from signer');
      }

      final response = AndroidSignerResponse.fromMap(result);
      if (response.result == null || response.result!.isEmpty) {
        throw const AndroidSignerException('NO_RESULT', 'Signer did not return decrypted text');
      }

      return response.result!;
    } on PlatformException catch (e) {
      _logger.warning('Failed to decrypt (NIP-04): ${e.code} - ${e.message}');
      throw AndroidSignerException(e.code, e.message ?? 'Unknown error');
    }
  }

  Future<String> nip44Encrypt({
    required String plaintext,
    required String pubkey,
    String? currentUser,
    String? id,
  }) async {
    _logger.info('Requesting NIP-44 encryption from signer');

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('nip44Encrypt', {
        'plaintext': plaintext,
        'pubkey': pubkey,
        'currentUser': currentUser ?? '',
        'id': id ?? '',
      });

      if (result == null) {
        throw const AndroidSignerException('NO_RESPONSE', 'No response from signer');
      }

      final response = AndroidSignerResponse.fromMap(result);
      if (response.result == null || response.result!.isEmpty) {
        throw const AndroidSignerException('NO_RESULT', 'Signer did not return encrypted text');
      }

      return response.result!;
    } on PlatformException catch (e) {
      _logger.warning('Failed to encrypt (NIP-44): ${e.code} - ${e.message}');
      throw AndroidSignerException(e.code, e.message ?? 'Unknown error');
    }
  }

  Future<String> nip44Decrypt({
    required String encryptedText,
    required String pubkey,
    String? currentUser,
    String? id,
  }) async {
    _logger.info('Requesting NIP-44 decryption from signer');

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('nip44Decrypt', {
        'encryptedText': encryptedText,
        'pubkey': pubkey,
        'currentUser': currentUser ?? '',
        'id': id ?? '',
      });

      if (result == null) {
        throw const AndroidSignerException('NO_RESPONSE', 'No response from signer');
      }

      final response = AndroidSignerResponse.fromMap(result);
      if (response.result == null || response.result!.isEmpty) {
        throw const AndroidSignerException('NO_RESULT', 'Signer did not return decrypted text');
      }

      return response.result!;
    } on PlatformException catch (e) {
      _logger.warning('Failed to decrypt (NIP-44): ${e.code} - ${e.message}');
      throw AndroidSignerException(e.code, e.message ?? 'Unknown error');
    }
  }

  ({
    Future<String> Function(String) signEvent,
    Future<String> Function(String, String) nip04Encrypt,
    Future<String> Function(String, String) nip04Decrypt,
    Future<String> Function(String, String) nip44Encrypt,
    Future<String> Function(String, String) nip44Decrypt,
  })
  _createSignerCallbacks(String pubkey) {
    return (
      signEvent: (unsignedEventJson) async {
        _logger.fine('Signing event via Android signer...');
        final response = await signEvent(
          eventJson: unsignedEventJson,
          currentUser: pubkey,
        );
        if (response.event == null || response.event!.isEmpty) {
          throw const AndroidSignerException(
            'NO_EVENT',
            'Signer did not return signed event',
          );
        }
        return response.event!;
      },
      nip04Encrypt: (plaintext, recipientPubkey) async {
        _logger.fine('NIP-04 encrypting via Android signer...');
        return nip04Encrypt(
          plaintext: plaintext,
          pubkey: recipientPubkey,
          currentUser: pubkey,
        );
      },
      nip04Decrypt: (ciphertext, senderPubkey) async {
        _logger.fine('NIP-04 decrypting via Android signer...');
        return nip04Decrypt(
          encryptedText: ciphertext,
          pubkey: senderPubkey,
          currentUser: pubkey,
        );
      },
      nip44Encrypt: (plaintext, recipientPubkey) async {
        _logger.fine('NIP-44 encrypting via Android signer...');
        return nip44Encrypt(
          plaintext: plaintext,
          pubkey: recipientPubkey,
          currentUser: pubkey,
        );
      },
      nip44Decrypt: (ciphertext, senderPubkey) async {
        _logger.fine('NIP-44 decrypting via Android signer...');
        return nip44Decrypt(
          encryptedText: ciphertext,
          pubkey: senderPubkey,
          currentUser: pubkey,
        );
      },
    );
  }

  Future<LoginResult> loginExternalSignerStart(String pubkey) async {
    final callbacks = _createSignerCallbacks(pubkey);
    return signer_api.loginExternalSignerStart(
      pubkey: pubkey,
      signEvent: callbacks.signEvent,
      nip04Encrypt: callbacks.nip04Encrypt,
      nip04Decrypt: callbacks.nip04Decrypt,
      nip44Encrypt: callbacks.nip44Encrypt,
      nip44Decrypt: callbacks.nip44Decrypt,
    );
  }

  Future<LoginResult> loginExternalSignerPublishDefaultRelays(String pubkey) async {
    return signer_api.loginExternalSignerPublishDefaultRelays(pubkey: pubkey);
  }

  Future<LoginResult> loginExternalSignerWithCustomRelay(
    String pubkey,
    String relayUrl,
  ) async {
    return signer_api.loginExternalSignerWithCustomRelay(
      pubkey: pubkey,
      relayUrl: relayUrl,
    );
  }

  Future<void> registerExternalSigner(String pubkey) async {
    _logger.info('Re-registering external signer for account $pubkey');
    final callbacks = _createSignerCallbacks(pubkey);
    await signer_api.registerExternalSigner(
      pubkey: pubkey,
      signEvent: callbacks.signEvent,
      nip04Encrypt: callbacks.nip04Encrypt,
      nip04Decrypt: callbacks.nip04Decrypt,
      nip44Encrypt: callbacks.nip44Encrypt,
      nip44Decrypt: callbacks.nip44Decrypt,
    );
  }

  Future<String?> getSignerPackageName() async {
    try {
      return await _channel.invokeMethod<String>('getSignerPackageName');
    } on PlatformException catch (e) {
      _logger.warning('Failed to get signer package name: ${e.message}');
      return null;
    }
  }

  Future<void> setSignerPackageName(String packageName) async {
    try {
      await _channel.invokeMethod<void>('setSignerPackageName', {
        'packageName': packageName,
      });
    } on PlatformException catch (e) {
      _logger.warning('Failed to set signer package name: ${e.message}');
    }
  }

  Future<void> _persistSignerPackageNameIfReturned(AndroidSignerResponse response) async {
    if (response.packageName != null && response.packageName!.isNotEmpty) {
      await setSignerPackageName(response.packageName!);
      _logger.fine('Saved signer package name: ${response.packageName}');
    }
  }

  void _validateSignerResponse(AndroidSignerResponse response) {
    final hasSignature = response.result != null && response.result!.isNotEmpty;
    final hasEvent = response.event != null && response.event!.isNotEmpty;
    if (!hasSignature && !hasEvent) {
      throw const AndroidSignerException(
        'NO_RESULT',
        'Signer did not return a signature or event',
      );
    }
  }
}
