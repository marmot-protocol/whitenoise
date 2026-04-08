import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whitenoise/hooks/use_chat_list.dart';
import 'package:whitenoise/hooks/use_chat_list_search.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/hooks/use_zapstore_update.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/chat_search.dart';
import 'package:whitenoise/widgets/chat_list_header.dart';
import 'package:whitenoise/widgets/chat_list_tile.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_chat_list.dart';
import 'package:whitenoise/widgets/wn_filter_chip.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_search_and_filters.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

const _zapstoreUrl = 'https://zapstore.dev/apps/org.parres.whitenoise';

const _slateHeight = 80;
const _searchAndFiltersHeight = 68;
const _filterChipsHeight = 48;

enum ChatListFilter { chats, archive }

class ChatListScreen extends HookConsumerWidget {
  const ChatListScreen({super.key});

  Widget _buildWelcomeDescription(
    BuildContext context,
    AppTypography typography,
    SemanticColors colors,
  ) {
    final l10n = context.l10n;
    final baseStyle = typography.medium14.copyWith(
      color: colors.backgroundContentQuaternary,
    );
    final highlightStyle = typography.medium14.copyWith(
      color: colors.backgroundContentPrimary,
    );

    final findPeople = l10n.findPeople;
    final shareProfile = l10n.shareYourProfile;
    final startNewChat = l10n.startANewChat;

    final template = l10n.welcomeNoticeDescription(
      findPeople,
      shareProfile,
      startNewChat,
    );

    final spans = <InlineSpan>[];
    var currentIndex = 0;

    void addHighlightedText(String text) {
      final index = template.indexOf(text, currentIndex);
      if (index == -1) return;

      if (index > currentIndex) {
        spans.add(TextSpan(text: template.substring(currentIndex, index)));
      }
      spans.add(TextSpan(text: text, style: highlightStyle));
      currentIndex = index + text.length;
    }

    final highlights = [findPeople, shareProfile, startNewChat];
    final sortedHighlights = highlights.toList()
      ..sort((a, b) => template.indexOf(a).compareTo(template.indexOf(b)));

    for (final highlight in sortedHighlights) {
      addHighlightedText(highlight);
    }

    if (currentIndex < template.length) {
      spans.add(TextSpan(text: template.substring(currentIndex)));
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
    );
  }

  WnSystemNotice? _buildSystemNotice(
    BuildContext context,
    AppTypography typography,
    SemanticColors colors, {
    required bool showWelcomeNotice,
    required String? updateVersion,
    required VoidCallback onUpdateDismiss,
    required VoidCallback onWelcomeDismiss,
  }) {
    if (updateVersion != null) {
      return WnSystemNotice(
        key: ValueKey('update_notice_$updateVersion'),
        title: context.l10n.updateAvailableTitle,
        description: Text(
          context.l10n.updateAvailableDescription(updateVersion),
          style: typography.medium12.copyWith(
            color: colors.intentionInfoContent,
          ),
        ),
        type: WnSystemNoticeType.info,
        variant: WnSystemNoticeVariant.dismissible,
        onDismiss: onUpdateDismiss,
        primaryAction: WnButton(
          key: const Key('update_now_button'),
          text: context.l10n.updateNow,
          size: WnButtonSize.medium,
          onPressed: () async {
            final launched = await launchUrl(
              Uri.parse(_zapstoreUrl),
              mode: LaunchMode.externalApplication,
            );
            if (!launched && context.mounted) {
              await launchUrl(
                Uri.parse(_zapstoreUrl),
              );
            }
          },
        ),
      );
    }

    if (showWelcomeNotice) {
      return WnSystemNotice(
        key: const Key('welcome_notice'),
        title: context.l10n.welcomeNoticeTitle,
        description: _buildWelcomeDescription(context, typography, colors),
        type: WnSystemNoticeType.neutral,
        variant: WnSystemNoticeVariant.dismissible,
        animateEntrance: false,
        onDismiss: onWelcomeDismiss,
        secondaryAction: WnButton(
          key: const Key('find_people_button'),
          text: context.l10n.findPeople,
          type: WnButtonType.outline,
          size: WnButtonSize.medium,
          trailingIcon: WnIcons.search,
          onPressed: () => Routes.pushToUserSearch(context),
        ),
        primaryAction: WnButton(
          key: const Key('share_profile_button'),
          text: context.l10n.shareYourProfile,
          size: WnButtonSize.medium,
          trailingIcon: WnIcons.qrCode,
          onPressed: () => Routes.pushToShareProfile(context),
        ),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final pubkey = ref.watch(accountPubkeyProvider);
    final chatListResult = useChatList(pubkey);
    final archivedChatListResult = useChatList(pubkey, archived: true);
    final selectedFilter = useState(ChatListFilter.chats);
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final notice = useSystemNotice();
    final updateState = useZapstoreUpdate();
    final searchQuery = useState('');
    final welcomeNoticeDismissed = useState(false);
    final chatListTopPadding = useMemoized(() => ValueNotifier(safeAreaTop + _slateHeight.h));
    final chatListSearch = useChatListSearch(
      pubkey: pubkey,
      query: searchQuery.value,
    );

    useEffect(() {
      welcomeNoticeDismissed.value = false;
      return null;
    }, [pubkey]);

    final isArchiveView = selectedFilter.value == ChatListFilter.archive;
    final activeChatList = isArchiveView ? archivedChatListResult.chats : chatListResult.chats;
    final filteredChats = filterChatsBySearchWithMessageMatches(
      activeChatList,
      searchQuery.value,
      chatListSearch.matchedGroupIds,
    );
    final isLoading = isArchiveView ? archivedChatListResult.isLoading : chatListResult.isLoading;
    final isEmpty = activeChatList.isEmpty && !isLoading;
    final showWelcomeNotice = !isArchiveView && isEmpty && !welcomeNoticeDismissed.value;
    final activeUpdateVersion = updateState.isDismissed ? null : updateState.availableVersion;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Stack(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: chatListTopPadding,
            builder: (context, topPadding, _) => WnChatList(
              itemCount: filteredChats.length,
              isLoading: isLoading,
              isSearchActive: searchQuery.value.isNotEmpty,
              topPadding: topPadding,
              header: WnSearchAndFilters(
                onSearchChanged: (value) => searchQuery.value = value,
                isLoading: chatListSearch.isSearching,
              ),
              headerHeight: _searchAndFiltersHeight.h,
              pinnedHeader: Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Row(
                  key: const Key('filter_chips_row'),
                  children: [
                    WnFilterChip(
                      key: const Key('filter_chip_chats'),
                      label: context.l10n.filterChats,
                      selected: selectedFilter.value == ChatListFilter.chats,
                      onSelected: (_) => selectedFilter.value = ChatListFilter.chats,
                    ),
                    SizedBox(width: 8.w),
                    WnFilterChip(
                      key: const Key('filter_chip_archive'),
                      label: context.l10n.filterArchive,
                      selected: selectedFilter.value == ChatListFilter.archive,
                      onSelected: (_) => selectedFilter.value = ChatListFilter.archive,
                    ),
                  ],
                ),
              ),
              pinnedHeaderHeight: _filterChipsHeight.h,
              emptyStateContent: isEmpty
                  ? isArchiveView
                        ? Center(
                            key: const Key('archived_chats_empty'),
                            child: Text(
                              context.l10n.archivedChatsEmpty,
                              style: typography.medium14.copyWith(
                                color: colors.backgroundContentQuaternary,
                              ),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40.w),
                            child: Text(
                              key: const Key('welcome_slogan'),
                              context.l10n.sloganFull,
                              style: typography.medium16.copyWith(
                                color: colors.backgroundContentTertiary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                  : null,
              itemBuilder: (context, index) {
                final chatSummary = filteredChats[index];
                return ChatListTile(
                  key: Key(chatSummary.mlsGroupId),
                  chatSummary: chatSummary,
                  isArchived: isArchiveView,
                  searchSnippet: chatListSearch.messageSnippets[chatSummary.mlsGroupId],
                  onChatListChanged: isArchiveView
                      ? archivedChatListResult.refresh
                      : chatListResult.refresh,
                  onError: notice.showErrorNotice,
                );
              },
            ),
          ),
          _MeasuredSlate(
            onHeightChanged: (height) {
              if (chatListTopPadding.value != height) {
                chatListTopPadding.value = height;
              }
            },
            child: SafeArea(
              bottom: false,
              child: WnSlate(
                systemNotice: _buildSystemNotice(
                  context,
                  typography,
                  colors,
                  showWelcomeNotice: showWelcomeNotice,
                  updateVersion: activeUpdateVersion,
                  onUpdateDismiss: updateState.dismiss,
                  onWelcomeDismiss: () {
                    if (context.mounted) {
                      welcomeNoticeDismissed.value = true;
                    }
                  },
                ),
                header: const ChatListHeader(),
              ),
            ),
          ),
          if (notice.noticeMessage != null)
            SafeArea(
              bottom: false,
              child: WnSystemNotice(
                key: ValueKey(notice.noticeMessage),
                title: notice.noticeMessage!,
                type: notice.noticeType,
                onDismiss: notice.dismissNotice,
              ),
            ),
        ],
      ),
    );
  }
}

class _MeasuredSlate extends StatefulWidget {
  const _MeasuredSlate({
    required this.onHeightChanged,
    required this.child,
  });

  final ValueChanged<double> onHeightChanged;
  final Widget child;

  @override
  State<_MeasuredSlate> createState() => _MeasuredSlateState();
}

class _MeasuredSlateState extends State<_MeasuredSlate> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final box = _key.currentContext?.findRenderObject() as RenderBox?;
          if (box == null || !box.hasSize) return;
          widget.onHeightChanged(box.size.height);
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: SizedBox(key: _key, child: widget.child),
      ),
    );
  }
}
