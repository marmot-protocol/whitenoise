import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_chat_list.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/chat_search.dart';
import 'package:whitenoise/widgets/chat_list_header.dart';
import 'package:whitenoise/widgets/chat_list_tile.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_chat_list.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_search_and_filters.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

const _slateHeight = 80;
const _searchAndFiltersHeight = 68;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final pubkey = ref.watch(accountPubkeyProvider);
    final chatListResult = useChatList(pubkey);
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final notice = useSystemNotice();
    final searchQuery = useState('');
    final welcomeNoticeDismissed = useState(false);

    useEffect(() {
      welcomeNoticeDismissed.value = false;
      return null;
    }, [pubkey]);

    final chatList = chatListResult.chats;
    final filteredChats = filterChatsBySearch(chatList, searchQuery.value);
    final isLoading = chatListResult.isLoading;
    final isEmpty = chatList.isEmpty && !isLoading;
    final showWelcomeNotice = isEmpty && !welcomeNoticeDismissed.value;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Stack(
        children: [
          if (showWelcomeNotice)
            Center(
              key: const Key('welcome_slogan'),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Text(
                  '${context.l10n.sloganDecentralized}, '
                  '${context.l10n.sloganUncensorable.toLowerCase()},\n'
                  '${context.l10n.sloganSecureMessaging.toLowerCase()}.',
                  style: typography.medium16.copyWith(
                    color: colors.backgroundContentTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          WnChatList(
            itemCount: filteredChats.length,
            isLoading: isLoading,
            isSearchActive: searchQuery.value.isNotEmpty,
            topPadding: safeAreaTop + _slateHeight.h,
            header: WnSearchAndFilters(
              onSearchChanged: (value) => searchQuery.value = value,
            ),
            headerHeight: _searchAndFiltersHeight.h,
            showEmptyState: !showWelcomeNotice && !isLoading,
            itemBuilder: (context, index) {
              final chatSummary = filteredChats[index];
              return ChatListTile(
                key: Key(chatSummary.mlsGroupId),
                chatSummary: chatSummary,
                onChatListChanged: chatListResult.refresh,
                onError: notice.showErrorNotice,
              );
            },
          ),
          SafeArea(
            bottom: false,
            child: WnSlate(
              systemNotice: showWelcomeNotice
                  ? WnSystemNotice(
                      key: const Key('welcome_notice'),
                      title: context.l10n.welcomeNoticeTitle,
                      description: _buildWelcomeDescription(
                        context,
                        typography,
                        colors,
                      ),
                      type: WnSystemNoticeType.neutral,
                      variant: WnSystemNoticeVariant.dismissible,
                      animateEntrance: false,
                      onDismiss: () {
                        if (context.mounted) {
                          welcomeNoticeDismissed.value = true;
                        }
                      },
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
                    )
                  : null,
              header: const ChatListHeader(),
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
