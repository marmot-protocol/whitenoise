import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_list_item_controller.dart';
import 'package:whitenoise/hooks/use_network_relays.dart';
import 'package:whitenoise/hooks/use_system_notice.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_confirmation_slate.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_list.dart';
import 'package:whitenoise/widgets/wn_list_item.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_system_notice.dart' show WnSystemNotice;
import 'package:whitenoise/widgets/wn_tooltip.dart';

class NetworkScreen extends HookConsumerWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final pubkey = ref.watch(accountPubkeyProvider);
    final (:state, :fetchAll, :addRelay, :removeRelay, :restoreDefaultRelays) = useNetworkRelays(
      pubkey,
    );
    final listItemController = useListItemController();
    final (:noticeMessage, :noticeType, :showErrorNotice, :showSuccessNotice, :dismissNotice) =
        useSystemNotice();

    useEffect(() {
      fetchAll();
      return null;
    }, const []);

    void showAddRelaySheet(RelayCategory category) {
      Routes.pushToAddRelay(
        context,
        category: category,
        onRelayAdded: (url) => addRelay(url, category),
      );
    }

    Widget buildSectionHeader({
      required String title,
      required String helpMessage,
      required Key infoIconKey,
      WnTooltipPosition tooltipPosition = WnTooltipPosition.top,
    }) {
      return Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: typography.semiBold16.copyWith(
                color: colors.backgroundContentSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Gap(2.w),
          WnTooltip(
            message: helpMessage,
            position: tooltipPosition,
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: WnIcon(
                WnIcons.help,
                key: infoIconKey,
                color: colors.backgroundContentSecondary,
                size: 18.w,
              ),
            ),
          ),
        ],
      );
    }

    Widget buildRelayList(RelayListState relayState, RelayCategory category) {
      if (relayState.isLoading && relayState.relays.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (relayState.error != null && relayState.relays.isEmpty) {
        return Center(
          child: Text(
            context.l10n.errorLoadingRelays,
            style: typography.medium14.copyWith(color: colors.fillDestructive),
          ),
        );
      }

      if (relayState.relays.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text(
              context.l10n.noRelaysConfigured,
              style: typography.medium14.copyWith(
                color: colors.backgroundContentTertiary,
              ),
            ),
          ),
        );
      }

      return WnList(
        children: relayState.relays.map((relay) {
          return WnListItem(
            key: Key('relay_item_${category.name}_${relay.url}'),
            title: relay.url,
            actions: [
              WnListItemAction(
                label: context.l10n.remove,
                onTap: () => removeRelay(relay.url, category),
                isDestructive: true,
              ),
            ],
          );
        }).toList(),
      );
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: WnSlate(
          showTopScrollEffect: true,
          showBottomScrollEffect: true,
          header: WnSlateNavigationHeader(
            title: context.l10n.networkRelaysTitle,
            onNavigate: () => Routes.goBack(context),
          ),
          systemNotice: noticeMessage != null
              ? WnSystemNotice(
                  key: ValueKey(noticeMessage),
                  title: noticeMessage,
                  type: noticeType,
                  onDismiss: dismissNotice,
                )
              : null,
          footer: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
            child: SizedBox(
              width: double.infinity,
              child: WnButton(
                key: const Key('restore_default_relays_button'),
                text: context.l10n.restoreDefaultRelays,
                size: WnButtonSize.medium,
                trailingIcon: WnIcons.reset,
                onPressed: () => WnConfirmationSlate.show(
                  context: context,
                  title: context.l10n.restoreDefaultRelaysConfirmationTitle,
                  message: context.l10n.restoreDefaultRelaysConfirmationMessage,
                  confirmText: context.l10n.restoreDefaultRelays,
                  cancelText: context.l10n.cancel,
                  isDestructive: true,
                  onConfirmAsync: () async {
                    try {
                      await restoreDefaultRelays();
                      return true;
                    } catch (_) {
                      if (context.mounted) {
                        showErrorNotice(context.l10n.restoreDefaultRelaysError);
                      }
                      return false;
                    }
                  },
                ),
              ),
            ),
          ),
          child: WnListItemScope(
            controller: listItemController,
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 0),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) {
                    listItemController.collapse();
                  }
                  return false;
                },
                child: GestureDetector(
                  onTap: listItemController.collapse,
                  behavior: HitTestBehavior.translucent,
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      RepaintBoundary(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildSectionHeader(
                              title: context.l10n.myRelays,
                              helpMessage: context.l10n.myRelaysHelp,
                              infoIconKey: const Key('info_icon_my_relays'),
                              tooltipPosition: WnTooltipPosition.bottom,
                            ),
                            Gap(8.h),
                            buildRelayList(state.normalRelays, RelayCategory.normal),
                            Gap(4.h),
                            SizedBox(
                              width: double.infinity,
                              child: WnButton(
                                key: const Key('add_button_my_relays'),
                                text: context.l10n.addMyRelay,
                                type: WnButtonType.overlay,
                                size: WnButtonSize.medium,
                                trailingIcon: WnIcons.addLarge,
                                onPressed: () => showAddRelaySheet(RelayCategory.normal),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Gap(16.h),
                      RepaintBoundary(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildSectionHeader(
                              title: context.l10n.inboxRelays,
                              helpMessage: context.l10n.inboxRelaysHelp,
                              infoIconKey: const Key('info_icon_inbox_relays'),
                            ),
                            Gap(8.h),
                            buildRelayList(state.inboxRelays, RelayCategory.inbox),
                            Gap(4.h),
                            SizedBox(
                              width: double.infinity,
                              child: WnButton(
                                key: const Key('add_button_inbox_relays'),
                                text: context.l10n.addInboxRelay,
                                type: WnButtonType.overlay,
                                size: WnButtonSize.medium,
                                trailingIcon: WnIcons.addLarge,
                                onPressed: () => showAddRelaySheet(RelayCategory.inbox),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Gap(16.h),
                      RepaintBoundary(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildSectionHeader(
                              title: context.l10n.keyPackageRelays,
                              helpMessage: context.l10n.keyPackageRelaysHelp,
                              infoIconKey: const Key('info_icon_key_package_relays'),
                            ),
                            Gap(8.h),
                            buildRelayList(
                              state.keyPackageRelays,
                              RelayCategory.keyPackage,
                            ),
                            Gap(4.h),
                            SizedBox(
                              width: double.infinity,
                              child: WnButton(
                                key: const Key('add_button_key_package_relays'),
                                text: context.l10n.addKeyPackageRelay,
                                type: WnButtonType.overlay,
                                size: WnButtonSize.medium,
                                trailingIcon: WnIcons.addLarge,
                                onPressed: () => showAddRelaySheet(RelayCategory.keyPackage),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
