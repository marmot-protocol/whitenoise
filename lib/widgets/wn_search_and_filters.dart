import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/widgets/wn_search_field.dart';

class WnSearchAndFilters extends HookWidget {
  const WnSearchAndFilters({
    super.key,
    this.onSearchChanged,
    this.isLoading = false,
  });

  final ValueChanged<String>? onSearchChanged;
  final bool isLoading;

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
        ],
      ),
    );
  }
}
