// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String photoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '照片',
      one: '照片',
    );
    return '$_temp0';
  }

  @override
  String mediaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '媒体文件',
      one: '媒体文件',
    );
    return '$_temp0';
  }

  @override
  String get appTitle => 'White Noise';

  @override
  String get sloganFull => '去中心化、防审查、\n安全的即时通讯。';

  @override
  String get sloganDecentralized => '去中心化';

  @override
  String get sloganUncensorable => '防审查';

  @override
  String get sloganSecureMessaging => '安全通讯';

  @override
  String get login => '登录';

  @override
  String get signUp => '注册';

  @override
  String get loginTitle => '输入您的私钥';

  @override
  String get enterPrivateKey => '输入您的私钥';

  @override
  String get nsecPlaceholder => 'nsec...';

  @override
  String get setupProfile => '设置个人资料';

  @override
  String get createProfile => '创建个人资料';

  @override
  String get chooseName => '名称';

  @override
  String get enterYourName => '输入您的名称';

  @override
  String get introduceYourself => '简介';

  @override
  String get writeSomethingAboutYourself => '介绍一下你自己';

  @override
  String get profilePrivacyDescription => '名称、照片和简介在全局 Nostr 网络中是公开可见的。请仅分享您愿意公开的内容。';

  @override
  String get cancel => '取消';

  @override
  String get profileReady => '您的个人资料已准备就绪！';

  @override
  String get startConversationHint => '通过添加好友或分享您的个人资料来开始对话。';

  @override
  String get share => '分享';

  @override
  String get shareYourProfile => '分享您的个人资料';

  @override
  String get startChat => '开始聊天';

  @override
  String get settings => '设置';

  @override
  String get shareAndConnect => '分享与连接';

  @override
  String get switchProfile => '切换账号';

  @override
  String get addNewProfile => '添加新账号';

  @override
  String get editProfile => '编辑个人资料';

  @override
  String get profileKeys => '账号密钥';

  @override
  String get networkRelays => '网络中继器';

  @override
  String get appearance => '外观';

  @override
  String get privacySecurity => '隐私与安全';

  @override
  String get donateToWhiteNoise => '捐赠给 White Noise';

  @override
  String get developerSettings => '开发者设置';

  @override
  String get signOut => '退出登录';

  @override
  String get appearanceTitle => '外观';

  @override
  String get privacySecurityTitle => '隐私与安全';

  @override
  String get deleteAllAppData => '删除所有应用数据';

  @override
  String get deleteAppData => '删除应用数据';

  @override
  String get deleteAllAppDataDescription => '从此设备上抹除所有的个人资料、密钥、聊天记录和本地文件。';

  @override
  String get deleteAllAppDataConfirmation => '确定要删除所有应用数据吗？';

  @override
  String get deleteAllAppDataWarning => '这将抹除此设备上的所有个人资料、密钥、聊天记录和本地文件。此操作不可撤销。';

  @override
  String get theme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get profileKeysTitle => '账号密钥';

  @override
  String get publicKey => '公钥';

  @override
  String get publicKeyCopied => '公钥已复制到剪贴板';

  @override
  String get publicKeyDescription => '您的公钥是您在 Nostr 网络上的唯一标识。分享它可以让其他人找到、识别并与您建立连接。';

  @override
  String get privateKey => '私钥';

  @override
  String get privateKeyCopied => '私钥已复制到剪贴板';

  @override
  String get privateKeyDescription => '私钥就像一个秘密密码，用于授权访问您的 Nostr 身份。';

  @override
  String get keepPrivateKeySecure => '请务必保护好您的私钥！';

  @override
  String get privateKeyWarning => '切勿公开分享您的私钥，且仅在登录其他信任的 Nostr 应用时使用它。';

  @override
  String get nsecOnExternalSigner => '私钥存储在外部签名器中';

  @override
  String get nsecOnExternalSignerDescription => '您的私钥在 White Noise 中不可用。请打开您的签名器应用来查看或管理它。';

  @override
  String get editProfileTitle => '编辑个人资料';

  @override
  String get profileName => '名称';

  @override
  String get nostrAddress => 'Nostr 地址 (nip-05)';

  @override
  String get nostrAddressPlaceholder => 'example@whitenoise.chat';

  @override
  String get aboutYou => '简介';

  @override
  String get profileIsPublic => '个人资料是公开的';

  @override
  String get profilePublicDescription => '您的个人资料信息将对网络上的所有人可见。';

  @override
  String get discard => '放弃';

  @override
  String get discardChanges => '放弃更改';

  @override
  String get save => '保存';

  @override
  String get profileUpdatedSuccessfully => '个人资料更新成功';

  @override
  String errorLoadingProfile(String error) {
    return '加载个人资料出错：$error';
  }

  @override
  String error(String error) {
    return '错误：$error';
  }

  @override
  String get profileLoadError => '无法加载个人资料。请重试。';

  @override
  String get failedToLoadPrivateKey => '无法加载私钥。请重试。';

  @override
  String get profileSaveError => '无法保存个人资料。请重试。';

  @override
  String get networkRelaysTitle => '网络中继器';

  @override
  String get myRelays => '我的中继器';

  @override
  String get myRelaysHelp => '您定义的在所有 Nostr 应用中使用的中继器。';

  @override
  String get inboxRelays => '收件箱中继器';

  @override
  String get inboxRelaysHelp => '用于接收邀请并与新用户开启安全对话的中继器。';

  @override
  String get keyPackageRelays => '密钥包中继器';

  @override
  String get keyPackageRelaysHelp => '存储您的安全密钥的中继器，以便他人邀请您进行加密对话。';

  @override
  String get errorLoadingRelays => '加载中继器出错';

  @override
  String get noRelaysConfigured => '未配置中继器';

  @override
  String get donateTitle => '捐赠给 White Noise';

  @override
  String get donateDescription =>
      '作为一家 501(c)3 非营利组织，White Noise 的存在纯粹是为了您的隐私和自由，而非利润。您的支持使我们能够保持独立且不妥协。';

  @override
  String get donateContributionAcknowledgmentTitle => '贡献确认';

  @override
  String get donateContributionLetterBefore => '如果您需要捐赠贡献确认函，请通过以下邮箱联系我们：';

  @override
  String get donateContributionLetterAfter => '';

  @override
  String get lightningAddress => '闪电网络地址';

  @override
  String get bitcoinSilentPayment => '比特币静默支付 (Silent Payment)';

  @override
  String get copiedToClipboardThankYou => '已复制到剪贴板。谢谢您的支持！';

  @override
  String get shareProfileTitle => '分享与连接';

  @override
  String get scanToConnect => '扫码连接';

  @override
  String get signOutTitle => '退出登录';

  @override
  String get signOutConfirmation => '确定要退出登录吗？';

  @override
  String get signOutWarning => '当您退出 White Noise 时，您的聊天记录将从此设备中删除，且无法在其他设备上恢复。';

  @override
  String get signOutWarningBackupKey => '如果您尚未备份私钥，您将无法在任何其他 Nostr 服务上使用此账号。';

  @override
  String get signOutCalloutTitle => '备份您的私钥';

  @override
  String get signOutCalloutDescription =>
      '当您退出 White Noise 时，您的聊天记录将从此设备中删除且无法恢复。\n\n如果您以后想再次访问您的账号，请复制并安全存储您的私钥。否则，您将永久失去访问权限。';

  @override
  String get signOutCalloutDescriptionBefore => '请确保您已在 ';

  @override
  String get signOutCalloutDescriptionLink => '设置 → 账号密钥';

  @override
  String get signOutCalloutDescriptionAfter => ' 中备份了私钥。否则，您将无法再次登录。';

  @override
  String get backUpPrivateKey => '备份私钥';

  @override
  String get copyPrivateKeyHint => '复制您的私钥以便在另一台设备上恢复您的账号。';

  @override
  String get publicKeyCopyError => '复制公钥失败。请重试。';

  @override
  String get noChatsYet => '暂无聊天';

  @override
  String get startConversation => '开始对话';

  @override
  String get welcomeNoticeTitle => '您的个人资料已准备就绪';

  @override
  String welcomeNoticeDescription(String findPeople, String shareProfile, String startANewChat) {
    return '点击 $findPeople 寻找好友。您也可以通过 $shareProfile 与认识的人建立连接，或点击聊天加号图标 $startANewChat。';
  }

  @override
  String get findPeople => '寻找用户';

  @override
  String get startANewChat => '开始新聊天';

  @override
  String get noMessagesYet => '暂无消息';

  @override
  String get messagePlaceholder => '输入消息';

  @override
  String get failedToSendMessage => '发送消息失败。请重试。';

  @override
  String get invitedToSecureChat => '您被邀请加入安全聊天';

  @override
  String get invitedYouToChatSuffix => ' 邀请您聊天';

  @override
  String get decline => '拒绝';

  @override
  String get accept => '接受';

  @override
  String get failedToAcceptInvitation => '接受邀请失败。请重试。';

  @override
  String get failedToDeclineInvitation => '拒绝邀请失败。请重试。';

  @override
  String get startNewChat => '发起新聊天';

  @override
  String get noResults => '无结果';

  @override
  String get noFollowsYet => '暂无关注';

  @override
  String get searchByNameOrNpub => '名称或 npub1...';

  @override
  String get developerSettingsTitle => '开发者设置';

  @override
  String get keyPackageManagementTitle => '密钥包管理';

  @override
  String get keyPackageManagementDescription => '发布、刷新和删除账号密钥包';

  @override
  String get relayStateTitle => '中继器状态';

  @override
  String get relayStateDescription => '检查实时中继器控制平面';

  @override
  String get relayControlStateDumpLabel => 'debug_relay_control_state:';

  @override
  String get relayControlStateSnapshotDescription => '实时中继器发现、收件箱和群组平面的快照。';

  @override
  String get relayControlStateLoading => '正在加载...';

  @override
  String get relayControlStateRefreshButton => '刷新转储';

  @override
  String get relayControlStateCopyButton => '复制转储';

  @override
  String get publishNewKeyPackage => '发布新密钥包';

  @override
  String get refreshKeyPackages => '刷新密钥包';

  @override
  String get deleteLegacyKeyPackages => '删除旧版密钥包';

  @override
  String keyPackagesCount(int count) {
    return '密钥包 ($count)';
  }

  @override
  String get noKeyPackagesFound => '未发现密钥包';

  @override
  String get keyPackagePublished => '密钥包已发布';

  @override
  String get keyPackagesRefreshed => '密钥包已刷新';

  @override
  String get legacyKeyPackagesDeleted => '旧版密钥包已删除';

  @override
  String get keyPackageDeleted => '密钥包已删除';

  @override
  String get keyPackageFetchFailed => '刷新密钥包失败。请重试。';

  @override
  String get keyPackagePublishFailed => '发布密钥包失败。请重试。';

  @override
  String get keyPackageDeleteFailed => '删除密钥包失败。请重试。';

  @override
  String get legacyKeyPackageDeleteFailed => '删除旧版密钥包失败。请重试。';

  @override
  String get legacyLabel => '旧版';

  @override
  String packageNumber(int number) {
    return '密钥包 $number';
  }

  @override
  String get goBack => '返回';

  @override
  String get createGroup => '创建群组';

  @override
  String get newGroupChat => '新群组聊天';

  @override
  String get selectMembers => '选择成员';

  @override
  String selectedCount(int count) {
    return '已选择 $count 人';
  }

  @override
  String get clearSelection => '清除';

  @override
  String get continueButton => '继续';

  @override
  String get setUpGroup => '设置群组';

  @override
  String get groupName => '群组名称';

  @override
  String get groupNamePlaceholder => '输入群组名称';

  @override
  String get groupDescription => '群组描述';

  @override
  String get description => '描述';

  @override
  String get groupDescriptionPlaceholder => '这个群组是做什么的？';

  @override
  String members(int count) {
    return '$count 名成员';
  }

  @override
  String invitingMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '正在邀请成员：',
      one: '正在邀请成员：',
    );
    return '$_temp0';
  }

  @override
  String get usersWithoutKeyPackages => '没有密钥包的用户（无法添加）';

  @override
  String usersNotOnWhiteNoise(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '这些用户尚未使用 White Noise',
      one: '该用户尚未使用 White Noise',
    );
    return '$_temp0';
  }

  @override
  String usersNotOnWhiteNoiseDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '这些用户无法被添加到群组中，因为他们尚未安装 White Noise 或尚未发布其密钥包。',
      one: '该用户无法被添加到群组中，因为他们尚未安装 White Noise 或尚未发布其密钥包。',
    );
    return '$_temp0';
  }

  @override
  String get uploadingImage => '正在上传图片...';

  @override
  String get creatingGroup => '正在创建群组...';

  @override
  String get groupNameRequired => '必须填写群组名称';

  @override
  String get noUsersWithKeyPackages => '没有拥有密钥包的用户可供添加';

  @override
  String get createGroupFailed => '创建群组失败';

  @override
  String get reportError => '报告错误';

  @override
  String get wipMessage => '我们正在开发此功能。为了支持我们的开发工作，欢迎捐赠给 White Noise';

  @override
  String get donate => '捐赠';

  @override
  String get chatWithSupport => '联系客服';

  @override
  String get supportChatWelcomeMessage => '您好！请告诉我们您的想法 —— 无论是疑问、Bug 还是建议。我们通常会在几小时内给予回复。';

  @override
  String get addRelay => '添加中继器';

  @override
  String get restoreDefaultRelays => '恢复默认中继器';

  @override
  String get restoreDefaultRelaysConfirmationTitle => '要恢复默认中继器吗？';

  @override
  String get restoreDefaultRelaysConfirmationMessage => '您确定要恢复应用的默认中继器吗？这将抹除并替换您当前的中继器配置。';

  @override
  String get restoreDefaultRelaysError => '恢复默认中继器失败。请重试。';

  @override
  String get addMyRelay => '添加我的中继器';

  @override
  String get addInboxRelay => '添加收件箱中继器';

  @override
  String get addKeyPackageRelay => '添加密钥包中继器';

  @override
  String get enterRelayAddress => '中继器地址';

  @override
  String get relayAddressPlaceholder => 'wss://relay.example.com';

  @override
  String get removeRelay => '移除中继器？';

  @override
  String get removeRelayConfirmation => '您确定要移除此中继器吗？此操作无法撤销。';

  @override
  String get remove => '移除';

  @override
  String get messageActions => '消息操作';

  @override
  String get reply => '回复';

  @override
  String get copyMessage => '复制';

  @override
  String get copyCode => '复制代码';

  @override
  String get copied => '已复制';

  @override
  String get delete => '删除';

  @override
  String get failedToDeleteMessage => '删除消息失败。请重试。';

  @override
  String get failedToSendReaction => '发送表情回应失败。请重试。';

  @override
  String get failedToRemoveReaction => '移除表情回应失败。请重试。';

  @override
  String get unknownUser => '未知用户';

  @override
  String get noName => '未命名';

  @override
  String get unknownGroup => '未知群组';

  @override
  String get hasInvitedYouToSecureChat => '邀请您加入安全聊天';

  @override
  String userInvitedYouToSecureChat(String name) {
    return '$name 邀请您加入安全聊天';
  }

  @override
  String get youHaveBeenInvitedToSecureChat => '您已受邀加入安全聊天';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageUpdateFailed => '保存语言偏好失败。请重试。';

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟前',
      one: '1 分钟前',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时前',
      one: '1 小时前',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前',
      one: '昨天',
    );
    return '$_temp0';
  }

  @override
  String get profile => '个人资料';

  @override
  String get follow => '关注';

  @override
  String get unfollow => '取消关注';

  @override
  String chatSearchMatchCount(int current, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total 条匹配',
      one: '1 条匹配',
    );
    return '第 $current 条，共 $_temp0';
  }

  @override
  String get failedToStartChat => '发起聊天失败。请重试。';

  @override
  String get inviteToWhiteNoise => '邀请加入 White Noise';

  @override
  String inviteToWhiteNoiseDescription(String name) {
    return '$name 尚未加入 White Noise。分享此应用以开始安全聊天。';
  }

  @override
  String get inviteMessage =>
      '快来 White Noise 加入我吧。无需手机号，无监控，真正的隐私。点击此处下载：https://www.whitenoise.chat/download';

  @override
  String get failedToUpdateFollow => '更新关注状态失败。请重试。';

  @override
  String get imagePickerError => '选取图片失败。请重试。';

  @override
  String get scanNsec => '扫码';

  @override
  String get scanNsecHint => '扫描您的私钥二维码以登录。';

  @override
  String get cameraPermissionDenied => '相机权限被拒绝';

  @override
  String get somethingWentWrong => '出错了';

  @override
  String get scanNpub => '扫码';

  @override
  String get scanNpubHint => '扫描联系人的二维码。';

  @override
  String get invalidNpub => '公钥无效。请重试。';

  @override
  String get you => '您';

  @override
  String get timestampNow => '现在';

  @override
  String timestampMinutes(int count) {
    return '$count分钟前';
  }

  @override
  String timestampHours(int count) {
    return '$count小时前';
  }

  @override
  String get timestampYesterday => '昨天';

  @override
  String get weekdayMonday => '星期一';

  @override
  String get weekdayTuesday => '星期二';

  @override
  String get weekdayWednesday => '星期三';

  @override
  String get weekdayThursday => '星期四';

  @override
  String get weekdayFriday => '星期五';

  @override
  String get weekdaySaturday => '星期六';

  @override
  String get weekdaySunday => '星期日';

  @override
  String get monthJanShort => '1月';

  @override
  String get monthFebShort => '2月';

  @override
  String get monthMarShort => '3月';

  @override
  String get monthAprShort => '4月';

  @override
  String get monthMayShort => '5月';

  @override
  String get monthJunShort => '6月';

  @override
  String get monthJulShort => '7月';

  @override
  String get monthAugShort => '8月';

  @override
  String get monthSepShort => '9月';

  @override
  String get monthOctShort => '10月';

  @override
  String get monthNovShort => '11月';

  @override
  String get monthDecShort => '12月';

  @override
  String get loginWithAmber => '使用 Amber 登录';

  @override
  String get signerConnectionError => '无法连接到签名器。请重试。';

  @override
  String get search => '搜索';

  @override
  String get filterChats => '聊天';

  @override
  String get filterArchive => '归档';

  @override
  String get signerErrorUserRejected => '登录已取消';

  @override
  String get signerErrorNotConnected => '未连接到签名器。请重试。';

  @override
  String get signerErrorNoSigner => '未发现签名器应用。请安装兼容 NIP-55 的签名器。';

  @override
  String get signerErrorNoResponse => '签名器无响应。请重试。';

  @override
  String get signerErrorNoPubkey => '无法从签名器获取公钥。';

  @override
  String get signerErrorNoResult => '签名器未返回结果。';

  @override
  String get signerErrorNoEvent => '签名器未返回已签名的事件。';

  @override
  String get signerErrorRequestInProgress => '另一个请求正在处理中。请稍候。';

  @override
  String get signerErrorNoActivity => '无法启动签名器。请重试。';

  @override
  String get signerErrorLaunchError => '启动签名器应用失败。';

  @override
  String get signerErrorUnknown => '签名器发生错误。请重试。';

  @override
  String get messageNotFound => '找不到消息';

  @override
  String get pin => '置顶';

  @override
  String get unpin => '取消置顶';

  @override
  String get mute => '静音';

  @override
  String get archive => '归档';

  @override
  String get unarchive => '取消归档';

  @override
  String get failedToArchiveChat => '归档聊天失败。请重试。';

  @override
  String get failedToUnarchiveChat => '取消归档聊天失败。请重试。';

  @override
  String get archivedChatsEmpty => '无归档聊天';

  @override
  String get failedToPinChat => '更新置顶状态失败。请重试。';

  @override
  String get carouselPrivacyTitle => '隐私与安全';

  @override
  String get carouselPrivacyDescription => '保护您的对话私密。即使发生数据泄露，您的消息依然安全无虞。';

  @override
  String get carouselIdentityTitle => '选择您的身份';

  @override
  String get carouselIdentityDescription => '聊天无需透露手机号或电子邮箱。自由选择您的身份：真名、笔名或匿名。';

  @override
  String get carouselDecentralizedTitle => '去中心化且无准入门槛';

  @override
  String get carouselDecentralizedDescription => '没有任何中央机构可以控制您的通信 —— 无需许可，无法审查。';

  @override
  String get learnMore => '了解更多';

  @override
  String get backToSignUp => '返回注册';

  @override
  String get deleteAllData => '删除所有数据';

  @override
  String get deleteAllDataConfirmation => '要删除所有数据吗？';

  @override
  String get deleteAllDataWarning => '这将永久删除此设备上的所有聊天记录、消息和设置。此操作无法撤销。';

  @override
  String get deleteAllDataError => '删除所有数据失败。请重试。';

  @override
  String get chatInformation => '聊天信息';

  @override
  String get addToGroup => '添加到群组';

  @override
  String get blockUser => '屏蔽用户';

  @override
  String get unblockUser => '取消屏蔽';

  @override
  String get unblock => '取消屏蔽';

  @override
  String get failedToBlockUser => '屏蔽用户失败。请重试。';

  @override
  String get failedToUnblockUser => '取消屏蔽失败。请重试。';

  @override
  String get userIsBlocked => '您已屏蔽此用户';

  @override
  String get userIsBlockedDescription => '在您取消屏蔽之前，您将不会收到新消息。';

  @override
  String get addToAnotherGroup => '添加到另一个群组';

  @override
  String get relayResolutionTitle => '中继器设置';

  @override
  String get relayResolutionDescription =>
      '我们无法在网络上找到您的中继器列表。您可以提供一个已发布这些列表的中继器地址，或者使用我们的默认中继器开始使用。';

  @override
  String get relayResolutionUseDefaults => '使用默认中继器';

  @override
  String get relayResolutionTryRelay => '搜索中继器';

  @override
  String get relayResolutionRelayPlaceholder => 'wss://relay.example.com';

  @override
  String get relayResolutionRelayLabel => '中继器 URL';

  @override
  String get relayResolutionNotFound => '在此中继器上未发现中继器列表。请尝试其他中继器或使用默认设置。';

  @override
  String get loginErrorInvalidKey => 'nsec 无效。请确保输入正确。';

  @override
  String get loginErrorNoRelayConnections => '无法连接到任何中继器。请检查您的网络连接并重试。';

  @override
  String get loginErrorTimeout => '登录超时。请重试。';

  @override
  String get loginErrorGeneric => '登录过程中发生错误。请重试。';

  @override
  String get loginErrorNoLoginInProgress => '当前没有正在进行的登录。请重新开始。';

  @override
  String get loginErrorInternal => '发生内部错误。请重试。';

  @override
  String get loginPasteNothingToPaste => '剪贴板为空';

  @override
  String get loginPasteFailed => '从剪贴板粘贴失败';

  @override
  String get openSettings => '打开设置';

  @override
  String get scannerError => '扫描器错误';

  @override
  String get scannerErrorDescription => '扫描器发生故障。请重试。';

  @override
  String get cameraPermissionDeniedDescription => '请在设备设置中开启相机权限以扫描二维码。';

  @override
  String get retry => '重试';

  @override
  String get groupInformation => '群组信息';

  @override
  String get editGroup => '编辑群组';

  @override
  String get editGroupAction => '编辑群组';

  @override
  String get groupNameLabel => '名称';

  @override
  String get groupDescriptionLabel => '关于';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 名成员',
      one: '1 名成员',
    );
    return '$_temp0';
  }

  @override
  String get adminBadge => '管理员';

  @override
  String get membersLabel => '成员：';

  @override
  String get memberBadge => '成员';

  @override
  String get sendMessage => '发送消息';

  @override
  String get makeAdmin => '设为管理员';

  @override
  String get removeAdminRole => '取消管理员';

  @override
  String get removeFromGroup => '移出群组';

  @override
  String get removeFromGroupConfirmation => '要移出群组吗？';

  @override
  String get removeFromGroupWarning => '该成员将被移出群组，且无法再看到新消息。';

  @override
  String get makeAdminConfirmation => '要设为管理员吗？';

  @override
  String get makeAdminWarning => '该成员将能够管理群组、添加或删除成员以及更改群组设置。';

  @override
  String get removeAdminConfirmation => '要取消管理员吗？';

  @override
  String get removeAdminWarning => '该成员将不再能够管理群组、添加或删除成员或更改群组设置。';

  @override
  String get failedToRemoveFromGroup => '移除成员失败。请重试。';

  @override
  String get failedToMakeAdmin => '设置管理员失败。请重试。';

  @override
  String get failedToRemoveAdmin => '取消管理员失败。请重试。';

  @override
  String get groupUpdatedSuccessfully => '群组更新成功';

  @override
  String get groupLoadError => '无法加载群组。请重试。';

  @override
  String get groupSaveError => '无法保存群组。请重试。';

  @override
  String get failedToFetchGroupMembers => '加载群组成员失败。请重试。';

  @override
  String get failedToAddMembers => '添加成员失败。请重试。';

  @override
  String get groupImageUploadFailed => '群组已创建，但图片上传失败。';

  @override
  String updateNeeded(String name) {
    return '$name 需要更新';
  }

  @override
  String updateNeededDescription(String name) {
    return '您还无法与 $name 开始安全聊天。他们需要先更新 White Noise 才能使用安全通讯。';
  }

  @override
  String addToGroupConfirmation(String userName, String groupName) {
    return '要将 $userName 添加到 $groupName 吗？';
  }

  @override
  String get unknownInviteToWhiteNoiseDescription => '该用户尚未加入 White Noise。分享此应用以开始安全聊天。';

  @override
  String get unknownUserNeedsUpdate => '需要更新';

  @override
  String get unknownUserNeedsUpdateDescription => '您还无法与此用户开始安全聊天。他们需要先更新 White Noise 才能使用安全通讯。';

  @override
  String get add => '添加';

  @override
  String get noGroupsAvailable => '暂无可用群组';

  @override
  String get noAdminGroupsAvailable => '您尚未在任何群组中担任管理员。创建一个群组来添加成员吧。';

  @override
  String get profilesTitle => '个人资料';

  @override
  String get noAccountsAvailable => '暂无可用账号';

  @override
  String get connectAnotherProfile => '连接另一个账号';

  @override
  String get rawDebugView => '调试模式';

  @override
  String get rawDebugViewDescription => '在聊天中显示原始消息数据';

  @override
  String get rawDebugViewTitle => '调试模式';

  @override
  String get rawDebugViewGroupId => '群组 ID';

  @override
  String rawDebugViewMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条消息',
      one: '1 条消息',
      zero: '无消息',
    );
    return '$_temp0';
  }

  @override
  String get rawDebugViewCopied => '已复制到剪贴板';

  @override
  String get appLogsTitle => '应用日志';

  @override
  String get appLogsViewLogs => '查看日志';

  @override
  String get appLogsViewLogsDescription => '在应用内查看所有日志输出';

  @override
  String get appLogsClear => '清除';

  @override
  String get appLogsEraseAll => '全部清除';

  @override
  String get appLogsEmpty => '暂无日志';

  @override
  String get appLogsSearchPlaceholder => '搜索日志...';

  @override
  String get appLogsAddPatternPlaceholder => '添加过滤模式';

  @override
  String get appLogsIgnore => '忽略';

  @override
  String get appLogsShow => '显示';

  @override
  String get appLogsClearFilters => '清除过滤器';

  @override
  String get appLogsLive => '实时';

  @override
  String appLogsFilteredCount(int shown, int total) {
    return '$shown / $total';
  }

  @override
  String get appLogsCopyAll => '全部复制';

  @override
  String get invalidRelayUrlScheme => 'URL 必须以 wss:// 或 ws:// 开头';

  @override
  String get invalidRelayUrl => '中继器 URL 无效';

  @override
  String get thisMessageWasDeleted => '此消息已被删除。';

  @override
  String get youDeletedThisMessage => '您删除了此消息。';

  @override
  String get relayControlStateLoadError => '加载中继器控制状态失败。请重试。';

  @override
  String get updateAvailableTitle => '有新版本可用';

  @override
  String updateAvailableDescription(String version) {
    return '版本 $version 已在 Zapstore 发布。';
  }

  @override
  String get updateNow => '立即更新';

  @override
  String get fatalErrorCopyError => '复制错误';

  @override
  String get fatalErrorErrorCopied => '错误已复制到剪贴板';

  @override
  String get fatalErrorTitle => '哎呀！';

  @override
  String get fatalErrorDescription => '加载应用时遇到了一点问题。抱歉，这不是您的错，是我们的问题。\n\n请帮我们修复它。点击下方将此错误发送给我们的团队。';

  @override
  String get reportBug => '报告 Bug';

  @override
  String get reportBugDescription => '描述您遇到的问题，帮助我们改进 White Noise。';

  @override
  String get reportBugWhatWentWrong => '发生了什么问题？';

  @override
  String get reportBugWhatWentWrongPlaceholder => '请描述您遇到的问题...';

  @override
  String get reportBugStepsToReproduce => '复现步骤';

  @override
  String get reportBugStepsToReproducePlaceholder => '1. 前往...\n2. 点击...\n3. 看到错误';

  @override
  String get reportBugFrequency => '问题发生的频率？';

  @override
  String get reportBugFrequencyOnce => '仅一次';

  @override
  String get reportBugFrequencyAlways => '总是';

  @override
  String get reportBugFrequencySometimes => '有时';

  @override
  String get reportBugIncludeNpub => '包含您的 npub';

  @override
  String get reportBugIncludeNpubDescription => '方便我们在需要时跟进；不勾选则保持匿名报告。';

  @override
  String get reportBugSend => '发送报告';

  @override
  String get reportBugSuccess => 'Bug 报告已发送。谢谢！';

  @override
  String get reportBugError => '发送报告失败。请重试。';

  @override
  String get reportBugWhatWentWrongRequired => '请描述具体发生了什么问题。';

  @override
  String get failedToStartSupportChat => '无法发起客服聊天';

  @override
  String get removedFromGroup => '您已被移出此群组';

  @override
  String get youLeftThisGroup => '您已退出此群组';

  @override
  String get removedFromGroupDescription => '您仍可以查看已保存的消息，但无法发送或接收新消息。您可以随时归档此聊天。';

  @override
  String get notificationSettings => '通知';

  @override
  String get notificationSettingsTitle => '通知';

  @override
  String get notifications => '通知';

  @override
  String get notificationsDescription => '接收新消息的推送通知';

  @override
  String get notificationsSettingsLoadError => '无法加载通知设置。请重试。';

  @override
  String get notificationsSettingsUpdateError => '无法更新通知设置。请重试。';

  @override
  String get waitingForInternet => '正在等待网络连接';

  @override
  String get saveToGalleryPermissionDenied => '无权保存图片';

  @override
  String get saveToGalleryNotEnoughSpace => '存储空间不足';

  @override
  String get saveToGalleryNotSupportedFormat => '不支持的图片格式';

  @override
  String get saveToGalleryError => '图片保存到相册失败';

  @override
  String get leave => '退出';

  @override
  String get leaveGroup => '退出群组';

  @override
  String get leaveGroupWarning => '确定要退出此群组吗？如果您不删除，聊天记录将保留在列表中，但您将无法发送或接收新消息，除非有人再次邀请您。';

  @override
  String get failedToLeaveGroup => '退出群组失败。请重试。';

  @override
  String get youLeftTheGroup => '您已退出群组';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String photoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '照片',
      one: '照片',
    );
    return '$_temp0';
  }

  @override
  String mediaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '媒體檔案',
      one: '媒體檔案',
    );
    return '$_temp0';
  }

  @override
  String get appTitle => 'White Noise';

  @override
  String get sloganFull => '去中心化、抗審查，\n安全的即時通訊。';

  @override
  String get sloganDecentralized => '去中心化';

  @override
  String get sloganUncensorable => '抗審查';

  @override
  String get sloganSecureMessaging => '安全通訊';

  @override
  String get login => '登入';

  @override
  String get signUp => '註冊';

  @override
  String get loginTitle => '輸入您的私鑰';

  @override
  String get enterPrivateKey => '輸入您的私鑰';

  @override
  String get nsecPlaceholder => 'nsec...';

  @override
  String get setupProfile => '設定個人檔案';

  @override
  String get createProfile => '建立個人檔案';

  @override
  String get chooseName => '名稱';

  @override
  String get enterYourName => '輸入您的名稱';

  @override
  String get introduceYourself => '簡介';

  @override
  String get writeSomethingAboutYourself => '介紹一下自己';

  @override
  String get profilePrivacyDescription => '名稱、照片和簡介會在全球 Nostr 網路上公開顯示。請只分享您願意公開的內容。';

  @override
  String get cancel => '取消';

  @override
  String get profileReady => '您的個人檔案已準備就緒！';

  @override
  String get startConversationHint => '加入好友或分享您的個人檔案，即可開始對話。';

  @override
  String get share => '分享';

  @override
  String get shareYourProfile => '分享您的個人檔案';

  @override
  String get startChat => '開始聊天';

  @override
  String get settings => '設定';

  @override
  String get shareAndConnect => '分享與連結';

  @override
  String get switchProfile => '切換帳號';

  @override
  String get addNewProfile => '新增帳號';

  @override
  String get editProfile => '編輯個人檔案';

  @override
  String get profileKeys => '帳號金鑰';

  @override
  String get networkRelays => '網路中繼站';

  @override
  String get appearance => '外觀';

  @override
  String get privacySecurity => '隱私與安全';

  @override
  String get donateToWhiteNoise => '捐款給 White Noise';

  @override
  String get developerSettings => '開發者設定';

  @override
  String get signOut => '登出';

  @override
  String get appearanceTitle => '外觀';

  @override
  String get privacySecurityTitle => '隱私與安全';

  @override
  String get deleteAllAppData => '刪除所有應用程式資料';

  @override
  String get deleteAppData => '刪除應用程式資料';

  @override
  String get deleteAllAppDataDescription => '從這台裝置清除所有個人檔案、金鑰、聊天記錄和本機檔案。';

  @override
  String get deleteAllAppDataConfirmation => '確定要刪除所有應用程式資料嗎？';

  @override
  String get deleteAllAppDataWarning => '這會清除這台裝置上的所有個人檔案、金鑰、聊天記錄和本機檔案。此操作無法復原。';

  @override
  String get theme => '主題';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get profileKeysTitle => '帳號金鑰';

  @override
  String get publicKey => '公鑰';

  @override
  String get publicKeyCopied => '公鑰已複製到剪貼簿';

  @override
  String get publicKeyDescription => '您的公鑰是您在 Nostr 網路上的唯一識別碼。分享它可讓其他人找到、辨識並與您連結。';

  @override
  String get privateKey => '私鑰';

  @override
  String get privateKeyCopied => '私鑰已複製到剪貼簿';

  @override
  String get privateKeyDescription => '私鑰就像祕密密碼，可用來存取您的 Nostr 身分。';

  @override
  String get keepPrivateKeySecure => '請務必妥善保管您的私鑰！';

  @override
  String get privateKeyWarning => '切勿公開分享您的私鑰，也只應在登入其他可信任的 Nostr 應用程式時使用。';

  @override
  String get nsecOnExternalSigner => '私鑰儲存在外部簽署器中';

  @override
  String get nsecOnExternalSignerDescription => 'White Noise 無法存取您的私鑰。請開啟您的簽署器應用程式查看或管理。';

  @override
  String get editProfileTitle => '編輯個人檔案';

  @override
  String get profileName => '名稱';

  @override
  String get nostrAddress => 'Nostr 位址 (nip-05)';

  @override
  String get nostrAddressPlaceholder => 'example@whitenoise.chat';

  @override
  String get aboutYou => '簡介';

  @override
  String get profileIsPublic => '個人檔案是公開的';

  @override
  String get profilePublicDescription => '您的個人檔案資訊會讓網路上的所有人看見。';

  @override
  String get discard => '捨棄';

  @override
  String get discardChanges => '捨棄變更';

  @override
  String get save => '儲存';

  @override
  String get profileUpdatedSuccessfully => '個人檔案已更新';

  @override
  String errorLoadingProfile(String error) {
    return '載入個人檔案時發生錯誤：$error';
  }

  @override
  String error(String error) {
    return '錯誤：$error';
  }

  @override
  String get profileLoadError => '無法載入個人檔案。請再試一次。';

  @override
  String get failedToLoadPrivateKey => '無法載入私鑰。請再試一次。';

  @override
  String get profileSaveError => '無法儲存個人檔案。請再試一次。';

  @override
  String get networkRelaysTitle => '網路中繼站';

  @override
  String get myRelays => '我的中繼站';

  @override
  String get myRelaysHelp => '您設定並供所有 Nostr 應用程式使用的中繼站。';

  @override
  String get inboxRelays => '收件匣中繼站';

  @override
  String get inboxRelaysHelp => '用來接收邀請，並與新使用者開始安全對話的中繼站。';

  @override
  String get keyPackageRelays => '金鑰套件中繼站';

  @override
  String get keyPackageRelaysHelp => '用來儲存安全金鑰的中繼站，讓其他人能邀請您進行加密對話。';

  @override
  String get errorLoadingRelays => '載入中繼站時發生錯誤';

  @override
  String get noRelaysConfigured => '尚未設定中繼站';

  @override
  String get donateTitle => '捐款給 White Noise';

  @override
  String get donateDescription =>
      'White Noise 是 501(c)3 非營利組織，存在的目的純粹是守護您的隱私與自由，而非追求利潤。您的支持讓我們能保持獨立、不受妥協。';

  @override
  String get donateContributionAcknowledgmentTitle => '捐款證明';

  @override
  String get donateContributionLetterBefore => '如果您需要捐款證明信，請透過以下信箱聯絡我們：';

  @override
  String get donateContributionLetterAfter => '';

  @override
  String get lightningAddress => '閃電網路地址';

  @override
  String get bitcoinSilentPayment => '比特幣靜默支付 (Silent Payment)';

  @override
  String get copiedToClipboardThankYou => '已複製到剪貼簿。謝謝您的支持！';

  @override
  String get shareProfileTitle => '分享與連結';

  @override
  String get scanToConnect => '掃描即可連結';

  @override
  String get signOutTitle => '登出';

  @override
  String get signOutConfirmation => '確定要登出嗎？';

  @override
  String get signOutWarning => '登出 White Noise 後，您的聊天記錄會從這台裝置刪除，且無法在其他裝置上還原。';

  @override
  String get signOutWarningBackupKey => '如果您尚未備份私鑰，將無法在任何其他 Nostr 服務使用此帳號。';

  @override
  String get signOutCalloutTitle => '備份您的私鑰';

  @override
  String get signOutCalloutDescription =>
      '登出 White Noise 後，您的聊天記錄會從這台裝置刪除且無法復原。\n\n如果您之後想再次存取帳號，請複製並妥善保存您的私鑰。否則，您將永久失去存取權。';

  @override
  String get signOutCalloutDescriptionBefore => '請確認您已在 ';

  @override
  String get signOutCalloutDescriptionLink => '設定 → 帳號金鑰';

  @override
  String get signOutCalloutDescriptionAfter => ' 備份私鑰。否則，您將無法再次登入。';

  @override
  String get backUpPrivateKey => '備份私鑰';

  @override
  String get copyPrivateKeyHint => '複製您的私鑰，以便在另一台裝置還原帳號。';

  @override
  String get publicKeyCopyError => '無法複製公鑰。請再試一次。';

  @override
  String get noChatsYet => '尚無聊天';

  @override
  String get startConversation => '開始對話';

  @override
  String get welcomeNoticeTitle => '您的個人檔案已準備就緒';

  @override
  String welcomeNoticeDescription(String findPeople, String shareProfile, String startANewChat) {
    return '點一下 $findPeople 尋找好友。您也可以透過 $shareProfile 與認識的人建立連結，或點選聊天加號圖示 $startANewChat。';
  }

  @override
  String get findPeople => '尋找使用者';

  @override
  String get startANewChat => '開始新聊天';

  @override
  String get noMessagesYet => '尚無訊息';

  @override
  String get messagePlaceholder => '輸入訊息';

  @override
  String get failedToSendMessage => '訊息傳送失敗。請再試一次。';

  @override
  String get invitedToSecureChat => '您已受邀加入安全聊天';

  @override
  String get invitedYouToChatSuffix => ' 邀請您聊天';

  @override
  String get decline => '拒絕';

  @override
  String get accept => '接受';

  @override
  String get failedToAcceptInvitation => '接受邀請失敗。請再試一次。';

  @override
  String get failedToDeclineInvitation => '拒絕邀請失敗。請再試一次。';

  @override
  String get startNewChat => '發起新聊天';

  @override
  String get noResults => '沒有結果';

  @override
  String get noFollowsYet => '尚未追蹤任何人';

  @override
  String get searchByNameOrNpub => '名稱或 npub1...';

  @override
  String get developerSettingsTitle => '開發者設定';

  @override
  String get keyPackageManagementTitle => '金鑰套件管理';

  @override
  String get keyPackageManagementDescription => '發布、重新整理和刪除帳號金鑰套件';

  @override
  String get relayStateTitle => '中繼站狀態';

  @override
  String get relayStateDescription => '檢查即時中繼站控制平面';

  @override
  String get relayControlStateDumpLabel => 'debug_relay_control_state:';

  @override
  String get relayControlStateSnapshotDescription => '即時中繼站探索、收件匣和群組平面的快照。';

  @override
  String get relayControlStateLoading => '正在載入...';

  @override
  String get relayControlStateRefreshButton => '重新整理傾印';

  @override
  String get relayControlStateCopyButton => '複製傾印';

  @override
  String get publishNewKeyPackage => '發布新金鑰套件';

  @override
  String get refreshKeyPackages => '重新整理金鑰套件';

  @override
  String get deleteLegacyKeyPackages => '刪除舊版金鑰套件';

  @override
  String keyPackagesCount(int count) {
    return '金鑰套件 ($count)';
  }

  @override
  String get noKeyPackagesFound => '找不到金鑰套件';

  @override
  String get keyPackagePublished => '金鑰套件已發布';

  @override
  String get keyPackagesRefreshed => '金鑰套件已重新整理';

  @override
  String get legacyKeyPackagesDeleted => '舊版金鑰套件已刪除';

  @override
  String get keyPackageDeleted => '金鑰套件已刪除';

  @override
  String get keyPackageFetchFailed => '重新整理金鑰套件失敗。請再試一次。';

  @override
  String get keyPackagePublishFailed => '發布金鑰套件失敗。請再試一次。';

  @override
  String get keyPackageDeleteFailed => '刪除金鑰套件失敗。請再試一次。';

  @override
  String get legacyKeyPackageDeleteFailed => '刪除舊版金鑰套件失敗。請再試一次。';

  @override
  String get legacyLabel => '舊版';

  @override
  String packageNumber(int number) {
    return '金鑰套件 $number';
  }

  @override
  String get goBack => '返回';

  @override
  String get createGroup => '建立群組';

  @override
  String get newGroupChat => '新群組聊天';

  @override
  String get selectMembers => '選擇成員';

  @override
  String selectedCount(int count) {
    return '已選擇 $count 人';
  }

  @override
  String get clearSelection => '清除';

  @override
  String get continueButton => '繼續';

  @override
  String get setUpGroup => '設定群組';

  @override
  String get groupName => '群組名稱';

  @override
  String get groupNamePlaceholder => '輸入群組名稱';

  @override
  String get groupDescription => '群組說明';

  @override
  String get description => '說明';

  @override
  String get groupDescriptionPlaceholder => '這個群組是做什麼用的？';

  @override
  String members(int count) {
    return '$count 名成員';
  }

  @override
  String invitingMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '正在邀請成員：',
      one: '正在邀請成員：',
    );
    return '$_temp0';
  }

  @override
  String get usersWithoutKeyPackages => '沒有金鑰套件的使用者（無法加入）';

  @override
  String usersNotOnWhiteNoise(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '這些使用者尚未使用 White Noise',
      one: '此使用者尚未使用 White Noise',
    );
    return '$_temp0';
  }

  @override
  String usersNotOnWhiteNoiseDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '無法將這些使用者加入群組，因為對方尚未安裝 White Noise，或尚未發布金鑰套件。',
      one: '無法將此使用者加入群組，因為對方尚未安裝 White Noise，或尚未發布金鑰套件。',
    );
    return '$_temp0';
  }

  @override
  String get uploadingImage => '正在上傳圖片...';

  @override
  String get creatingGroup => '正在建立群組...';

  @override
  String get groupNameRequired => '必須填寫群組名稱';

  @override
  String get noUsersWithKeyPackages => '沒有可加入且具備金鑰套件的使用者';

  @override
  String get createGroupFailed => '建立群組失敗';

  @override
  String get reportError => '回報錯誤';

  @override
  String get wipMessage => '我們正在開發此功能。若想支持開發工作，歡迎捐款給 White Noise';

  @override
  String get donate => '捐款';

  @override
  String get chatWithSupport => '聯絡客服';

  @override
  String get supportChatWelcomeMessage => '您好！請告訴我們您的想法，不論是問題、Bug 或建議都可以。我們通常會在幾小時內回覆。';

  @override
  String get addRelay => '新增中繼站';

  @override
  String get restoreDefaultRelays => '還原預設中繼站';

  @override
  String get restoreDefaultRelaysConfirmationTitle => '要還原預設中繼站嗎？';

  @override
  String get restoreDefaultRelaysConfirmationMessage => '確定要還原應用程式的預設中繼站嗎？這會清除並取代您目前的中繼站設定。';

  @override
  String get restoreDefaultRelaysError => '還原預設中繼站失敗。請再試一次。';

  @override
  String get addMyRelay => '新增我的中繼站';

  @override
  String get addInboxRelay => '新增收件匣中繼站';

  @override
  String get addKeyPackageRelay => '新增金鑰套件中繼站';

  @override
  String get enterRelayAddress => '中繼站地址';

  @override
  String get relayAddressPlaceholder => 'wss://relay.example.com';

  @override
  String get removeRelay => '移除中繼站？';

  @override
  String get removeRelayConfirmation => '確定要移除此中繼站嗎？此操作無法復原。';

  @override
  String get remove => '移除';

  @override
  String get messageActions => '訊息操作';

  @override
  String get reply => '回覆';

  @override
  String get copyMessage => '複製';

  @override
  String get copyCode => '複製程式碼';

  @override
  String get copied => '已複製';

  @override
  String get delete => '刪除';

  @override
  String get failedToDeleteMessage => '刪除訊息失敗。請再試一次。';

  @override
  String get failedToSendReaction => '傳送表情回應失敗。請再試一次。';

  @override
  String get failedToRemoveReaction => '移除表情回應失敗。請再試一次。';

  @override
  String get unknownUser => '未知使用者';

  @override
  String get noName => '未命名';

  @override
  String get unknownGroup => '未知群組';

  @override
  String get hasInvitedYouToSecureChat => '邀請您加入安全聊天';

  @override
  String userInvitedYouToSecureChat(String name) {
    return '$name 邀請您加入安全聊天';
  }

  @override
  String get youHaveBeenInvitedToSecureChat => '您已受邀加入安全聊天';

  @override
  String get language => '語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get languageUpdateFailed => '儲存語言偏好失敗。請再試一次。';

  @override
  String get timeJustNow => '剛剛';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分鐘前',
      one: '1 分鐘前',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小時前',
      one: '1 小時前',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前',
      one: '昨天',
    );
    return '$_temp0';
  }

  @override
  String get profile => '個人檔案';

  @override
  String get follow => '追蹤';

  @override
  String get unfollow => '取消追蹤';

  @override
  String chatSearchMatchCount(int current, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total 筆相符',
      one: '1 筆相符',
    );
    return '第 $current 筆，共 $_temp0';
  }

  @override
  String get failedToStartChat => '發起聊天失敗。請再試一次。';

  @override
  String get inviteToWhiteNoise => '邀請加入 White Noise';

  @override
  String inviteToWhiteNoiseDescription(String name) {
    return '$name 尚未加入 White Noise。分享此應用程式即可開始安全聊天。';
  }

  @override
  String get inviteMessage =>
      '來 White Noise 加入我吧。無需手機號碼，沒有監控，真正保有隱私。點這裡下載：https://www.whitenoise.chat/download';

  @override
  String get failedToUpdateFollow => '更新追蹤狀態失敗。請再試一次。';

  @override
  String get imagePickerError => '選取圖片失敗。請再試一次。';

  @override
  String get scanNsec => '掃描 QR 碼';

  @override
  String get scanNsecHint => '掃描您的私鑰 QR 碼以登入。';

  @override
  String get cameraPermissionDenied => '相機權限遭拒';

  @override
  String get somethingWentWrong => '發生錯誤';

  @override
  String get scanNpub => '掃描 QR 碼';

  @override
  String get scanNpubHint => '掃描聯絡人的 QR 碼。';

  @override
  String get invalidNpub => '公鑰無效。請再試一次。';

  @override
  String get you => '您';

  @override
  String get timestampNow => '現在';

  @override
  String timestampMinutes(int count) {
    return '$count 分鐘前';
  }

  @override
  String timestampHours(int count) {
    return '$count 小時前';
  }

  @override
  String get timestampYesterday => '昨天';

  @override
  String get weekdayMonday => '星期一';

  @override
  String get weekdayTuesday => '星期二';

  @override
  String get weekdayWednesday => '星期三';

  @override
  String get weekdayThursday => '星期四';

  @override
  String get weekdayFriday => '星期五';

  @override
  String get weekdaySaturday => '星期六';

  @override
  String get weekdaySunday => '星期日';

  @override
  String get monthJanShort => '1月';

  @override
  String get monthFebShort => '2月';

  @override
  String get monthMarShort => '3月';

  @override
  String get monthAprShort => '4月';

  @override
  String get monthMayShort => '5月';

  @override
  String get monthJunShort => '6月';

  @override
  String get monthJulShort => '7月';

  @override
  String get monthAugShort => '8月';

  @override
  String get monthSepShort => '9月';

  @override
  String get monthOctShort => '10月';

  @override
  String get monthNovShort => '11月';

  @override
  String get monthDecShort => '12月';

  @override
  String get loginWithAmber => '使用 Amber 登入';

  @override
  String get signerConnectionError => '無法連線到簽署器。請再試一次。';

  @override
  String get search => '搜尋';

  @override
  String get filterChats => '聊天';

  @override
  String get filterArchive => '封存';

  @override
  String get signerErrorUserRejected => '登入已取消';

  @override
  String get signerErrorNotConnected => '尚未連線到簽署器。請再試一次。';

  @override
  String get signerErrorNoSigner => '找不到簽署器應用程式。請安裝相容 NIP-55 的簽署器。';

  @override
  String get signerErrorNoResponse => '簽署器沒有回應。請再試一次。';

  @override
  String get signerErrorNoPubkey => '無法從簽署器取得公鑰。';

  @override
  String get signerErrorNoResult => '簽署器沒有回傳結果。';

  @override
  String get signerErrorNoEvent => '簽署器沒有回傳已簽署的事件。';

  @override
  String get signerErrorRequestInProgress => '另一個請求正在處理中。請稍候。';

  @override
  String get signerErrorNoActivity => '無法啟動簽署器。請再試一次。';

  @override
  String get signerErrorLaunchError => '啟動簽署器應用程式失敗。';

  @override
  String get signerErrorUnknown => '簽署器發生錯誤。請再試一次。';

  @override
  String get messageNotFound => '找不到訊息';

  @override
  String get pin => '置頂';

  @override
  String get unpin => '取消置頂';

  @override
  String get mute => '靜音';

  @override
  String get archive => '封存';

  @override
  String get unarchive => '取消封存';

  @override
  String get failedToArchiveChat => '封存聊天失敗。請再試一次。';

  @override
  String get failedToUnarchiveChat => '取消封存聊天失敗。請再試一次。';

  @override
  String get archivedChatsEmpty => '沒有已封存的聊天';

  @override
  String get failedToPinChat => '更新置頂狀態失敗。請再試一次。';

  @override
  String get carouselPrivacyTitle => '隱私與安全';

  @override
  String get carouselPrivacyDescription => '保護您的對話隱私。即使發生資料外洩，您的訊息仍會保持安全。';

  @override
  String get carouselIdentityTitle => '選擇您的身分';

  @override
  String get carouselIdentityDescription => '聊天時不必透露手機號碼或電子郵件。您可以自由選擇身分：真名、筆名或匿名。';

  @override
  String get carouselDecentralizedTitle => '去中心化且無需許可';

  @override
  String get carouselDecentralizedDescription => '沒有任何中央機構能控制您的通訊，不需取得許可，也無法被審查。';

  @override
  String get learnMore => '了解更多';

  @override
  String get backToSignUp => '返回註冊';

  @override
  String get deleteAllData => '刪除所有資料';

  @override
  String get deleteAllDataConfirmation => '要刪除所有資料嗎？';

  @override
  String get deleteAllDataWarning => '這會永久刪除這台裝置上的所有聊天、訊息和設定。此操作無法復原。';

  @override
  String get deleteAllDataError => '刪除所有資料失敗。請再試一次。';

  @override
  String get chatInformation => '聊天資訊';

  @override
  String get addToGroup => '加入群組';

  @override
  String get blockUser => '封鎖使用者';

  @override
  String get unblockUser => '解除封鎖使用者';

  @override
  String get unblock => '解除封鎖';

  @override
  String get failedToBlockUser => '封鎖使用者失敗。請再試一次。';

  @override
  String get failedToUnblockUser => '解除封鎖失敗。請再試一次。';

  @override
  String get userIsBlocked => '您已封鎖此使用者';

  @override
  String get userIsBlockedDescription => '解除封鎖前，您不會收到對方的新訊息。';

  @override
  String get addToAnotherGroup => '加入另一個群組';

  @override
  String get relayResolutionTitle => '中繼站設定';

  @override
  String get relayResolutionDescription => '我們無法在網路上找到您的中繼站清單。您可以提供已發布這些清單的中繼站地址，或使用我們的預設中繼站開始使用。';

  @override
  String get relayResolutionUseDefaults => '使用預設中繼站';

  @override
  String get relayResolutionTryRelay => '搜尋中繼站';

  @override
  String get relayResolutionRelayPlaceholder => 'wss://relay.example.com';

  @override
  String get relayResolutionRelayLabel => '中繼站 URL';

  @override
  String get relayResolutionNotFound => '在此中繼站找不到中繼站清單。請嘗試其他中繼站或使用預設設定。';

  @override
  String get loginErrorInvalidKey => 'nsec 無效。請確認輸入正確。';

  @override
  String get loginErrorNoRelayConnections => '無法連線到任何中繼站。請檢查網路連線後再試一次。';

  @override
  String get loginErrorTimeout => '登入逾時。請再試一次。';

  @override
  String get loginErrorGeneric => '登入時發生錯誤。請再試一次。';

  @override
  String get loginErrorNoLoginInProgress => '目前沒有正在進行的登入。請重新開始。';

  @override
  String get loginErrorInternal => '發生內部錯誤。請再試一次。';

  @override
  String get loginPasteNothingToPaste => '剪貼簿是空的';

  @override
  String get loginPasteFailed => '從剪貼簿貼上失敗';

  @override
  String get openSettings => '開啟設定';

  @override
  String get scannerError => '掃描器錯誤';

  @override
  String get scannerErrorDescription => '掃描器發生問題。請再試一次。';

  @override
  String get cameraPermissionDeniedDescription => '請在裝置設定中開啟相機權限，以掃描 QR 碼。';

  @override
  String get retry => '重試';

  @override
  String get groupInformation => '群組資訊';

  @override
  String get editGroup => '編輯群組';

  @override
  String get editGroupAction => '編輯群組';

  @override
  String get groupNameLabel => '名稱';

  @override
  String get groupDescriptionLabel => '關於';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 名成員',
      one: '1 名成員',
    );
    return '$_temp0';
  }

  @override
  String get adminBadge => '管理員';

  @override
  String get membersLabel => '成員：';

  @override
  String get memberBadge => '成員';

  @override
  String get sendMessage => '傳送訊息';

  @override
  String get makeAdmin => '設為管理員';

  @override
  String get removeAdminRole => '移除管理員身分';

  @override
  String get removeFromGroup => '移出群組';

  @override
  String get removeFromGroupConfirmation => '要移出群組嗎？';

  @override
  String get removeFromGroupWarning => '此成員會被移出群組，且無法再看到新訊息。';

  @override
  String get makeAdminConfirmation => '要設為管理員嗎？';

  @override
  String get makeAdminWarning => '此成員將能管理群組、新增或移除成員，以及變更群組設定。';

  @override
  String get removeAdminConfirmation => '要移除管理員身分嗎？';

  @override
  String get removeAdminWarning => '此成員將不再能管理群組、新增或移除成員，或變更群組設定。';

  @override
  String get failedToRemoveFromGroup => '移除成員失敗。請再試一次。';

  @override
  String get failedToMakeAdmin => '設定管理員失敗。請再試一次。';

  @override
  String get failedToRemoveAdmin => '移除管理員身分失敗。請再試一次。';

  @override
  String get groupUpdatedSuccessfully => '群組已更新';

  @override
  String get groupLoadError => '無法載入群組。請再試一次。';

  @override
  String get groupSaveError => '無法儲存群組。請再試一次。';

  @override
  String get failedToFetchGroupMembers => '載入群組成員失敗。請再試一次。';

  @override
  String get failedToAddMembers => '新增成員失敗。請再試一次。';

  @override
  String get groupImageUploadFailed => '群組已建立，但圖片上傳失敗。';

  @override
  String updateNeeded(String name) {
    return '$name 需要更新';
  }

  @override
  String updateNeededDescription(String name) {
    return '您目前還無法與 $name 開始安全聊天。對方需要先更新 White Noise，才能使用安全通訊。';
  }

  @override
  String addToGroupConfirmation(String userName, String groupName) {
    return '要將 $userName 加入 $groupName 嗎？';
  }

  @override
  String get unknownInviteToWhiteNoiseDescription => '此使用者尚未加入 White Noise。分享此應用程式即可開始安全聊天。';

  @override
  String get unknownUserNeedsUpdate => '需要更新';

  @override
  String get unknownUserNeedsUpdateDescription => '您目前還無法與此使用者開始安全聊天。對方需要先更新 White Noise，才能使用安全通訊。';

  @override
  String get add => '新增';

  @override
  String get noGroupsAvailable => '沒有可用群組';

  @override
  String get noAdminGroupsAvailable => '您目前不是任何群組的管理員。建立群組即可新增成員。';

  @override
  String get profilesTitle => '個人檔案';

  @override
  String get noAccountsAvailable => '沒有可用帳號';

  @override
  String get connectAnotherProfile => '連結另一個帳號';

  @override
  String get rawDebugView => '偵錯模式';

  @override
  String get rawDebugViewDescription => '在聊天中顯示原始訊息資料';

  @override
  String get rawDebugViewTitle => '偵錯模式';

  @override
  String get rawDebugViewGroupId => '群組 ID';

  @override
  String rawDebugViewMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則訊息',
      one: '1 則訊息',
      zero: '沒有訊息',
    );
    return '$_temp0';
  }

  @override
  String get rawDebugViewCopied => '已複製到剪貼簿';

  @override
  String get appLogsTitle => '應用程式記錄';

  @override
  String get appLogsViewLogs => '查看記錄';

  @override
  String get appLogsViewLogsDescription => '在應用程式內查看所有 Logger 輸出';

  @override
  String get appLogsClear => '清除';

  @override
  String get appLogsEraseAll => '全部清除';

  @override
  String get appLogsEmpty => '尚無記錄';

  @override
  String get appLogsSearchPlaceholder => '搜尋記錄...';

  @override
  String get appLogsAddPatternPlaceholder => '新增篩選模式';

  @override
  String get appLogsIgnore => '忽略';

  @override
  String get appLogsShow => '顯示';

  @override
  String get appLogsClearFilters => '清除篩選條件';

  @override
  String get appLogsLive => '即時';

  @override
  String appLogsFilteredCount(int shown, int total) {
    return '$shown / $total';
  }

  @override
  String get appLogsCopyAll => '全部複製';

  @override
  String get invalidRelayUrlScheme => 'URL 必須以 wss:// 或 ws:// 開頭';

  @override
  String get invalidRelayUrl => '中繼站 URL 無效';

  @override
  String get thisMessageWasDeleted => '此訊息已刪除。';

  @override
  String get youDeletedThisMessage => '您已刪除此訊息。';

  @override
  String get relayControlStateLoadError => '載入中繼站控制狀態失敗。請再試一次。';

  @override
  String get updateAvailableTitle => '有新版本可用';

  @override
  String updateAvailableDescription(String version) {
    return '版本 $version 已在 Zapstore 發布。';
  }

  @override
  String get updateNow => '立即更新';

  @override
  String get fatalErrorCopyError => '複製錯誤';

  @override
  String get fatalErrorErrorCopied => '錯誤已複製到剪貼簿';

  @override
  String get fatalErrorTitle => '糟糕！';

  @override
  String get fatalErrorDescription =>
      '載入應用程式時遇到了一點問題。抱歉，這不是您的錯，是我們的問題。\n\n請協助我們修復。點選下方將此錯誤傳送給我們的團隊。';

  @override
  String get reportBug => '回報 Bug';

  @override
  String get reportBugDescription => '請描述您遇到的問題，協助我們改進 White Noise。';

  @override
  String get reportBugWhatWentWrong => '發生了什麼問題？';

  @override
  String get reportBugWhatWentWrongPlaceholder => '請描述您遇到的問題...';

  @override
  String get reportBugStepsToReproduce => '重現步驟';

  @override
  String get reportBugStepsToReproducePlaceholder => '1. 前往...\n2. 點選...\n3. 看到錯誤';

  @override
  String get reportBugFrequency => '這個問題發生的頻率？';

  @override
  String get reportBugFrequencyOnce => '只發生一次';

  @override
  String get reportBugFrequencyAlways => '每次都會';

  @override
  String get reportBugFrequencySometimes => '有時候';

  @override
  String get reportBugIncludeNpub => '包含您的 npub';

  @override
  String get reportBugIncludeNpubDescription => '方便我們在需要時與您聯絡；關閉此選項可保持匿名回報。';

  @override
  String get reportBugSend => '傳送回報';

  @override
  String get reportBugSuccess => 'Bug 回報已送出。謝謝！';

  @override
  String get reportBugError => '傳送回報失敗。請再試一次。';

  @override
  String get reportBugWhatWentWrongRequired => '請描述具體發生了什麼問題。';

  @override
  String get failedToStartSupportChat => '無法發起客服聊天';

  @override
  String get removedFromGroup => '您已被移出此群組';

  @override
  String get youLeftThisGroup => '您已離開此群組';

  @override
  String get removedFromGroupDescription => '您仍可查看已儲存的訊息，但無法傳送或接收新訊息。您可以隨時封存此聊天。';

  @override
  String get notificationSettings => '通知';

  @override
  String get notificationSettingsTitle => '通知';

  @override
  String get notifications => '通知';

  @override
  String get notificationsDescription => '接收新訊息的推播通知';

  @override
  String get notificationsSettingsLoadError => '無法載入通知設定。請再試一次。';

  @override
  String get notificationsSettingsUpdateError => '無法更新通知設定。請再試一次。';

  @override
  String get waitingForInternet => '正在等待網路連線';

  @override
  String get saveToGalleryPermissionDenied => '沒有儲存圖片的權限';

  @override
  String get saveToGalleryNotEnoughSpace => '儲存空間不足';

  @override
  String get saveToGalleryNotSupportedFormat => '不支援此圖片格式';

  @override
  String get saveToGalleryError => '圖片儲存到相簿失敗';

  @override
  String get leave => '離開';

  @override
  String get leaveGroup => '離開群組';

  @override
  String get leaveGroupWarning => '確定要離開此群組嗎？如果您沒有刪除聊天，它仍會留在列表中；但除非有人再次邀請您，否則您將無法傳送或接收新訊息。';

  @override
  String get failedToLeaveGroup => '離開群組失敗。請再試一次。';

  @override
  String get youLeftTheGroup => '您已離開群組';
}
