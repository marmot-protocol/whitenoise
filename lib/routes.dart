import 'package:flutter/material.dart'
    show BuildContext, GlobalKey, Navigator, NavigatorState, Widget;
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;
import 'package:go_router/go_router.dart'
    show CustomTransitionPage, GoRoute, GoRouter, GoRouterState;
import 'package:whitenoise/hooks/use_route_refresh.dart' show routeObserver;
import 'package:whitenoise/observers/active_chat_route_observer.dart' show ActiveChatRouteObserver;
import 'package:whitenoise/providers/active_chat_provider.dart' show activeChatProvider;
import 'package:whitenoise/providers/auth_provider.dart' show authProvider;
import 'package:whitenoise/providers/is_adding_account_provider.dart' show isAddingAccountProvider;
import 'package:whitenoise/screens/add_profile_screen.dart' show AddProfileScreen;
import 'package:whitenoise/screens/add_to_group_screen.dart' show AddToGroupScreen;
import 'package:whitenoise/screens/appearance_screen.dart' show AppearanceScreen;
import 'package:whitenoise/screens/chat_info_screen.dart' show ChatInfoScreen;
import 'package:whitenoise/screens/chat_invite_screen.dart' show ChatInviteScreen;
import 'package:whitenoise/screens/chat_list_screen.dart' show ChatListScreen;
import 'package:whitenoise/screens/chat_screen.dart' show ChatScreen;
import 'package:whitenoise/screens/developer_settings_screen.dart' show DeveloperSettingsScreen;
import 'package:whitenoise/screens/donate_screen.dart' show DonateScreen;
import 'package:whitenoise/screens/edit_group_screen.dart' show EditGroupScreen;
import 'package:whitenoise/screens/edit_profile_screen.dart' show EditProfileScreen;
import 'package:whitenoise/screens/group_info_screen.dart' show GroupInfoScreen;
import 'package:whitenoise/screens/group_member_screen.dart' show GroupMemberScreen;
import 'package:whitenoise/screens/home_screen.dart' show HomeScreen;
import 'package:whitenoise/screens/login_screen.dart' show LoginScreen;
import 'package:whitenoise/screens/network_screen.dart' show NetworkScreen;
import 'package:whitenoise/screens/privacy_security_screen.dart' show PrivacySecurityScreen;
import 'package:whitenoise/screens/profile_keys_screen.dart' show ProfileKeysScreen;
import 'package:whitenoise/screens/relay_resolution_screen.dart' show RelayResolutionScreen;
import 'package:whitenoise/screens/scan_npub_screen.dart' show ScanNpubScreen;
import 'package:whitenoise/screens/scan_nsec_screen.dart' show ScanNsecScreen;
import 'package:whitenoise/screens/set_up_group_screen.dart' show SetUpGroupScreen;
import 'package:whitenoise/screens/settings_screen.dart' show SettingsScreen;
import 'package:whitenoise/screens/share_profile_screen.dart' show ShareProfileScreen;
import 'package:whitenoise/screens/sign_out_screen.dart' show SignOutScreen;
import 'package:whitenoise/screens/signup_screen.dart' show SignupScreen;
import 'package:whitenoise/screens/start_chat_screen.dart' show StartChatScreen;
import 'package:whitenoise/screens/switch_profile_screen.dart' show SwitchProfileScreen;
import 'package:whitenoise/screens/user_search_screen.dart' show UserSearchScreen;
import 'package:whitenoise/screens/user_selection_screen.dart' show UserSelectionScreen;
import 'package:whitenoise/screens/wip_screen.dart' show WipScreen;
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;
import 'package:whitenoise/src/rust/api/users.dart' show User;
import 'package:whitenoise/widgets/wn_slate_content_transition.dart' show WnSlateContentTransition;

abstract final class Routes {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static const _home = '/';
  static const _login = '/login';
  static const _scanNsec = '/scan-nsec';
  static const _scanNpub = '/scan-npub';
  static const _signup = '/signup';
  static const _chatList = '/chats';
  static const _settings = '/settings';
  static const _donate = '/donate';
  static const _appearance = '/appearance';
  static const _privacySecurity = '/privacy-security';
  static const _wip = '/wip';
  static const _developerSettings = '/developer-settings';
  static const _profileKeys = '/profile-keys';
  static const _shareProfile = '/share-profile';
  static const _editProfile = '/edit-profile';
  static const _signOut = '/sign-out';
  static const _switchProfile = '/switch-profile';
  static const _addProfile = '/add-profile';
  static const _network = '/network';
  static const _relayResolution = '/relay-resolution';
  static const _userSearch = '/user-search';
  static const _userSelection = '/user-selection';
  static const _setUpGroup = '/set-up-group';
  static const _addToGroup = '/add-to-group/:userPubkey';
  static const _startChat = '/start-chat/:userPubkey';
  static const _chatInfo = '/chat-info/:userPubkey';
  static const _groupInfo = '/group-info/:groupId';
  static const _editGroup = '/edit-group/:groupId';
  static const _groupMember = '/group-member/:groupId/:memberPubkey';
  static const _invite = '/invites/:mlsGroupId';
  static const _chat = '/chats/:groupId';
  static const _publicRoutes = {_home, _login, _scanNsec, _signup, _relayResolution};

  static GoRouter build(WidgetRef ref) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: _home,
      observers: [routeObserver, ActiveChatRouteObserver(ref.read(activeChatProvider.notifier))],
      redirect: (context, state) {
        final pubkey = ref.read(authProvider).value;
        final isOnPublicPage = _publicRoutes.contains(state.matchedLocation);
        final isAddingAccount = ref.read(isAddingAccountProvider);

        if (pubkey == null && !isOnPublicPage) return _login;
        if (pubkey != null && isOnPublicPage && !isAddingAccount) return _chatList;

        return null;
      },
      routes: [
        GoRoute(
          path: _home,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: _login,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const LoginScreen(),
          ),
        ),
        GoRoute(
          path: _scanNsec,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const ScanNsecScreen(),
          ),
        ),
        GoRoute(
          path: _scanNpub,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const ScanNpubScreen(),
          ),
        ),
        GoRoute(
          path: _signup,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const SignupScreen(),
          ),
        ),
        GoRoute(
          path: _chatList,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const ChatListScreen(),
          ),
        ),
        GoRoute(
          path: _settings,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const SettingsScreen(),
          ),
        ),
        GoRoute(
          path: _donate,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const DonateScreen(),
          ),
        ),
        GoRoute(
          path: _appearance,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const AppearanceScreen(),
          ),
        ),
        GoRoute(
          path: _privacySecurity,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const PrivacySecurityScreen(),
          ),
        ),
        GoRoute(
          path: _wip,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const WipScreen(),
          ),
        ),

        GoRoute(
          path: _developerSettings,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const DeveloperSettingsScreen(),
          ),
        ),
        GoRoute(
          path: _profileKeys,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const ProfileKeysScreen(),
          ),
        ),
        GoRoute(
          path: _shareProfile,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const ShareProfileScreen(),
          ),
        ),
        GoRoute(
          path: _editProfile,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const EditProfileScreen(),
          ),
        ),
        GoRoute(
          path: _signOut,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const SignOutScreen(),
          ),
        ),
        GoRoute(
          path: _switchProfile,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const SwitchProfileScreen(),
          ),
        ),
        GoRoute(
          path: _addProfile,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const AddProfileScreen(),
          ),
        ),
        GoRoute(
          path: _network,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const NetworkScreen(),
          ),
        ),
        GoRoute(
          name: 'relayResolution',
          path: _relayResolution,
          pageBuilder: (context, state) {
            final extra = state.extra! as Map<String, dynamic>;
            return _navigationTransition(
              state: state,
              child: RelayResolutionScreen(
                pubkey: extra['pubkey'] as String,
                isExternalSigner: extra['isExternalSigner'] as bool,
              ),
            );
          },
        ),
        GoRoute(
          path: _userSearch,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: const UserSearchScreen(),
          ),
        ),
        GoRoute(
          path: _userSelection,
          pageBuilder: (context, state) {
            final initialUsers = state.extra as List<User>? ?? const [];
            return _navigationTransition(
              state: state,
              child: UserSelectionScreen(initialUsers: initialUsers),
            );
          },
        ),
        GoRoute(
          name: 'setUpGroup',
          path: _setUpGroup,
          pageBuilder: (context, state) {
            final selectedUsers = state.extra as List<User>?;
            if (selectedUsers == null || selectedUsers.isEmpty) {
              return _navigationTransition(
                state: state,
                child: const UserSelectionScreen(),
              );
            }
            return _navigationTransition(
              state: state,
              child: SetUpGroupScreen(
                selectedUsers: selectedUsers,
              ),
            );
          },
        ),
        GoRoute(
          name: 'addToGroup',
          path: _addToGroup,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: AddToGroupScreen(
              userPubkey: state.pathParameters['userPubkey']!,
            ),
          ),
        ),
        GoRoute(
          name: 'startChat',
          path: _startChat,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: StartChatScreen(
              userPubkey: state.pathParameters['userPubkey']!,
              initialMetadata: state.extra as FlutterMetadata?,
            ),
          ),
        ),
        GoRoute(
          name: 'chatInfo',
          path: _chatInfo,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: ChatInfoScreen(userPubkey: state.pathParameters['userPubkey']!),
            opaque: false,
          ),
        ),
        GoRoute(
          name: 'groupInfo',
          path: _groupInfo,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: GroupInfoScreen(groupId: state.pathParameters['groupId']!),
            opaque: false,
          ),
        ),
        GoRoute(
          name: 'groupMember',
          path: _groupMember,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: GroupMemberScreen(
              groupId: state.pathParameters['groupId']!,
              memberPubkey: state.pathParameters['memberPubkey']!,
            ),
            opaque: false,
          ),
        ),
        GoRoute(
          name: 'editGroup',
          path: _editGroup,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: EditGroupScreen(groupId: state.pathParameters['groupId']!),
          ),
        ),
        GoRoute(
          name: 'invite',
          path: _invite,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: ChatInviteScreen(mlsGroupId: state.pathParameters['mlsGroupId']!),
          ),
        ),
        GoRoute(
          name: 'chat',
          path: _chat,
          pageBuilder: (context, state) => _navigationTransition(
            state: state,
            child: ChatScreen(groupId: state.pathParameters['groupId']!),
          ),
        ),
      ],
    );
  }

  static CustomTransitionPage<void> _navigationTransition({
    required GoRouterState state,
    required Widget child,
    bool opaque = true,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      name: state.uri.path,
      child: child,
      opaque: opaque,
      transitionDuration: WnSlateContentTransition.duration,
      reverseTransitionDuration: WnSlateContentTransition.duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  static void goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      GoRouter.of(context).pop();
    } else {
      GoRouter.of(context).go(_home);
    }
  }

  static void goToHome(BuildContext context) {
    GoRouter.of(context).go(_home);
  }

  static void pushToHome(BuildContext context) {
    GoRouter.of(context).push(_home);
  }

  static void goToLogin(BuildContext context) {
    GoRouter.of(context).go(_login);
  }

  static void pushToLogin(BuildContext context) {
    GoRouter.of(context).push(_login);
  }

  static void goToSignup(BuildContext context) {
    GoRouter.of(context).go(_signup);
  }

  static void pushToSignup(BuildContext context) {
    GoRouter.of(context).push(_signup);
  }

  static Future<String?> pushToScanNsec(BuildContext context) async {
    return GoRouter.of(context).push<String>(_scanNsec);
  }

  static void pushToScanNpub(BuildContext context) {
    GoRouter.of(context).push(_scanNpub);
  }

  static void goToChatList(BuildContext context) {
    GoRouter.of(context).go(_chatList);
  }

  static void pushToChatList(BuildContext context) {
    GoRouter.of(context).push(_chatList);
  }

  static void pushToSettings(BuildContext context) {
    GoRouter.of(context).push(_settings);
  }

  static void pushToWip(BuildContext context) {
    GoRouter.of(context).push(_wip);
  }

  static void pushToDonate(BuildContext context) {
    GoRouter.of(context).push(_donate);
  }

  static void pushToAppearance(BuildContext context) {
    GoRouter.of(context).push(_appearance);
  }

  static void pushToPrivacySecurity(BuildContext context) {
    GoRouter.of(context).push(_privacySecurity);
  }

  static void pushToDeveloperSettings(BuildContext context) {
    GoRouter.of(context).push(_developerSettings);
  }

  static void pushToProfileKeys(BuildContext context) {
    GoRouter.of(context).push(_profileKeys);
  }

  static void pushToShareProfile(BuildContext context) {
    GoRouter.of(context).push(_shareProfile);
  }

  static void pushToEditProfile(BuildContext context) {
    GoRouter.of(context).push(_editProfile);
  }

  static void pushToSignOut(BuildContext context) {
    GoRouter.of(context).push(_signOut);
  }

  static void pushToSwitchProfile(BuildContext context) {
    GoRouter.of(context).push(_switchProfile);
  }

  static void pushToAddProfile(BuildContext context) {
    GoRouter.of(context).push(_addProfile);
  }

  static void pushToUserSearch(BuildContext context) {
    GoRouter.of(context).push(_userSearch);
  }

  static void pushToUserSelection(BuildContext context, {List<User> initialUsers = const []}) {
    GoRouter.of(context).push(_userSelection, extra: initialUsers.isEmpty ? null : initialUsers);
  }

  static void pushToSetUpGroup(BuildContext context, List<User> selectedUsers) {
    GoRouter.of(context).pushNamed(
      'setUpGroup',
      extra: selectedUsers,
    );
  }

  static void pushToInvite(BuildContext context, String mlsGroupId) {
    GoRouter.of(context).pushNamed('invite', pathParameters: {'mlsGroupId': mlsGroupId});
  }

  static void goToChat(BuildContext context, String groupId) {
    GoRouter.of(context).goNamed('chat', pathParameters: {'groupId': groupId});
  }

  static void pushToRelayResolution(
    BuildContext context, {
    required String pubkey,
    required bool isExternalSigner,
  }) {
    GoRouter.of(context).push(
      _relayResolution,
      extra: {
        'pubkey': pubkey,
        'isExternalSigner': isExternalSigner,
      },
    );
  }

  static void pushToNetwork(BuildContext context) {
    GoRouter.of(context).push(_network);
  }

  static void pushToGroupInfo(BuildContext context, String groupId) {
    GoRouter.of(context).pushNamed('groupInfo', pathParameters: {'groupId': groupId});
  }

  static void pushToEditGroup(BuildContext context, String groupId) {
    GoRouter.of(context).pushNamed('editGroup', pathParameters: {'groupId': groupId});
  }

  static void pushToGroupMember(BuildContext context, String groupId, String memberPubkey) {
    GoRouter.of(context).pushNamed(
      'groupMember',
      pathParameters: {'groupId': groupId, 'memberPubkey': memberPubkey},
    );
  }

  static Future<bool?> pushToChatInfo(BuildContext context, String userPubkey) {
    return GoRouter.of(
      context,
    ).pushNamed<bool>('chatInfo', pathParameters: {'userPubkey': userPubkey});
  }

  static void pushToAddToGroup(BuildContext context, String userPubkey) {
    GoRouter.of(context).pushNamed(
      'addToGroup',
      pathParameters: {'userPubkey': userPubkey},
    );
  }

  static void pushToStartChat(
    BuildContext context,
    String userPubkey, {
    FlutterMetadata? metadata,
  }) {
    GoRouter.of(context).pushNamed(
      'startChat',
      pathParameters: {'userPubkey': userPubkey},
      extra: metadata,
    );
  }
}
