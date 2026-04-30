import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/widgets/wn_filter_chip.dart';

class ChatListFilters extends StatelessWidget {
  const ChatListFilters({
    super.key,
    required this.isChatsSelected,
    required this.isArchiveSelected,
    required this.onChatsSelected,
    required this.onArchiveSelected,
  });

  final bool isChatsSelected;
  final bool isArchiveSelected;
  final ValueChanged<bool> onChatsSelected;
  final ValueChanged<bool> onArchiveSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      key: const Key('filter_chips_row'),
      children: [
        WnFilterChip(
          key: const Key('filter_chip_chats'),
          label: l10n.filterChats,
          selected: isChatsSelected,
          onSelected: onChatsSelected,
        ),
        SizedBox(width: 8.w),
        WnFilterChip(
          key: const Key('filter_chip_archive'),
          label: l10n.filterArchive,
          selected: isArchiveSelected,
          onSelected: onArchiveSelected,
        ),
      ],
    );
  }
}
