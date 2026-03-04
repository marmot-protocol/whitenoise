import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/routes.dart';
import 'package:whitenoise/theme.dart';
import 'package:whitenoise/utils/app_flavor.dart';
import 'package:whitenoise/widgets/wn_button.dart';
import 'package:whitenoise/widgets/wn_input.dart';
import 'package:whitenoise/widgets/wn_separator.dart';
import 'package:whitenoise/widgets/wn_slate.dart';
import 'package:whitenoise/widgets/wn_slate_navigation_header.dart';

class RouteBrowserScreen extends HookWidget {
  const RouteBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    final addToGroupPubkeyController = useTextEditingController();
    final startChatPubkeyController = useTextEditingController();
    final chatInfoPubkeyController = useTextEditingController();
    final groupInfoGroupIdController = useTextEditingController();
    final editGroupGroupIdController = useTextEditingController();
    final groupMemberGroupIdController = useTextEditingController();
    final groupMemberPubkeyController = useTextEditingController();
    final inviteGroupIdController = useTextEditingController();
    final chatGroupIdController = useTextEditingController();
    final chatRawDebugGroupIdController = useTextEditingController();

    final relayPubkeyController = useTextEditingController();
    final relayExternalSigner = useState(false);

    final publicRoutes = <_StaticRouteItem>[
      _StaticRouteItem(
        title: 'Home',
        path: '/',
        onOpen: () => Routes.pushToHome(context),
      ),
      _StaticRouteItem(
        title: 'Login',
        path: '/login',
        onOpen: () => Routes.pushToLogin(context),
        note: 'When authenticated, redirect rules may send you to /chats.',
      ),
      _StaticRouteItem(
        title: 'Scan Nsec',
        path: '/scan-nsec',
        onOpen: () {
          Routes.pushToScanNsec(context);
        },
      ),
      _StaticRouteItem(
        title: 'Signup',
        path: '/signup',
        onOpen: () => Routes.pushToSignup(context),
        note: 'When authenticated, redirect rules may send you to /chats.',
      ),
    ];

    final authenticatedStaticRoutes = <_StaticRouteItem>[
      _StaticRouteItem(
        title: 'Scan Npub',
        path: '/scan-npub',
        onOpen: () => Routes.pushToScanNpub(context),
      ),
      _StaticRouteItem(
        title: 'Chat List',
        path: '/chats',
        onOpen: () => Routes.pushToChatList(context),
      ),
      _StaticRouteItem(
        title: 'Settings',
        path: '/settings',
        onOpen: () => Routes.pushToSettings(context),
      ),
      _StaticRouteItem(
        title: 'Donate',
        path: '/donate',
        onOpen: () => Routes.pushToDonate(context),
      ),
      _StaticRouteItem(
        title: 'Appearance',
        path: '/appearance',
        onOpen: () => Routes.pushToAppearance(context),
      ),
      _StaticRouteItem(
        title: 'Privacy & Security',
        path: '/privacy-security',
        onOpen: () => Routes.pushToPrivacySecurity(context),
      ),
      _StaticRouteItem(
        title: 'WIP',
        path: '/wip',
        onOpen: () => Routes.pushToWip(context),
      ),
      _StaticRouteItem(
        title: 'Developer Settings',
        path: '/developer-settings',
        onOpen: () => Routes.pushToDeveloperSettings(context),
      ),
      if (isStaging)
        _StaticRouteItem(
          title: 'App Logs',
          path: '/app-logs',
          onOpen: () => Routes.pushToAppLogs(context),
        ),
      if (isStaging)
        _StaticRouteItem(
          title: 'Debug SQL Query',
          path: '/debug-sql-query',
          onOpen: () => Routes.pushToDebugSqlQuery(context),
        ),
      _StaticRouteItem(
        title: 'Profile Keys',
        path: '/profile-keys',
        onOpen: () => Routes.pushToProfileKeys(context),
      ),
      _StaticRouteItem(
        title: 'Share Profile',
        path: '/share-profile',
        onOpen: () => Routes.pushToShareProfile(context),
      ),
      _StaticRouteItem(
        title: 'Edit Profile',
        path: '/edit-profile',
        onOpen: () => Routes.pushToEditProfile(context),
      ),
      _StaticRouteItem(
        title: 'Sign Out',
        path: '/sign-out',
        onOpen: () => Routes.pushToSignOut(context),
      ),
      _StaticRouteItem(
        title: 'Switch Profile',
        path: '/switch-profile',
        onOpen: () => Routes.pushToSwitchProfile(context),
      ),
      _StaticRouteItem(
        title: 'Add Profile',
        path: '/add-profile',
        onOpen: () => Routes.pushToAddProfile(context),
      ),
      _StaticRouteItem(
        title: 'Network',
        path: '/network',
        onOpen: () => Routes.pushToNetwork(context),
      ),
      _StaticRouteItem(
        title: 'User Search',
        path: '/user-search',
        onOpen: () => Routes.pushToUserSearch(context),
      ),
      _StaticRouteItem(
        title: 'User Selection',
        path: '/user-selection',
        onOpen: () => Routes.pushToUserSelection(context),
      ),
    ];

    final parameterizedRoutes = <_ParameterizedRouteItem>[
      _ParameterizedRouteItem(
        title: 'Add To Group',
        path: '/add-to-group/:userPubkey',
        fields: [
          _RouteField(
            label: 'userPubkey',
            hint: 'hex pubkey',
            controller: addToGroupPubkeyController,
          ),
        ],
        onOpen: () => Routes.pushToAddToGroup(context, addToGroupPubkeyController.text.trim()),
      ),
      _ParameterizedRouteItem(
        title: 'Start Chat',
        path: '/start-chat/:userPubkey',
        fields: [
          _RouteField(
            label: 'userPubkey',
            hint: 'hex pubkey',
            controller: startChatPubkeyController,
          ),
        ],
        onOpen: () => Routes.pushToStartChat(context, startChatPubkeyController.text.trim()),
      ),
      _ParameterizedRouteItem(
        title: 'Chat Info',
        path: '/chat-info/:userPubkey',
        fields: [
          _RouteField(
            label: 'userPubkey',
            hint: 'hex pubkey',
            controller: chatInfoPubkeyController,
          ),
        ],
        onOpen: () {
          Routes.pushToChatInfo(context, chatInfoPubkeyController.text.trim());
        },
      ),
      _ParameterizedRouteItem(
        title: 'Group Info',
        path: '/group-info/:groupId',
        fields: [
          _RouteField(
            label: 'groupId',
            hint: 'mls group id',
            controller: groupInfoGroupIdController,
          ),
        ],
        onOpen: () => Routes.pushToGroupInfo(context, groupInfoGroupIdController.text.trim()),
      ),
      _ParameterizedRouteItem(
        title: 'Edit Group',
        path: '/edit-group/:groupId',
        fields: [
          _RouteField(
            label: 'groupId',
            hint: 'mls group id',
            controller: editGroupGroupIdController,
          ),
        ],
        onOpen: () => Routes.pushToEditGroup(context, editGroupGroupIdController.text.trim()),
      ),
      _ParameterizedRouteItem(
        title: 'Group Member',
        path: '/group-member/:groupId/:memberPubkey',
        fields: [
          _RouteField(
            label: 'groupId',
            hint: 'mls group id',
            controller: groupMemberGroupIdController,
          ),
          _RouteField(
            label: 'memberPubkey',
            hint: 'hex pubkey',
            controller: groupMemberPubkeyController,
          ),
        ],
        onOpen: () => Routes.pushToGroupMember(
          context,
          groupMemberGroupIdController.text.trim(),
          groupMemberPubkeyController.text.trim(),
        ),
      ),
      _ParameterizedRouteItem(
        title: 'Invite',
        path: '/invites/:mlsGroupId',
        fields: [
          _RouteField(
            label: 'mlsGroupId',
            hint: 'mls group id',
            controller: inviteGroupIdController,
          ),
        ],
        onOpen: () => Routes.pushToInvite(context, inviteGroupIdController.text.trim()),
      ),
      _ParameterizedRouteItem(
        title: 'Chat',
        path: '/chats/:groupId',
        fields: [
          _RouteField(
            label: 'groupId',
            hint: 'mls group id',
            controller: chatGroupIdController,
          ),
        ],
        onOpen: () => Routes.goToChat(context, chatGroupIdController.text.trim()),
      ),
      if (isStaging)
        _ParameterizedRouteItem(
          title: 'Chat Raw Debug',
          path: '/chats/:groupId/debug',
          fields: [
            _RouteField(
              label: 'groupId',
              hint: 'mls group id',
              controller: chatRawDebugGroupIdController,
            ),
          ],
          onOpen: () =>
              Routes.pushToChatRawDebug(context, chatRawDebugGroupIdController.text.trim()),
        ),
    ];

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: WnSlate(
            showTopScrollEffect: true,
            showBottomScrollEffect: true,
            header: WnSlateNavigationHeader(
              title: 'Route Browser',
              type: WnSlateNavigationType.back,
              onNavigate: () => Routes.goBack(context),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
              children: [
                Text(
                  'Open screens directly from the app route map for runtime inspection.',
                  style: typography.medium12.copyWith(
                    color: colors.backgroundContentSecondary,
                  ),
                ),
                SizedBox(height: 16.h),
                const _SectionTitle(title: 'Public Routes'),
                ...publicRoutes.map((item) => _StaticRouteCard(item: item)),
                SizedBox(height: 12.h),
                const WnSeparator(),
                SizedBox(height: 12.h),
                const _SectionTitle(title: 'Authenticated Static Routes'),
                ...authenticatedStaticRoutes.map((item) => _StaticRouteCard(item: item)),
                SizedBox(height: 12.h),
                const WnSeparator(),
                SizedBox(height: 12.h),
                const _SectionTitle(title: 'Parameterized Routes'),
                ...parameterizedRoutes.map((item) => _ParameterizedRouteCard(item: item)),
                SizedBox(height: 12.h),
                const WnSeparator(),
                SizedBox(height: 12.h),
                const _SectionTitle(title: 'Routes Requiring Extra'),
                AnimatedBuilder(
                  animation: relayPubkeyController,
                  builder: (context, _) => _ExtraRouteCard(
                    title: 'Relay Resolution',
                    path: '/relay-resolution',
                    note: 'Requires extra map { pubkey, isExternalSigner }.',
                    controls: [
                      WnInput(
                        label: 'pubkey',
                        placeholder: 'hex pubkey',
                        size: WnInputSize.size44,
                        controller: relayPubkeyController,
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: colors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: colors.borderTertiary),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                child: Text(
                                  'isExternalSigner',
                                  style: typography.medium14.copyWith(
                                    color: colors.backgroundContentPrimary,
                                  ),
                                ),
                              ),
                            ),
                            Switch(
                              value: relayExternalSigner.value,
                              onChanged: (value) => relayExternalSigner.value = value,
                              activeThumbColor: colors.backgroundContentPrimary,
                            ),
                          ],
                        ),
                      ),
                    ],
                    onOpen: relayPubkeyController.text.trim().isEmpty
                        ? null
                        : () => Routes.pushToRelayResolution(
                            context,
                            pubkey: relayPubkeyController.text.trim(),
                            isExternalSigner: relayExternalSigner.value,
                          ),
                  ),
                ),
                _ExtraRouteCard(
                  title: 'Set Up Group (Flow-only)',
                  path: '/set-up-group',
                  note:
                      'This route expects selected users in extra payload. Use helper to start from user selection.',
                  controls: const [],
                  onOpen: () => Routes.pushToUserSelection(context),
                  buttonText: 'Open Flow Helper',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: context.typographyScaled.semiBold14.copyWith(
          color: context.colors.backgroundContentPrimary,
        ),
      ),
    );
  }
}

class _StaticRouteCard extends StatelessWidget {
  const _StaticRouteCard({required this.item});

  final _StaticRouteItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: colors.borderTertiary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: typography.medium16.copyWith(
                    color: colors.backgroundContentPrimary,
                  ),
                ),
              ),
              SizedBox(
                width: 110.w,
                child: WnButton(
                  text: 'Open',
                  onPressed: item.onOpen,
                  size: WnButtonSize.xsmall,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            item.path,
            style: typography.medium12.copyWith(
              color: colors.backgroundContentSecondary,
              fontFamily: 'monospace',
            ),
          ),
          if (item.note != null) ...[
            SizedBox(height: 4.h),
            Text(
              item.note!,
              style: typography.medium12.copyWith(
                color: colors.backgroundContentTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParameterizedRouteCard extends StatelessWidget {
  const _ParameterizedRouteCard({required this.item});

  final _ParameterizedRouteItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;
    final readyListenable = Listenable.merge(
      item.fields.map((field) => field.controller).toList(),
    );

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: colors.borderTertiary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: typography.medium16.copyWith(
                    color: colors.backgroundContentPrimary,
                  ),
                ),
              ),
              SizedBox(
                width: 110.w,
                child: AnimatedBuilder(
                  animation: readyListenable,
                  builder: (context, _) {
                    final isReady = item.fields.every(
                      (field) => field.controller.text.trim().isNotEmpty,
                    );
                    return WnButton(
                      text: 'Open',
                      onPressed: isReady ? item.onOpen : null,
                      size: WnButtonSize.xsmall,
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            item.path,
            style: typography.medium12.copyWith(
              color: colors.backgroundContentSecondary,
              fontFamily: 'monospace',
            ),
          ),
          SizedBox(height: 8.h),
          ..._buildFields(context),
        ],
      ),
    );
  }

  List<Widget> _buildFields(BuildContext context) {
    return item.fields
        .expand(
          (field) => [
            WnInput(
              label: field.label,
              placeholder: field.hint,
              size: WnInputSize.size44,
              controller: field.controller,
            ),
            SizedBox(height: 8.h),
          ],
        )
        .toList();
  }
}

class _ExtraRouteCard extends StatelessWidget {
  const _ExtraRouteCard({
    required this.title,
    required this.path,
    required this.note,
    required this.controls,
    required this.onOpen,
    this.buttonText = 'Open',
  });

  final String title;
  final String path;
  final String note;
  final List<Widget> controls;
  final VoidCallback? onOpen;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typographyScaled;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: colors.borderTertiary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: typography.medium16.copyWith(
                    color: colors.backgroundContentPrimary,
                  ),
                ),
              ),
              SizedBox(
                width: 150.w,
                child: WnButton(
                  text: buttonText,
                  onPressed: onOpen,
                  size: WnButtonSize.xsmall,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            path,
            style: typography.medium12.copyWith(
              color: colors.backgroundContentSecondary,
              fontFamily: 'monospace',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            note,
            style: typography.medium12.copyWith(
              color: colors.backgroundContentTertiary,
            ),
          ),
          if (controls.isNotEmpty) ...[
            SizedBox(height: 8.h),
            ...controls,
          ],
        ],
      ),
    );
  }
}

class _StaticRouteItem {
  const _StaticRouteItem({
    required this.title,
    required this.path,
    required this.onOpen,
    this.note,
  });

  final String title;
  final String path;
  final VoidCallback onOpen;
  final String? note;
}

class _ParameterizedRouteItem {
  const _ParameterizedRouteItem({
    required this.title,
    required this.path,
    required this.fields,
    required this.onOpen,
  });

  final String title;
  final String path;
  final List<_RouteField> fields;
  final VoidCallback onOpen;
}

class _RouteField {
  const _RouteField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
}
