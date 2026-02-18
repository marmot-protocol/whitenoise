// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'White Noise';

  @override
  String get sloganDecentralized => 'Децентрализованный';

  @override
  String get sloganUncensorable => 'Нецензурируемый';

  @override
  String get sloganSecureMessaging => 'Безопасный Мессенджер';

  @override
  String get login => 'Войти';

  @override
  String get signUp => 'Регистрация';

  @override
  String get loginTitle => 'Войти';

  @override
  String get enterPrivateKey => 'Введите ваш приватный ключ';

  @override
  String get nsecPlaceholder => 'nsec...';

  @override
  String get setupProfile => 'Настройка профиля';

  @override
  String get chooseName => 'Выберите имя';

  @override
  String get enterYourName => 'Введите ваше имя';

  @override
  String get introduceYourself => 'Расскажите о себе';

  @override
  String get writeSomethingAboutYourself => 'Напишите что-нибудь о себе';

  @override
  String get cancel => 'Отмена';

  @override
  String get profileReady => 'Ваш профиль готов!';

  @override
  String get startConversationHint =>
      'Начните разговор, добавив друзей или поделившись своим профилем.';

  @override
  String get shareYourProfile => 'Поделиться профилем';

  @override
  String get startChat => 'Начать чат';

  @override
  String get settings => 'Настройки';

  @override
  String get shareAndConnect => 'Поделиться и подключиться';

  @override
  String get switchProfile => 'Сменить профиль';

  @override
  String get addNewProfile => 'Добавить новый профиль';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get profileKeys => 'Ключи профиля';

  @override
  String get networkRelays => 'Сетевые реле';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get privacySecurity => 'Конфиденциальность и безопасность';

  @override
  String get donateToWhiteNoise => 'Пожертвовать White Noise';

  @override
  String get developerSettings => 'Настройки разработчика';

  @override
  String get signOut => 'Выйти';

  @override
  String get appearanceTitle => 'Внешний вид';

  @override
  String get privacySecurityTitle => 'Конфиденциальность и безопасность';

  @override
  String get deleteAllAppData => 'Удалить все данные приложения';

  @override
  String get deleteAppData => 'Удалить данные приложения';

  @override
  String get deleteAllAppDataDescription =>
      'Удалить все профили, ключи, чаты и локальные файлы с этого устройства.';

  @override
  String get deleteAllAppDataConfirmation => 'Удалить все данные приложения?';

  @override
  String get deleteAllAppDataWarning =>
      'Будут удалены все профили, ключи, чаты и локальные файлы с этого устройства. Это действие нельзя отменить.';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get profileKeysTitle => 'Ключи профиля';

  @override
  String get publicKey => 'Публичный ключ';

  @override
  String get publicKeyCopied => 'Публичный ключ скопирован в буфер обмена';

  @override
  String get publicKeyDescription =>
      'Ваш публичный ключ (npub) можно делиться с другими. Он используется для вашей идентификации в сети.';

  @override
  String get privateKey => 'Приватный ключ';

  @override
  String get privateKeyCopied => 'Приватный ключ скопирован в буфер обмена';

  @override
  String get privateKeyDescription =>
      'Ваш приватный ключ (nsec) должен оставаться секретным. Любой, кто имеет к нему доступ, может контролировать ваш аккаунт.';

  @override
  String get keepPrivateKeySecure => 'Храните приватный ключ в безопасности';

  @override
  String get privateKeyWarning =>
      'Не делитесь приватным ключом публично и используйте его только для входа в другие приложения Nostr.';

  @override
  String get nsecOnExternalSigner => 'Закрытый ключ хранится во внешнем приложении';

  @override
  String get nsecOnExternalSignerDescription =>
      'Ваш закрытый ключ недоступен в White Noise. Откройте ваше приложение для подписи, чтобы просмотреть или управлять им.';

  @override
  String get editProfileTitle => 'Редактировать профиль';

  @override
  String get profileName => 'Имя профиля';

  @override
  String get nostrAddress => 'Адрес Nostr';

  @override
  String get nostrAddressPlaceholder => 'example@whitenoise.chat';

  @override
  String get aboutYou => 'О вас';

  @override
  String get profileIsPublic => 'Профиль публичный';

  @override
  String get profilePublicDescription => 'Информация вашего профиля будет видна всем в сети.';

  @override
  String get discard => 'Отменить';

  @override
  String get discardChanges => 'Отменить изменения';

  @override
  String get save => 'Сохранить';

  @override
  String get profileUpdatedSuccessfully => 'Профиль успешно обновлён';

  @override
  String errorLoadingProfile(String error) {
    return 'Ошибка загрузки профиля: $error';
  }

  @override
  String error(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get profileLoadError => 'Не удалось загрузить профиль. Пожалуйста, попробуйте снова.';

  @override
  String get failedToLoadPrivateKey =>
      'Не удалось загрузить приватный ключ. Пожалуйста, попробуйте снова.';

  @override
  String get profileSaveError => 'Не удалось сохранить профиль. Пожалуйста, попробуйте снова.';

  @override
  String get networkRelaysTitle => 'Сетевые Реле';

  @override
  String get myRelays => 'Мои Реле';

  @override
  String get myRelaysHelp =>
      'Реле, которые вы определили для использования во всех ваших приложениях Nostr.';

  @override
  String get inboxRelays => 'Входящие Реле';

  @override
  String get inboxRelaysHelp =>
      'Реле для получения приглашений и начала безопасных разговоров с новыми пользователями.';

  @override
  String get keyPackageRelays => 'Реле Пакетов Ключей';

  @override
  String get keyPackageRelaysHelp =>
      'Реле, которые хранят ваш безопасный ключ, чтобы другие могли приглашать вас в зашифрованные разговоры.';

  @override
  String get errorLoadingRelays => 'Ошибка загрузки реле';

  @override
  String get noRelaysConfigured => 'Реле не настроены';

  @override
  String get donateTitle => 'Пожертвовать White Noise';

  @override
  String get donateDescription =>
      'Как некоммерческая организация, White Noise существует исключительно для вашей конфиденциальности и свободы, а не для прибыли. Ваша поддержка сохраняет нашу независимость и бескомпромиссность.';

  @override
  String get lightningAddress => 'Адрес Lightning';

  @override
  String get bitcoinSilentPayment => 'Тихий Платёж Bitcoin';

  @override
  String get copiedToClipboardThankYou => 'Скопировано в буфер обмена. Спасибо!';

  @override
  String get shareProfileTitle => 'Поделиться профилем';

  @override
  String get scanToConnect => 'Сканируйте для подключения';

  @override
  String get signOutTitle => 'Выход';

  @override
  String get signOutConfirmation => 'Вы уверены, что хотите выйти?';

  @override
  String get signOutWarning =>
      'Когда вы выходите из White Noise, ваши чаты будут удалены с этого устройства и не могут быть восстановлены на другом устройстве.';

  @override
  String get signOutWarningBackupKey =>
      'Если вы не сделали резервную копию приватного ключа, вы не сможете использовать этот профиль в любом другом сервисе Nostr.';

  @override
  String get backUpPrivateKey => 'Сделайте резервную копию приватного ключа';

  @override
  String get copyPrivateKeyHint =>
      'Скопируйте приватный ключ для восстановления аккаунта на другом устройстве.';

  @override
  String get publicKeyCopyError => 'Не удалось скопировать публичный ключ. Попробуйте снова.';

  @override
  String get noChatsYet => 'Пока нет чатов';

  @override
  String get startConversation => 'Начните разговор';

  @override
  String get welcomeNoticeTitle => 'Ваш профиль готов';

  @override
  String welcomeNoticeDescription(String findPeople, String shareProfile, String startANewChat) {
    return 'Нажмите $findPeople, чтобы найти друзей. $shareProfile, чтобы связаться со знакомыми, или $startANewChat, используя иконку чата.';
  }

  @override
  String get findPeople => 'Найти людей';

  @override
  String get startANewChat => 'начните новый чат';

  @override
  String get noMessagesYet => 'Пока нет сообщений';

  @override
  String get messagePlaceholder => 'Сообщение';

  @override
  String get failedToSendMessage => 'Не удалось отправить сообщение. Попробуйте снова.';

  @override
  String get invitedToSecureChat => 'Вы приглашены в безопасный чат';

  @override
  String get decline => 'Отклонить';

  @override
  String get accept => 'Принять';

  @override
  String failedToAcceptInvitation(String error) {
    return 'Не удалось принять приглашение: $error';
  }

  @override
  String failedToDeclineInvitation(String error) {
    return 'Не удалось отклонить приглашение: $error';
  }

  @override
  String get startNewChat => 'Новый чат';

  @override
  String get noResults => 'Нет результатов';

  @override
  String get noFollowsYet => 'Пока нет подписок';

  @override
  String get searchByNameOrNpub => 'Имя или npub1...';

  @override
  String get developerSettingsTitle => 'Настройки Разработчика';

  @override
  String get publishNewKeyPackage => 'Опубликовать Новый Пакет Ключей';

  @override
  String get refreshKeyPackages => 'Обновить Пакеты Ключей';

  @override
  String get deleteAllKeyPackages => 'Удалить Все Пакеты Ключей';

  @override
  String keyPackagesCount(int count) {
    return 'Пакеты Ключей ($count)';
  }

  @override
  String get noKeyPackagesFound => 'Пакеты ключей не найдены';

  @override
  String get keyPackagePublished => 'Пакет ключей опубликован';

  @override
  String get keyPackagesRefreshed => 'Пакеты ключей обновлены';

  @override
  String get keyPackagesDeleted => 'Все пакеты ключей удалены';

  @override
  String get keyPackageDeleted => 'Пакет ключей удалён';

  @override
  String packageNumber(int number) {
    return 'Пакет $number';
  }

  @override
  String get goBack => 'Назад';

  @override
  String get createGroup => 'Создать группу';

  @override
  String get newGroupChat => 'Новый групповой чат';

  @override
  String get selectMembers => 'Выбрать Участников';

  @override
  String selectedCount(int count) {
    return '$count выбрано';
  }

  @override
  String get clearSelection => 'Очистить';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get setUpGroup => 'Настроить группу';

  @override
  String get groupName => 'Название Группы';

  @override
  String get groupNamePlaceholder => 'Введите название группы';

  @override
  String get groupDescription => 'Описание Группы';

  @override
  String get description => 'Описание';

  @override
  String get groupDescriptionPlaceholder => 'Для чего эта группа?';

  @override
  String members(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count участников',
      many: '$count участников',
      few: '$count участника',
      one: '1 участник',
    );
    return '$_temp0';
  }

  @override
  String invitingMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Приглашение участников:',
      many: 'Приглашение участников:',
      few: 'Приглашение участников:',
      one: 'Приглашение участника:',
    );
    return '$_temp0';
  }

  @override
  String get usersWithoutKeyPackages =>
      'Пользователи без ключевых пакетов (не могут быть добавлены)';

  @override
  String usersNotOnWhiteNoise(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Эти пользователи не в White Noise',
      many: 'Эти пользователи не в White Noise',
      few: 'Эти пользователи не в White Noise',
      one: 'Этот пользователь не в White Noise',
    );
    return '$_temp0';
  }

  @override
  String usersNotOnWhiteNoiseDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Эти пользователи не могут быть добавлены в группу, потому что у них не установлен White Noise или они еще не опубликовали свои ключевые пакеты.',
      many:
          'Эти пользователи не могут быть добавлены в группу, потому что у них не установлен White Noise или они еще не опубликовали свои ключевые пакеты.',
      few:
          'Эти пользователи не могут быть добавлены в группу, потому что у них не установлен White Noise или они еще не опубликовали свои ключевые пакеты.',
      one:
          'Этот пользователь не может быть добавлен в группу, потому что у него не установлен White Noise или он еще не опубликовал свой ключевой пакет.',
    );
    return '$_temp0';
  }

  @override
  String get uploadingImage => 'Загрузка изображения...';

  @override
  String get creatingGroup => 'Создание группы...';

  @override
  String get groupNameRequired => 'Требуется название группы';

  @override
  String get noUsersWithKeyPackages => 'Нет пользователей с ключевыми пакетами для добавления';

  @override
  String get createGroupFailed => 'Не удалось создать группу';

  @override
  String get reportError => 'Сообщить об ошибке';

  @override
  String get workInProgress => 'Мы работаем над этим';

  @override
  String get wipMessage =>
      'Мы работаем над этой функцией. Чтобы поддержать разработку, пожертвуйте на проект White Noise';

  @override
  String get donate => 'Пожертвовать';

  @override
  String get addRelay => 'Добавить Реле';

  @override
  String get enterRelayAddress => 'Введите адрес реле';

  @override
  String get relayAddressPlaceholder => 'wss://relay.example.com';

  @override
  String get removeRelay => 'Удалить Реле?';

  @override
  String get removeRelayConfirmation =>
      'Вы уверены, что хотите удалить это реле? Это действие нельзя отменить.';

  @override
  String get remove => 'Удалить';

  @override
  String get messageActions => 'Действия с сообщением';

  @override
  String get reply => 'Ответить';

  @override
  String get copyMessage => 'Копировать';

  @override
  String get delete => 'Удалить';

  @override
  String get failedToDeleteMessage => 'Не удалось удалить сообщение. Попробуйте снова.';

  @override
  String get failedToSendReaction => 'Не удалось отправить реакцию. Попробуйте снова.';

  @override
  String get failedToRemoveReaction => 'Не удалось удалить реакцию. Попробуйте снова.';

  @override
  String get unknownUser => 'Неизвестный пользователь';

  @override
  String get unknownGroup => 'Неизвестная группа';

  @override
  String get hasInvitedYouToSecureChat => 'Пригласил вас в безопасный чат';

  @override
  String userInvitedYouToSecureChat(String name) {
    return '$name пригласил вас в безопасный чат';
  }

  @override
  String get youHaveBeenInvitedToSecureChat => 'Вы были приглашены в безопасный чат';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Системный';

  @override
  String get languageUpdateFailed => 'Не удалось сохранить языковые настройки. Попробуйте снова.';

  @override
  String get timeJustNow => 'только что';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минут назад',
      many: '$count минут назад',
      few: '$count минуты назад',
      one: '1 минуту назад',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часов назад',
      many: '$count часов назад',
      few: '$count часа назад',
      one: '1 час назад',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней назад',
      many: '$count дней назад',
      few: '$count дня назад',
      one: 'вчера',
    );
    return '$_temp0';
  }

  @override
  String get profile => 'Профиль';

  @override
  String get follow => 'Подписаться';

  @override
  String get unfollow => 'Отписаться';

  @override
  String get failedToStartChat => 'Не удалось начать чат. Попробуйте снова.';

  @override
  String get inviteToWhiteNoise => 'Пригласить в White Noise';

  @override
  String inviteToWhiteNoiseDescription(String name) {
    return '$name ещё не в White Noise. Поделитесь приложением, чтобы начать безопасный чат.';
  }

  @override
  String get failedToUpdateFollow => 'Не удалось обновить статус подписки. Попробуйте снова.';

  @override
  String get imagePickerError => 'Не удалось выбрать изображение. Попробуйте снова.';

  @override
  String get scanNsec => 'Сканировать QR-код';

  @override
  String get scanNsecHint => 'Отсканируйте QR-код вашего приватного ключа для входа.';

  @override
  String get cameraPermissionDenied => 'Доступ к камере запрещён';

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get scanNpub => 'Сканировать QR-код';

  @override
  String get scanNpubHint => 'Отсканируйте QR-код контакта.';

  @override
  String get invalidNpub => 'Недействительный публичный ключ. Попробуйте снова.';

  @override
  String get you => 'Вы';

  @override
  String get timestampNow => 'Сейчас';

  @override
  String timestampMinutes(int count) {
    return '$countм';
  }

  @override
  String timestampHours(int count) {
    return '$countч';
  }

  @override
  String get timestampYesterday => 'Вчера';

  @override
  String get weekdayMonday => 'Понедельник';

  @override
  String get weekdayTuesday => 'Вторник';

  @override
  String get weekdayWednesday => 'Среда';

  @override
  String get weekdayThursday => 'Четверг';

  @override
  String get weekdayFriday => 'Пятница';

  @override
  String get weekdaySaturday => 'Суббота';

  @override
  String get weekdaySunday => 'Воскресенье';

  @override
  String get monthJanShort => 'Янв';

  @override
  String get monthFebShort => 'Фев';

  @override
  String get monthMarShort => 'Мар';

  @override
  String get monthAprShort => 'Апр';

  @override
  String get monthMayShort => 'Май';

  @override
  String get monthJunShort => 'Июн';

  @override
  String get monthJulShort => 'Июл';

  @override
  String get monthAugShort => 'Авг';

  @override
  String get monthSepShort => 'Сен';

  @override
  String get monthOctShort => 'Окт';

  @override
  String get monthNovShort => 'Ноя';

  @override
  String get monthDecShort => 'Дек';

  @override
  String get loginWithAmber => 'Войти через Amber';

  @override
  String get signerConnectionError => 'Не удалось подключиться к signer. Попробуйте снова.';

  @override
  String get search => 'Поиск';

  @override
  String get filterChats => 'Чаты';

  @override
  String get filterArchive => 'Архив';

  @override
  String get signerErrorUserRejected => 'Вход отменён';

  @override
  String get signerErrorNotConnected => 'Нет подключения к signer. Попробуйте снова.';

  @override
  String get signerErrorNoSigner =>
      'Приложение signer не найдено. Установите совместимый с NIP-55 signer.';

  @override
  String get signerErrorNoResponse => 'Нет ответа от signer. Попробуйте снова.';

  @override
  String get signerErrorNoPubkey => 'Не удалось получить публичный ключ от signer.';

  @override
  String get signerErrorNoResult => 'Signer не вернул результат.';

  @override
  String get signerErrorNoEvent => 'Signer не вернул подписанное событие.';

  @override
  String get signerErrorRequestInProgress => 'Выполняется другой запрос. Подождите.';

  @override
  String get signerErrorNoActivity => 'Не удалось запустить signer. Попробуйте снова.';

  @override
  String get signerErrorLaunchError => 'Не удалось запустить приложение signer.';

  @override
  String get signerErrorUnknown => 'Произошла ошибка с signer. Попробуйте снова.';

  @override
  String get messageNotFound => 'Сообщение не найдено';

  @override
  String get pin => 'Закрепить';

  @override
  String get unpin => 'Открепить';

  @override
  String get mute => 'Без звука';

  @override
  String get archive => 'Архивировать';

  @override
  String get failedToPinChat => 'Не удалось закрепить. Попробуйте снова.';

  @override
  String get carouselPrivacyTitle => 'Конфиденциальность и безопасность';

  @override
  String get carouselPrivacyDescription =>
      'Сохраняйте конфиденциальность ваших разговоров. Даже в случае утечки ваши сообщения остаются защищёнными.';

  @override
  String get carouselIdentityTitle => 'Выберите свою личность';

  @override
  String get carouselIdentityDescription =>
      'Общайтесь, не раскрывая номер телефона или email. Выбирайте: настоящее имя, псевдоним или анонимность.';

  @override
  String get carouselDecentralizedTitle => 'Децентрализованный и без разрешений';

  @override
  String get carouselDecentralizedDescription =>
      'Никакая центральная власть не контролирует вашу коммуникацию – разрешения не нужны, цензура невозможна.';

  @override
  String get learnMore => 'Узнать больше';

  @override
  String get backToSignUp => 'Вернуться к регистрации';

  @override
  String get deleteAllData => 'Удалить все данные';

  @override
  String get deleteAllDataConfirmation => 'Удалить все данные?';

  @override
  String get deleteAllDataWarning =>
      'Это действие безвозвратно удалит все ваши чаты, сообщения и настройки с этого устройства. Отменить невозможно.';

  @override
  String get deleteAllDataError => 'Не удалось удалить все данные. Пожалуйста, попробуйте снова.';

  @override
  String get chatInformation => 'Информация о чате';

  @override
  String get addAsContact => 'Добавить в контакты';

  @override
  String get removeAsContact => 'Удалить из контактов';

  @override
  String get addToGroup => 'Добавить в группу';

  @override
  String get relayResolutionTitle => 'Настройка реле';

  @override
  String get relayResolutionDescription =>
      'Мы не нашли ваши списки реле в сети. Вы можете указать реле, где опубликованы ваши списки, или использовать наши стандартные реле для начала работы.';

  @override
  String get relayResolutionUseDefaults => 'Использовать стандартные реле';

  @override
  String get relayResolutionTryRelay => 'Поиск реле';

  @override
  String get relayResolutionRelayPlaceholder => 'wss://relay.example.com';

  @override
  String get relayResolutionRelayLabel => 'URL реле';

  @override
  String get relayResolutionNotFound =>
      'На этом реле не найдено списков. Попробуйте другое или используйте стандартные.';

  @override
  String get loginErrorInvalidKey =>
      'Неверный формат приватного ключа. Пожалуйста, проверьте и попробуйте снова.';

  @override
  String get loginErrorNoRelayConnections =>
      'Не удалось подключиться ни к одному реле. Проверьте соединение и попробуйте снова.';

  @override
  String get loginErrorTimeout => 'Время входа истекло. Пожалуйста, попробуйте снова.';

  @override
  String get loginErrorGeneric => 'Произошла ошибка при входе. Пожалуйста, попробуйте снова.';

  @override
  String get loginErrorNoLoginInProgress => 'Нет активного входа. Пожалуйста, начните сначала.';

  @override
  String get loginErrorInternal => 'Произошла внутренняя ошибка. Пожалуйста, попробуйте снова.';

  @override
  String get loginPasteNothingToPaste => 'Нечего вставить';

  @override
  String get loginPasteFailed => 'Не удалось вставить из буфера обмена';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get scannerError => 'Ошибка сканера';

  @override
  String get scannerErrorDescription => 'Произошла ошибка сканера. Пожалуйста, попробуйте снова.';

  @override
  String get cameraPermissionDeniedDescription =>
      'Пожалуйста, включите доступ к камере в настройках устройства для сканирования QR-кодов.';

  @override
  String get retry => 'Повторить';
}
