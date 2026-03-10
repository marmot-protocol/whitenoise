import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whitenoise/hooks/use_list_item_controller.dart';
import 'package:whitenoise/hooks/use_network_relays.dart';
import 'package:whitenoise/l10n/l10n.dart';
import 'package:whitenoise/providers/account_pubkey_provider.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/widgets/wn_add_relay_bottom_sheet.dart';
import 'package:whitenoise/widgets/wn_icon.dart';
import 'package:whitenoise/widgets/wn_icon_button.dart';
import 'package:whitenoise/widgets/wn_list.dart';
import 'package:whitenoise/widgets/wn_list_item.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';
import 'package:whitenoise/widgets/wn_tooltip.dart';

class NetworkScreen extends HookConsumerWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final pubkey = ref.watch(accountPubkeyProvider);
    final (:state, :fetchAll, :addRelay, :removeRelay) = useNetworkRelays(pubkey);
    final listItemController = useListItemController();

    useEffect(() {
      fetchAll();
      return null;
    }, const []);

    void showAddRelaySheet(RelayCategory category) {
      WnAddRelayBottomSheet.show(
        context: context,
        onRelayAdded: (url) => addRelay(url, category),
      );
    }

    Widget buildSectionHeader({
      required String title,
      required String helpMessage,
      required Key infoIconKey,
      required Key addIconKey,
      required VoidCallback onAdd,
      WnTooltipPosition tooltipPosition = WnTooltipPosition.top,
    }) {
      return Row(
        children: [
          Expanded(
            child: Row(
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
                Gap(8.w),
                WnTooltip(
                  message: helpMessage,
                  position: tooltipPosition,
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: WnIcon(
                      WnIcons.information,
                      key: infoIconKey,
                      color: colors.backgroundContentSecondary,
                      size: 18.w,
                    ),
                  ),
                ),
              ],
            ),
          ),
          WnIconButton(
            key: addIconKey,
            icon: WnIcons.addCircle,
            onPressed: onAdd,
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
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            showTopScrollEffect: true,
            showBottomScrollEffect: true,
            header: WnSlateNavigationHeader(
              title: context.l10n.networkRelaysTitle,
              type: WnSlateNavigationType.back,
              onNavigate: () => Routes.goBack(context),
            ),
            child: WnListItemScope(
              controller: listItemController,
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                child: Column(
                  children: [
                    Expanded(
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
                            padding: EdgeInsets.only(top: 16.h),
                            children: [
                              RepaintBoundary(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    buildSectionHeader(
                                      title: context.l10n.myRelays,
                                      helpMessage: context.l10n.myRelaysHelp,
                                      infoIconKey: const Key('info_icon_my_relays'),
                                      addIconKey: const Key('add_icon_my_relays'),
                                      onAdd: () => showAddRelaySheet(RelayCategory.normal),
                                      tooltipPosition: WnTooltipPosition.bottom,
                                    ),
                                    Gap(12.h),
                                    buildRelayList(state.normalRelays, RelayCategory.normal),
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
                                      addIconKey: const Key('add_icon_inbox_relays'),
                                      onAdd: () => showAddRelaySheet(RelayCategory.inbox),
                                    ),
                                    Gap(12.h),
                                    buildRelayList(state.inboxRelays, RelayCategory.inbox),
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
                                      addIconKey: const Key('add_icon_key_package_relays'),
                                      onAdd: () => showAddRelaySheet(RelayCategory.keyPackage),
                                    ),
                                    Gap(12.h),
                                    buildRelayList(
                                      state.keyPackageRelays,
                                      RelayCategory.keyPackage,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
