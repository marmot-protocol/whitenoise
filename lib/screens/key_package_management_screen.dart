import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show HookWidget, useEffect, useState;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_key_packages.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' show FlutterEvent;
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_key_package_card.dart';
import 'package:whitenoise/widgets/wn_scroll_edge_effect.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart';

class KeyPackageManagementScreen extends HookConsumerWidget {
  const KeyPackageManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final pubkey = ref.watch(accountPubkeyProvider);
    final (:state, :fetch, :publish, :delete, :deleteAll) = useKeyPackages(pubkey);

    final noticeMessage = useState<String?>(null);
    final noticeType = useState<WnSystemNoticeType>(WnSystemNoticeType.success);

    void showNotice(String message, {bool isError = false}) {
      noticeMessage.value = message;
      noticeType.value = isError ? WnSystemNoticeType.error : WnSystemNoticeType.success;
    }

    void dismissNotice() {
      noticeMessage.value = null;
    }

    String getSuccessMessage(KeyPackageAction action) {
      return switch (action) {
        KeyPackageAction.fetch => context.l10n.keyPackagesRefreshed,
        KeyPackageAction.publish => context.l10n.keyPackagePublished,
        KeyPackageAction.delete => context.l10n.keyPackageDeleted,
        KeyPackageAction.deleteAll => context.l10n.keyPackagesDeleted,
      };
    }

    String getErrorMessage(KeyPackageAction action) {
      return switch (action) {
        KeyPackageAction.fetch => context.l10n.keyPackageFetchFailed,
        KeyPackageAction.publish => context.l10n.keyPackagePublishFailed,
        KeyPackageAction.delete => context.l10n.keyPackageDeleteFailed,
        KeyPackageAction.deleteAll => context.l10n.keyPackageDeleteAllFailed,
      };
    }

    Future<void> handleAction(Future<KeyPackageResult> Function() action) async {
      final result = await action();
      if (!context.mounted) return;
      if (result.success) {
        showNotice(getSuccessMessage(result.action));
      } else {
        showNotice(getErrorMessage(result.action), isError: true);
      }
    }

    Future<void> handleDelete(String id) => handleAction(() => delete(id));

    useEffect(() {
      fetch().then((result) {
        if (!context.mounted) return;
        if (!result.success) {
          showNotice(getErrorMessage(result.action), isError: true);
        }
      });
      return null;
    }, [pubkey]);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            header: WnSlateNavigationHeader(
              title: context.l10n.keyPackageManagementTitle,
              onNavigate: () => Routes.goBack(context),
            ),
            systemNotice: noticeMessage.value != null
                ? WnSystemNotice(
                    key: ValueKey(noticeMessage.value),
                    title: noticeMessage.value!,
                    type: noticeType.value,
                    onDismiss: dismissNotice,
                  )
                : null,
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  _KeyPackageActionButtons(
                    isLoading: state.isLoading,
                    activeAction: state.activeAction,
                    onPublish: () => handleAction(publish),
                    onFetch: () => handleAction(fetch),
                    onDeleteAll: () => handleAction(deleteAll),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    context.l10n.keyPackagesCount(state.packages.length),
                    style: typography.semiBold14.copyWith(
                      color: colors.backgroundContentPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: _KeyPackageList(
                      packages: state.packages,
                      onDelete: handleDelete,
                      disabled: state.isLoading,
                      deletingId: state.deletingId,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyPackageActionButtons extends StatelessWidget {
  const _KeyPackageActionButtons({
    required this.isLoading,
    required this.activeAction,
    required this.onPublish,
    required this.onFetch,
    required this.onDeleteAll,
  });

  final bool isLoading;
  final KeyPackageAction? activeAction;
  final VoidCallback onPublish;
  final VoidCallback onFetch;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8.h,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WnButton(
          text: context.l10n.refreshKeyPackages,
          onPressed: onFetch,
          disabled: isLoading,
          loading: activeAction == KeyPackageAction.fetch,
          type: WnButtonType.outline,
          size: WnButtonSize.medium,
        ),
        WnButton(
          text: context.l10n.publishNewKeyPackage,
          onPressed: onPublish,
          disabled: isLoading,
          loading: activeAction == KeyPackageAction.publish,
          size: WnButtonSize.medium,
        ),
        WnButton(
          text: context.l10n.deleteAllKeyPackages,
          onPressed: onDeleteAll,
          disabled: isLoading,
          loading: activeAction == KeyPackageAction.deleteAll,
          type: WnButtonType.destructive,
          size: WnButtonSize.medium,
        ),
      ],
    );
  }
}

class _KeyPackageList extends HookWidget {
  const _KeyPackageList({
    required this.packages,
    required this.onDelete,
    required this.disabled,
    required this.deletingId,
  });

  final List<FlutterEvent> packages;
  final void Function(String id) onDelete;
  final bool disabled;
  final String? deletingId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final canScrollUp = useState(false);
    final canScrollDown = useState(false);

    void updateScrollState(ScrollMetrics metrics) {
      canScrollUp.value = metrics.extentBefore > 0;
      canScrollDown.value = metrics.extentAfter > 0;
    }

    if (packages.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noKeyPackagesFound,
          style: typography.medium14.copyWith(
            color: colors.backgroundContentTertiary,
          ),
        ),
      );
    }

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        updateScrollState(notification.metrics);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          updateScrollState(notification.metrics);
          return false;
        },
        child: Stack(
          children: [
            ListView.separated(
              itemCount: packages.length,
              separatorBuilder: (_, _) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final package = packages[index];
                final isDeleting = deletingId == package.id;
                return WnKeyPackageCard(
                  key: Key('key_package_card_${package.id}'),
                  title: context.l10n.packageNumber(index + 1),
                  packageId: package.id,
                  createdAt: package.createdAt.toIso8601String(),
                  onDelete: () => onDelete(package.id),
                  deleteLabel: context.l10n.delete,
                  disabled: disabled || isDeleting,
                  loading: isDeleting,
                  deleteButtonKey: Key('delete_key_package_${package.id}'),
                );
              },
            ),
            if (canScrollUp.value) WnScrollEdgeEffect.slateTop(color: colors.backgroundSecondary),
            if (canScrollDown.value)
              WnScrollEdgeEffect.slateBottom(color: colors.backgroundSecondary),
          ],
        ),
      ),
    );
  }
}
