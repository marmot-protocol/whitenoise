import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/widgets/chat_list_filters.dart';
import 'package:whitenoise/widgets/wn_search_field.dart';

class ChatListSearchAndFilters extends HookWidget {
  const ChatListSearchAndFilters({
    super.key,
    this.onSearchChanged,
    this.isLoading = false,
    this.showFilterChips = false,
    this.isChatsSelected = false,
    this.isArchiveSelected = false,
    this.onChatsSelected,
    this.onArchiveSelected,
  });

  final ValueChanged<String>? onSearchChanged;
  final bool isLoading;
  final bool showFilterChips;
  final bool isChatsSelected;
  final bool isArchiveSelected;
  final ValueChanged<bool>? onChatsSelected;
  final ValueChanged<bool>? onArchiveSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searchController = useTextEditingController();

    final onSearchChangedRef = useRef(onSearchChanged);
    onSearchChangedRef.value = onSearchChanged;

    useEffect(() {
      void listener() {
        onSearchChangedRef.value?.call(searchController.text);
      }

      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Column(
        key: const Key('search_and_filters'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WnSearchField(
            placeholder: l10n.search,
            controller: searchController,
            isLoading: isLoading,
          ),
          if (showFilterChips) ...[
            SizedBox(height: 8.h),
            ChatListFilters(
              isChatsSelected: isChatsSelected,
              isArchiveSelected: isArchiveSelected,
              onChatsSelected: (value) => onChatsSelected?.call(value),
              onArchiveSelected: (value) => onArchiveSelected?.call(value),
            ),
          ],
        ],
      ),
    );
  }
}
