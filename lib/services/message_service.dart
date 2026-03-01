import 'package:logging/logging.dart';
import 'package:whitenoise/constants/nostr_event_kinds.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart' as messages_api;
import 'package:whitenoise/src/rust/api/utils.dart' as utils_api;

final _logger = Logger('MessageService');

class MessageService {
  final String pubkey;
  final String groupId;

  const MessageService({required this.pubkey, required this.groupId});

  Future<void> sendMessage({
    required String content,
    String? replyToMessageId,
    String? replyToMessagePubkey,
    int? replyToMessageKind,
    List<MediaFile> mediaFiles = const [],
  }) async {
    _logger.info(
      'sendMessage START groupId=$groupId contentLen=${content.length} '
      'replyTo=$replyToMessageId mediaCount=${mediaFiles.length}',
    );

    try {
      final replyTags =
          (replyToMessageId != null && replyToMessagePubkey != null && replyToMessageKind != null)
          ? await _eventReferenceTags(
              eventId: replyToMessageId,
              eventPubkey: replyToMessagePubkey,
              eventKind: replyToMessageKind,
            )
          : <messages_api.Tag>[];

      final mediaTags = await _buildMediaTags(mediaFiles: mediaFiles);
      final allTags = [...replyTags, ...mediaTags];

      _logger.info('sendMessage calling Rust API tagsCount=${allTags.length}');

      final result = await messages_api.sendMessageToGroup(
        pubkey: pubkey,
        groupId: groupId,
        message: content,
        kind: NostrEventKinds.chatMessage,
        tags: allTags.isEmpty ? null : allTags,
      );

      _logger.info(
        'sendMessage OK resultId=${result.id} pubkey=${result.pubkey} kind=${result.kind} '
        'createdAt=${result.createdAt.toIso8601String()}',
      );
    } catch (e, st) {
      _logger.severe('sendMessage FAILED groupId=$groupId', e, st);
      rethrow;
    }
  }

  Future<void> sendTextMessage({
    required String content,
    String? replyToMessageId,
    String? replyToMessagePubkey,
    int? replyToMessageKind,
  }) async {
    _logger.info(
      'sendTextMessage START groupId=$groupId contentLen=${content.length} replyTo=$replyToMessageId',
    );

    try {
      final tags =
          (replyToMessageId != null && replyToMessagePubkey != null && replyToMessageKind != null)
          ? await _eventReferenceTags(
              eventId: replyToMessageId,
              eventPubkey: replyToMessagePubkey,
              eventKind: replyToMessageKind,
            )
          : null;

      _logger.info('sendTextMessage calling Rust API hasTags=${tags != null}');

      final result = await messages_api.sendMessageToGroup(
        pubkey: pubkey,
        groupId: groupId,
        message: content,
        kind: NostrEventKinds.chatMessage,
        tags: tags,
      );

      _logger.info(
        'sendTextMessage OK resultId=${result.id} createdAt=${result.createdAt.toIso8601String()}',
      );
    } catch (e, st) {
      _logger.severe('sendTextMessage FAILED groupId=$groupId', e, st);
      rethrow;
    }
  }

  Future<void> sendReaction({
    required String messageId,
    required String messagePubkey,
    required int messageKind,
    required String emoji,
  }) async {
    _logger.info(
      'sendReaction START groupId=$groupId messageId=$messageId emoji=$emoji kind=$messageKind',
    );
    try {
      final tags = await _eventReferenceTags(
        eventId: messageId,
        eventPubkey: messagePubkey,
        eventKind: messageKind,
      );

      _logger.info('sendReaction calling Rust API');
      final result = await messages_api.sendMessageToGroup(
        pubkey: pubkey,
        groupId: groupId,
        message: emoji,
        kind: NostrEventKinds.reaction,
        tags: tags,
      );
      _logger.info(
        'sendReaction OK resultId=${result.id} createdAt=${result.createdAt.toIso8601String()}',
      );
    } catch (e, st) {
      _logger.severe(
        'sendReaction FAILED groupId=$groupId messageId=$messageId emoji=$emoji',
        e,
        st,
      );
      rethrow;
    }
  }

  Future<void> toggleReaction({
    required messages_api.ChatMessage message,
    required String emoji,
  }) async {
    final existingReaction = message.reactions.userReactions
        .where((r) => r.user == pubkey && r.emoji == emoji)
        .firstOrNull;

    _logger.info(
      'toggleReaction groupId=$groupId messageId=${message.id} emoji=$emoji '
      'existing=${existingReaction?.reactionId}',
    );

    if (existingReaction != null) {
      await deleteReaction(
        reactionId: existingReaction.reactionId,
        reactionPubkey: pubkey,
      );
    } else {
      await sendReaction(
        messageId: message.id,
        messagePubkey: message.pubkey,
        messageKind: message.kind,
        emoji: emoji,
      );
    }
  }

  Future<void> deleteTextMessage({
    required String messageId,
    required String messagePubkey,
  }) async {
    await _deleteEvent(
      eventId: messageId,
      eventPubkey: messagePubkey,
      eventKind: NostrEventKinds.chatMessage,
    );
  }

  Future<void> deleteReaction({
    required String reactionId,
    required String reactionPubkey,
  }) async {
    await _deleteEvent(
      eventId: reactionId,
      eventPubkey: reactionPubkey,
      eventKind: NostrEventKinds.reaction,
    );
  }

  Future<void> _deleteEvent({
    required String eventId,
    required String eventPubkey,
    required int eventKind,
  }) async {
    _logger.info(
      '_deleteEvent START groupId=$groupId eventId=$eventId eventKind=$eventKind',
    );
    try {
      final tags = await _eventReferenceTags(
        eventId: eventId,
        eventPubkey: eventPubkey,
        eventKind: eventKind,
      );

      _logger.info('_deleteEvent calling Rust API tagsCount=${tags.length}');
      final result = await messages_api.sendMessageToGroup(
        pubkey: pubkey,
        groupId: groupId,
        message: '',
        tags: tags,
        kind: NostrEventKinds.deletion,
      );
      _logger.info(
        '_deleteEvent OK resultId=${result.id} createdAt=${result.createdAt.toIso8601String()}',
      );
    } catch (e, st) {
      _logger.severe('_deleteEvent FAILED groupId=$groupId eventId=$eventId', e, st);
      rethrow;
    }
  }

  Future<List<messages_api.Tag>> _eventReferenceTags({
    required String eventId,
    required String eventPubkey,
    required int eventKind,
  }) {
    return Future.wait([
      utils_api.tagFromVec(vec: ['e', eventId]),
      utils_api.tagFromVec(vec: ['p', eventPubkey, '']),
      utils_api.tagFromVec(vec: ['k', eventKind.toString()]),
    ]);
  }

  Future<List<messages_api.Tag>> _buildMediaTags({
    required List<MediaFile> mediaFiles,
  }) {
    return Future.wait(
      mediaFiles.map((file) => _buildMediaTag(mediaFile: file)),
    );
  }

  // MIP-04: https://github.com/marmot-protocol/marmot/blob/master/04.md
  Future<messages_api.Tag> _buildMediaTag({
    required MediaFile mediaFile,
  }) async {
    final metadata = mediaFile.fileMetadata;
    final tags = [
      'imeta',
      'url ${mediaFile.blossomUrl}',
      'm ${mediaFile.mimeType}',
      'filename ${metadata?.originalFilename ?? ''}',
    ];
    if (mediaFile.originalFileHash != null) {
      tags.add('x ${mediaFile.originalFileHash}');
    }
    if (metadata?.blurhash != null) {
      tags.add('blurhash ${metadata?.blurhash}');
    }
    if (metadata?.dimensions != null) {
      tags.add('dim ${metadata?.dimensions}');
    }
    if (mediaFile.nonce != null) {
      tags.add('n ${mediaFile.nonce!}');
    }
    if (mediaFile.schemeVersion != null) {
      tags.add('v ${mediaFile.schemeVersion}');
    }
    return await utils_api.tagFromVec(vec: tags);
  }
}
