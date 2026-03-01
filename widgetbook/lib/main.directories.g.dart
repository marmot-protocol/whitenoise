// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:whitenoise_widgetbook/components/buttons.dart'
    as _whitenoise_widgetbook_components_buttons;
import 'package:whitenoise_widgetbook/components/carousel_indicator.dart'
    as _whitenoise_widgetbook_components_carousel_indicator;
import 'package:whitenoise_widgetbook/components/chat_info_actions.dart'
    as _whitenoise_widgetbook_components_chat_info_actions;
import 'package:whitenoise_widgetbook/components/chat_info_profile_card.dart'
    as _whitenoise_widgetbook_components_chat_info_profile_card;
import 'package:whitenoise_widgetbook/components/chat_list_item.dart'
    as _whitenoise_widgetbook_components_chat_list_item;
import 'package:whitenoise_widgetbook/components/chat_message_input.dart'
    as _whitenoise_widgetbook_components_chat_message_input;
import 'package:whitenoise_widgetbook/components/chat_status.dart'
    as _whitenoise_widgetbook_components_chat_status;
import 'package:whitenoise_widgetbook/components/feedback.dart'
    as _whitenoise_widgetbook_components_feedback;
import 'package:whitenoise_widgetbook/components/filter_chip.dart'
    as _whitenoise_widgetbook_components_filter_chip;
import 'package:whitenoise_widgetbook/components/icon_button.dart'
    as _whitenoise_widgetbook_components_icon_button;
import 'package:whitenoise_widgetbook/components/icons.dart'
    as _whitenoise_widgetbook_components_icons;
import 'package:whitenoise_widgetbook/components/inputs.dart'
    as _whitenoise_widgetbook_components_inputs;
import 'package:whitenoise_widgetbook/components/key_package_card.dart'
    as _whitenoise_widgetbook_components_key_package_card;
import 'package:whitenoise_widgetbook/components/list.dart'
    as _whitenoise_widgetbook_components_list;
import 'package:whitenoise_widgetbook/components/media_preview.dart'
    as _whitenoise_widgetbook_components_media_preview;
import 'package:whitenoise_widgetbook/components/media_thumbnail.dart'
    as _whitenoise_widgetbook_components_media_thumbnail;
import 'package:whitenoise_widgetbook/components/menu.dart'
    as _whitenoise_widgetbook_components_menu;
import 'package:whitenoise_widgetbook/components/message_bubble.dart'
    as _whitenoise_widgetbook_components_message_bubble;
import 'package:whitenoise_widgetbook/components/message_media.dart'
    as _whitenoise_widgetbook_components_message_media;
import 'package:whitenoise_widgetbook/components/message_quote.dart'
    as _whitenoise_widgetbook_components_message_quote;
import 'package:whitenoise_widgetbook/components/reaction.dart'
    as _whitenoise_widgetbook_components_reaction;
import 'package:whitenoise_widgetbook/components/spinner.dart'
    as _whitenoise_widgetbook_components_spinner;
import 'package:whitenoise_widgetbook/components/structure.dart'
    as _whitenoise_widgetbook_components_structure;
import 'package:whitenoise_widgetbook/components/timestamp.dart'
    as _whitenoise_widgetbook_components_timestamp;
import 'package:whitenoise_widgetbook/components/tooltip.dart'
    as _whitenoise_widgetbook_components_tooltip;
import 'package:whitenoise_widgetbook/components/wn_avatar.dart'
    as _whitenoise_widgetbook_components_wn_avatar;
import 'package:whitenoise_widgetbook/components/wn_copy_card.dart'
    as _whitenoise_widgetbook_components_wn_copy_card;
import 'package:whitenoise_widgetbook/components/wn_profile_switcher_item.dart'
    as _whitenoise_widgetbook_components_wn_profile_switcher_item;
import 'package:whitenoise_widgetbook/components/wn_slate_headers.dart'
    as _whitenoise_widgetbook_components_wn_slate_headers;
import 'package:whitenoise_widgetbook/components/wn_user_item.dart'
    as _whitenoise_widgetbook_components_wn_user_item;
import 'package:whitenoise_widgetbook/foundations/semantic_colors.dart'
    as _whitenoise_widgetbook_foundations_semantic_colors;
import 'package:whitenoise_widgetbook/foundations/typography.dart'
    as _whitenoise_widgetbook_foundations_typography;
import 'package:whitenoise_widgetbook/introduction.dart'
    as _whitenoise_widgetbook_introduction;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookComponent(
    name: 'Introduction',
    useCases: [
      _widgetbook.WidgetbookUseCase(
        name: 'Resources',
        builder: _whitenoise_widgetbook_introduction.introduction,
      ),
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'components',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'WnAvatarStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Avatar',
            builder:
                _whitenoise_widgetbook_components_wn_avatar.wnAvatarShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnButtonStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Button',
            builder: _whitenoise_widgetbook_components_buttons.wnButtonShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnCalloutStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Callout',
            builder:
                _whitenoise_widgetbook_components_feedback.wnCalloutShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnCarouselIndicatorStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Carousel Indicator',
            builder: _whitenoise_widgetbook_components_carousel_indicator
                .wnCarouselIndicatorShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnChatInfoActionsStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Chat Info Actions',
            builder: _whitenoise_widgetbook_components_chat_info_actions
                .wnChatInfoActionsShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnChatInfoProfileCardStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Chat Info Profile Card',
            builder: _whitenoise_widgetbook_components_chat_info_profile_card
                .wnChatInfoProfileCardShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnChatListItemStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Chat List Item',
            builder: _whitenoise_widgetbook_components_chat_list_item
                .wnChatListItemShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnChatMessageInputStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Chat Message Input',
            builder: _whitenoise_widgetbook_components_chat_message_input
                .wnChatMessageInputShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnChatStatusStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Chat Status',
            builder: _whitenoise_widgetbook_components_chat_status
                .wnChatStatusShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnCopyCardStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Copy Card',
            builder: _whitenoise_widgetbook_components_wn_copy_card
                .wnCopyCardShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnFilterChipStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Filter Chip',
            builder: _whitenoise_widgetbook_components_filter_chip
                .wnFilterChipShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnIconStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Icons',
            builder: _whitenoise_widgetbook_components_icons.wnIconShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnInputPasswordStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Password Input',
            builder: _whitenoise_widgetbook_components_inputs
                .wnInputPasswordShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnInputStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Text Input',
            builder: _whitenoise_widgetbook_components_inputs.wnInputShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnInputTextAreaStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Text Area',
            builder: _whitenoise_widgetbook_components_inputs
                .wnInputTextAreaShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnKeyPackageCardStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Key Package Card',
            builder: _whitenoise_widgetbook_components_key_package_card
                .wnKeyPackageCardShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnListStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'List',
            builder: _whitenoise_widgetbook_components_list.wnListShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnMediaPreviewStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Media Preview',
            builder: _whitenoise_widgetbook_components_media_preview
                .wnMediaPreviewShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnMediaThumbnailStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Media Thumbnail',
            builder: _whitenoise_widgetbook_components_media_thumbnail
                .wnMediaThumbnailShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnMenuItemStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Menu Item',
            builder: _whitenoise_widgetbook_components_menu.wnMenuItemShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnMenuStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Menu Container',
            builder: _whitenoise_widgetbook_components_menu.wnMenuShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnMessageBubbleStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Message Bubble',
            builder: _whitenoise_widgetbook_components_message_bubble
                .wnMessageBubbleShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnMessageMediaStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Message Media',
            builder: _whitenoise_widgetbook_components_message_media
                .wnMessageMediaShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnMessageQuoteStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Message Quote',
            builder: _whitenoise_widgetbook_components_message_quote
                .wnMessageQuoteShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnOverlayStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Overlay',
            builder:
                _whitenoise_widgetbook_components_structure.wnOverlayShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnProfileSwitcherItemStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Profile Switcher Item',
            builder: _whitenoise_widgetbook_components_wn_profile_switcher_item
                .wnProfileSwitcherItemShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnReactionStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Reaction',
            builder:
                _whitenoise_widgetbook_components_reaction.wnReactionShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnScrollEdgeEffectStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Scroll Edge Effect',
            builder: _whitenoise_widgetbook_components_structure
                .wnScrollEdgeEffectShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnSeparatorStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Separator',
            builder:
                _whitenoise_widgetbook_components_structure.wnSeparatorShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnSlateHeadersStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Slate Headers',
            builder: _whitenoise_widgetbook_components_wn_slate_headers
                .wnSlateHeadersShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnSpinnerStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Spinner',
            builder:
                _whitenoise_widgetbook_components_spinner.wnSpinnerShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnTimestampStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Timestamp',
            builder:
                _whitenoise_widgetbook_components_timestamp.wnTimestampShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnTooltipStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Tooltip',
            builder:
                _whitenoise_widgetbook_components_tooltip.wnTooltipShowcase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'WnUserItemStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'User Item',
            builder: _whitenoise_widgetbook_components_wn_user_item
                .wnUserItemShowcase,
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'foundations',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'SemanticColorsStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Semantic Colors',
            builder:
                _whitenoise_widgetbook_foundations_semantic_colors.allColors,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'TypographyStory',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Typography',
            builder:
                _whitenoise_widgetbook_foundations_typography.allTypography,
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'widgets',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'WnIconButton',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Icon Button',
            builder: _whitenoise_widgetbook_components_icon_button
                .wnIconButtonShowcase,
          ),
        ],
      ),
    ],
  ),
];
