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
    _logger.info('Sending message to group $groupId');

    final replyTags =
        (replyToMessageId != null && replyToMessagePubkey != null && replyToMessageKind != null)
        ? await _eventReferenceTags(
            eventId: replyToMessageId,
            eventPubkey: replyToMessagePubkey,
            eventKind: replyToMessageKind,
          )
        : <messages_api.Tag>[];

    final mediaTags = await _buildMediaTags(mediaFiles);
    final allTags = [...replyTags, ...mediaTags];

    await messages_api.sendMessageToGroup(
      pubkey: pubkey,
      groupId: groupId,
      message: content,
      kind: NostrEventKinds.chatMessage,
      tags: allTags.isEmpty ? null : allTags,
    );
    _logger.info('Message sent successfully');
  }

  Future<void> sendTextMessage({
    required String content,
    String? replyToMessageId,
    String? replyToMessagePubkey,
    int? replyToMessageKind,
  }) async {
    _logger.info('Sending text message to group $groupId');

    final tags =
        (replyToMessageId != null && replyToMessagePubkey != null && replyToMessageKind != null)
        ? await _eventReferenceTags(
            eventId: replyToMessageId,
            eventPubkey: replyToMessagePubkey,
            eventKind: replyToMessageKind,
          )
        : null;

    await messages_api.sendMessageToGroup(
      pubkey: pubkey,
      groupId: groupId,
      message: content,
      kind: NostrEventKinds.chatMessage,
      tags: tags,
    );
    _logger.info('Message sent successfully');
  }

  Future<void> sendReaction({
    required String messageId,
    required String messagePubkey,
    required int messageKind,
    required String emoji,
  }) async {
    final tags = await _eventReferenceTags(
      eventId: messageId,
      eventPubkey: messagePubkey,
      eventKind: messageKind,
    );

    _logger.info('Sending reaction to message $messageId');
    await messages_api.sendMessageToGroup(
      pubkey: pubkey,
      groupId: groupId,
      message: emoji,
      kind: NostrEventKinds.reaction,
      tags: tags,
    );
    _logger.info('Reaction sent successfully');
  }

  Future<void> toggleReaction({
    required messages_api.ChatMessage message,
    required String emoji,
  }) async {
    final existingReaction = message.reactions.userReactions
        .where((r) => r.user == pubkey && r.emoji == emoji)
        .firstOrNull;

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
    _logger.info('Building deletion tags for event $eventId');
    final tags = await _eventReferenceTags(
      eventId: eventId,
      eventPubkey: eventPubkey,
      eventKind: eventKind,
    );

    _logger.info('Deleting event $eventId');
    await messages_api.sendMessageToGroup(
      pubkey: pubkey,
      groupId: groupId,
      message: '',
      tags: tags,
      kind: NostrEventKinds.deletion,
    );
    _logger.info('Event $eventId deleted successfully');
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

  Future<List<messages_api.Tag>> _buildMediaTags(List<MediaFile> files) {
    return Future.wait(
      files.map((f) {
        final metadata = f.fileMetadata;
        final parts = [
          'imeta',
          'url ${f.blossomUrl}',
          'm ${f.mimeType}',
          'x ${f.originalFileHash}',
          'filename ${metadata?.originalFilename ?? ''}',
          'v mip04-v1',
        ];
        if (metadata?.blurhash != null) {
          parts.add('blurhash ${metadata!.blurhash}');
        }
        if (metadata?.dimensions != null) {
          parts.add('dim ${metadata!.dimensions}');
        }
        return utils_api.tagFromVec(vec: parts);
      }),
    );
  }
}
