// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'White Noise';

  @override
  String get sloganDecentralized => 'Merkezi Olmayan';

  @override
  String get sloganUncensorable => 'Sansürlenemez';

  @override
  String get sloganSecureMessaging => 'Güvenli Mesajlaşma';

  @override
  String get login => 'Giriş Yap';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get loginTitle => 'Giriş Yap';

  @override
  String get enterPrivateKey => 'Özel anahtarınızı girin';

  @override
  String get nsecPlaceholder => 'nsec...';

  @override
  String get setupProfile => 'Profil ayarla';

  @override
  String get chooseName => 'Bir isim seçin';

  @override
  String get enterYourName => 'Adınızı girin';

  @override
  String get introduceYourself => 'Kendinizi tanıtın';

  @override
  String get writeSomethingAboutYourself => 'Kendiniz hakkında bir şeyler yazın';

  @override
  String get cancel => 'İptal';

  @override
  String get profileReady => 'Profiliniz hazır!';

  @override
  String get startConversationHint =>
      'Arkadaş ekleyerek veya profilinizi paylaşarak bir sohbet başlatın.';

  @override
  String get shareYourProfile => 'Profilini paylaş';

  @override
  String get startChat => 'Sohbet başlat';

  @override
  String get settings => 'Ayarlar';

  @override
  String get shareAndConnect => 'Paylaş ve bağlan';

  @override
  String get switchProfile => 'Profil değiştir';

  @override
  String get addNewProfile => 'Yeni profil ekle';

  @override
  String get editProfile => 'Profili düzenle';

  @override
  String get profileKeys => 'Profil anahtarları';

  @override
  String get networkRelays => 'Ağ röleleri';

  @override
  String get appearance => 'Görünüm';

  @override
  String get privacySecurity => 'Gizlilik ve güvenlik';

  @override
  String get donateToWhiteNoise => 'White Noise\'a bağış yap';

  @override
  String get developerSettings => 'Geliştirici ayarları';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get appearanceTitle => 'Görünüm';

  @override
  String get privacySecurityTitle => 'Gizlilik ve güvenlik';

  @override
  String get deleteAllAppData => 'Tüm Uygulama Verilerini Sil';

  @override
  String get deleteAppData => 'Uygulama verilerini sil';

  @override
  String get deleteAllAppDataDescription =>
      'Bu cihazdaki tüm profilleri, anahtarları, sohbetleri ve yerel dosyaları sil.';

  @override
  String get deleteAllAppDataConfirmation => 'Tüm uygulama verileri silinsin mi?';

  @override
  String get deleteAllAppDataWarning =>
      'Bu cihazdaki tüm profiller, anahtarlar, sohbetler ve yerel dosyalar silinecektir. Bu işlem geri alınamaz.';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get profileKeysTitle => 'Profil anahtarları';

  @override
  String get publicKey => 'Açık anahtar';

  @override
  String get publicKeyCopied => 'Açık anahtar panoya kopyalandı';

  @override
  String get publicKeyDescription =>
      'Açık anahtarınız (npub) başkalarıyla paylaşılabilir. Ağda sizi tanımlamak için kullanılır.';

  @override
  String get privateKey => 'Özel anahtar';

  @override
  String get privateKeyCopied => 'Özel anahtar panoya kopyalandı';

  @override
  String get privateKeyDescription =>
      'Özel anahtarınız (nsec) gizli tutulmalıdır. Erişimi olan herkes hesabınızı kontrol edebilir.';

  @override
  String get keepPrivateKeySecure => 'Özel anahtarınızı güvende tutun';

  @override
  String get privateKeyWarning =>
      'Özel anahtarınızı herkese açık paylaşmayın ve yalnızca diğer Nostr uygulamalarına giriş yapmak için kullanın.';

  @override
  String get nsecOnExternalSigner => 'Özel anahtar harici bir imzalayıcıda saklanıyor';

  @override
  String get nsecOnExternalSignerDescription =>
      'Özel anahtarınız White Noise\'da mevcut değil. Görüntülemek veya yönetmek için imzalayıcınızı açın.';

  @override
  String get editProfileTitle => 'Profili düzenle';

  @override
  String get profileName => 'Profil adı';

  @override
  String get nostrAddress => 'Nostr adresi';

  @override
  String get nostrAddressPlaceholder => 'ornek@whitenoise.chat';

  @override
  String get aboutYou => 'Hakkınızda';

  @override
  String get profileIsPublic => 'Profil herkese açık';

  @override
  String get profilePublicDescription =>
      'Profil bilgileriniz ağdaki herkes tarafından görülebilir.';

  @override
  String get discard => 'At';

  @override
  String get discardChanges => 'Değişiklikleri at';

  @override
  String get save => 'Kaydet';

  @override
  String get profileUpdatedSuccessfully => 'Profil başarıyla güncellendi';

  @override
  String errorLoadingProfile(String error) {
    return 'Profil yüklenirken hata: $error';
  }

  @override
  String error(String error) {
    return 'Hata: $error';
  }

  @override
  String get profileLoadError => 'Profil yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String get failedToLoadPrivateKey => 'Özel anahtar yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String get profileSaveError => 'Profil kaydedilemedi. Lütfen tekrar deneyin.';

  @override
  String get networkRelaysTitle => 'Ağ Röleleri';

  @override
  String get myRelays => 'Rölelerim';

  @override
  String get myRelaysHelp => 'Tüm Nostr uygulamalarınızda kullanmak üzere tanımladığınız röleler.';

  @override
  String get inboxRelays => 'Gelen Kutusu Röleleri';

  @override
  String get inboxRelaysHelp =>
      'Davet almak ve yeni kullanıcılarla güvenli sohbetler başlatmak için kullanılan röleler.';

  @override
  String get keyPackageRelays => 'Anahtar Paketi Röleleri';

  @override
  String get keyPackageRelaysHelp =>
      'Başkalarının sizi şifreli sohbetlere davet edebilmesi için güvenli anahtarınızı saklayan röleler.';

  @override
  String get errorLoadingRelays => 'Röleler yüklenirken hata';

  @override
  String get noRelaysConfigured => 'Yapılandırılmış röle yok';

  @override
  String get donateTitle => 'White Noise\'a Bağış Yap';

  @override
  String get donateDescription =>
      'Kar amacı gütmeyen bir kuruluş olarak White Noise, yalnızca gizliliğiniz ve özgürlüğünüz için var, kar için değil. Desteğiniz bizi bağımsız ve taviz vermeden tutar.';

  @override
  String get lightningAddress => 'Lightning Adresi';

  @override
  String get bitcoinSilentPayment => 'Bitcoin Sessiz Ödeme';

  @override
  String get copiedToClipboardThankYou => 'Panoya kopyalandı. Teşekkürler!';

  @override
  String get shareProfileTitle => 'Profili paylaş';

  @override
  String get scanToConnect => 'Bağlanmak için tarayın';

  @override
  String get signOutTitle => 'Çıkış yap';

  @override
  String get signOutConfirmation => 'Çıkış yapmak istediğinizden emin misiniz?';

  @override
  String get signOutWarning =>
      'White Noise\'dan çıkış yaptığınızda, sohbetleriniz bu cihazdan silinecek ve başka bir cihazda geri yüklenemeyecektir.';

  @override
  String get signOutWarningBackupKey =>
      'Özel anahtarınızı yedeklemediyseniz, bu profili başka hiçbir Nostr hizmetinde kullanamazsınız.';

  @override
  String get backUpPrivateKey => 'Özel anahtarınızı yedekleyin';

  @override
  String get copyPrivateKeyHint =>
      'Hesabınızı başka bir cihazda geri yüklemek için özel anahtarınızı kopyalayın.';

  @override
  String get publicKeyCopyError => 'Açık anahtar kopyalanamadı. Lütfen tekrar deneyin.';

  @override
  String get noChatsYet => 'Henüz sohbet yok';

  @override
  String get startConversation => 'Bir sohbet başlatın';

  @override
  String get welcomeNoticeTitle => 'Profiliniz hazır';

  @override
  String welcomeNoticeDescription(String findPeople, String shareProfile, String startANewChat) {
    return 'Arkadaşlarınızı bulmak için $findPeople\'a dokunun. Tanıdığınız kişilerle bağlantı kurmak için $shareProfile veya sohbet artı simgesini kullanarak $startANewChat.';
  }

  @override
  String get findPeople => 'Kişi bul';

  @override
  String get startANewChat => 'yeni bir sohbet başlatın';

  @override
  String get noMessagesYet => 'Henüz mesaj yok';

  @override
  String get messagePlaceholder => 'Mesaj';

  @override
  String get failedToSendMessage => 'Mesaj gönderilemedi. Lütfen tekrar deneyin.';

  @override
  String get invitedToSecureChat => 'Güvenli bir sohbete davet edildiniz';

  @override
  String get decline => 'Reddet';

  @override
  String get accept => 'Kabul et';

  @override
  String failedToAcceptInvitation(String error) {
    return 'Davet kabul edilemedi: $error';
  }

  @override
  String failedToDeclineInvitation(String error) {
    return 'Davet reddedilemedi: $error';
  }

  @override
  String get startNewChat => 'Yeni sohbet';

  @override
  String get noResults => 'Sonuç yok';

  @override
  String get noFollowsYet => 'Henüz takip yok';

  @override
  String get searchByNameOrNpub => 'Ad veya npub1...';

  @override
  String get developerSettingsTitle => 'Geliştirici Ayarları';

  @override
  String get publishNewKeyPackage => 'Yeni Anahtar Paketi Yayınla';

  @override
  String get refreshKeyPackages => 'Anahtar Paketlerini Yenile';

  @override
  String get deleteAllKeyPackages => 'Tüm Anahtar Paketlerini Sil';

  @override
  String keyPackagesCount(int count) {
    return 'Anahtar Paketleri ($count)';
  }

  @override
  String get noKeyPackagesFound => 'Anahtar paketi bulunamadı';

  @override
  String get keyPackagePublished => 'Anahtar paketi yayınlandı';

  @override
  String get keyPackagesRefreshed => 'Anahtar paketleri yenilendi';

  @override
  String get keyPackagesDeleted => 'Tüm anahtar paketleri silindi';

  @override
  String get keyPackageDeleted => 'Anahtar paketi silindi';

  @override
  String packageNumber(int number) {
    return 'Paket $number';
  }

  @override
  String get goBack => 'Geri dön';

  @override
  String get createGroup => 'Grup oluştur';

  @override
  String get newGroupChat => 'Yeni grup sohbeti';

  @override
  String get selectMembers => 'Üye Seç';

  @override
  String selectedCount(int count) {
    return '$count seçildi';
  }

  @override
  String get clearSelection => 'Temizle';

  @override
  String get continueButton => 'Devam Et';

  @override
  String get setUpGroup => 'Grup oluştur';

  @override
  String get groupName => 'Grup Adı';

  @override
  String get groupNamePlaceholder => 'Grup adını girin';

  @override
  String get groupDescription => 'Grup Açıklaması';

  @override
  String get description => 'Açıklama';

  @override
  String get groupDescriptionPlaceholder => 'Bu grup ne için?';

  @override
  String members(int count) {
    return '$count üye';
  }

  @override
  String invitingMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Üyeler davet ediliyor:',
      one: 'Üye davet ediliyor:',
    );
    return '$_temp0';
  }

  @override
  String get usersWithoutKeyPackages => 'Anahtar paketi olmayan kullanıcılar (eklenemez)';

  @override
  String usersNotOnWhiteNoise(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu kullanıcılar White Noise\'da değil',
      one: 'Bu kullanıcı White Noise\'da değil',
    );
    return '$_temp0';
  }

  @override
  String usersNotOnWhiteNoiseDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bu kullanıcılar gruba eklenemez çünkü White Noise yüklü değil veya henüz anahtar paketlerini yayınlamamışlar.',
      one:
          'Bu kullanıcı gruba eklenemez çünkü White Noise yüklü değil veya henüz anahtar paketini yayınlamamış.',
    );
    return '$_temp0';
  }

  @override
  String get uploadingImage => 'Resim yükleniyor...';

  @override
  String get creatingGroup => 'Grup oluşturuluyor...';

  @override
  String get groupNameRequired => 'Grup adı gerekli';

  @override
  String get noUsersWithKeyPackages => 'Eklenecek anahtar paketi olan kullanıcı yok';

  @override
  String get createGroupFailed => 'Grup oluşturma başarısız oldu';

  @override
  String get reportError => 'Hata bildir';

  @override
  String get workInProgress => 'Bunun üzerinde çalışıyoruz';

  @override
  String get wipMessage =>
      'Bu özellik üzerinde çalışıyoruz. Geliştirmeyi desteklemek için lütfen White Noise\'a bağış yapın';

  @override
  String get donate => 'Bağış yap';

  @override
  String get addRelay => 'Röle Ekle';

  @override
  String get enterRelayAddress => 'Röle adresini girin';

  @override
  String get relayAddressPlaceholder => 'wss://relay.example.com';

  @override
  String get removeRelay => 'Röle Kaldırılsın mı?';

  @override
  String get removeRelayConfirmation =>
      'Bu röleyi kaldırmak istediğinizden emin misiniz? Bu işlem geri alınamaz.';

  @override
  String get remove => 'Kaldır';

  @override
  String get messageActions => 'Mesaj işlemleri';

  @override
  String get reply => 'Yanıtla';

  @override
  String get copyMessage => 'Kopyala';

  @override
  String get delete => 'Sil';

  @override
  String get failedToDeleteMessage => 'Mesaj silinemedi. Lütfen tekrar deneyin.';

  @override
  String get failedToSendReaction => 'Tepki gönderilemedi. Lütfen tekrar deneyin.';

  @override
  String get failedToRemoveReaction => 'Tepki kaldırılamadı. Lütfen tekrar deneyin.';

  @override
  String get unknownUser => 'Bilinmeyen kullanıcı';

  @override
  String get unknownGroup => 'Bilinmeyen grup';

  @override
  String get hasInvitedYouToSecureChat => 'Sizi güvenli bir sohbete davet etti';

  @override
  String userInvitedYouToSecureChat(String name) {
    return '$name sizi güvenli bir sohbete davet etti';
  }

  @override
  String get youHaveBeenInvitedToSecureChat => 'Güvenli bir sohbete davet edildiniz';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get languageUpdateFailed => 'Dil tercihi kaydedilemedi. Lütfen tekrar deneyin.';

  @override
  String get timeJustNow => 'şimdi';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dakika önce',
      one: '1 dakika önce',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat önce',
      one: '1 saat önce',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün önce',
      one: 'dün',
    );
    return '$_temp0';
  }

  @override
  String get profile => 'Profil';

  @override
  String get follow => 'Takip et';

  @override
  String get unfollow => 'Takibi bırak';

  @override
  String get failedToStartChat => 'Sohbet başlatılamadı. Lütfen tekrar deneyin.';

  @override
  String get inviteToWhiteNoise => 'White Noise\'a Davet Et';

  @override
  String inviteToWhiteNoiseDescription(String name) {
    return '$name henüz White Noise\'da değil. Güvenli bir sohbet başlatmak için uygulamayı paylaşın.';
  }

  @override
  String get failedToUpdateFollow => 'Takip durumu güncellenemedi. Lütfen tekrar deneyin.';

  @override
  String get imagePickerError => 'Görsel seçilemedi. Lütfen tekrar deneyin.';

  @override
  String get scanNsec => 'QR kodu tara';

  @override
  String get scanNsecHint => 'Giriş yapmak için özel anahtar QR kodunuzu tarayın.';

  @override
  String get cameraPermissionDenied => 'Kamera izni reddedildi';

  @override
  String get somethingWentWrong => 'Bir şeyler yanlış gitti';

  @override
  String get scanNpub => 'QR kodu tara';

  @override
  String get scanNpubHint => 'Bir kişinin QR kodunu tarayın.';

  @override
  String get invalidNpub => 'Geçersiz açık anahtar. Lütfen tekrar deneyin.';

  @override
  String get you => 'Sen';

  @override
  String get timestampNow => 'Şimdi';

  @override
  String timestampMinutes(int count) {
    return '${count}dk';
  }

  @override
  String timestampHours(int count) {
    return '${count}sa';
  }

  @override
  String get timestampYesterday => 'Dün';

  @override
  String get weekdayMonday => 'Pazartesi';

  @override
  String get weekdayTuesday => 'Salı';

  @override
  String get weekdayWednesday => 'Çarşamba';

  @override
  String get weekdayThursday => 'Perşembe';

  @override
  String get weekdayFriday => 'Cuma';

  @override
  String get weekdaySaturday => 'Cumartesi';

  @override
  String get weekdaySunday => 'Pazar';

  @override
  String get monthJanShort => 'Oca';

  @override
  String get monthFebShort => 'Şub';

  @override
  String get monthMarShort => 'Mar';

  @override
  String get monthAprShort => 'Nis';

  @override
  String get monthMayShort => 'May';

  @override
  String get monthJunShort => 'Haz';

  @override
  String get monthJulShort => 'Tem';

  @override
  String get monthAugShort => 'Ağu';

  @override
  String get monthSepShort => 'Eyl';

  @override
  String get monthOctShort => 'Eki';

  @override
  String get monthNovShort => 'Kas';

  @override
  String get monthDecShort => 'Ara';

  @override
  String get loginWithAmber => 'Amber ile giriş yap';

  @override
  String get signerConnectionError => 'Signer\'a bağlanılamadı. Lütfen tekrar deneyin.';

  @override
  String get search => 'Ara';

  @override
  String get filterChats => 'Sohbetler';

  @override
  String get filterArchive => 'Arşiv';

  @override
  String get signerErrorUserRejected => 'Giriş iptal edildi';

  @override
  String get signerErrorNotConnected => 'Signer\'a bağlı değil. Lütfen tekrar deneyin.';

  @override
  String get signerErrorNoSigner =>
      'Signer uygulaması bulunamadı. NIP-55 uyumlu bir signer yükleyin.';

  @override
  String get signerErrorNoResponse => 'Signer\'dan yanıt alınamadı. Lütfen tekrar deneyin.';

  @override
  String get signerErrorNoPubkey => 'Signer\'dan ortak anahtar alınamadı.';

  @override
  String get signerErrorNoResult => 'Signer sonuç döndürmedi.';

  @override
  String get signerErrorNoEvent => 'Signer imzalı etkinlik döndürmedi.';

  @override
  String get signerErrorRequestInProgress => 'Başka bir istek işleniyor. Lütfen bekleyin.';

  @override
  String get signerErrorNoActivity => 'Signer başlatılamadı. Lütfen tekrar deneyin.';

  @override
  String get signerErrorLaunchError => 'Signer uygulaması başlatılamadı.';

  @override
  String get signerErrorUnknown => 'Signer ile bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get messageNotFound => 'Mesaj bulunamadı';

  @override
  String get pin => 'Sabitle';

  @override
  String get unpin => 'Sabitlemeden Kaldır';

  @override
  String get mute => 'Sessiz';

  @override
  String get archive => 'Arşivle';

  @override
  String get failedToPinChat => 'Sabitleme başarısız. Lütfen tekrar deneyin.';

  @override
  String get carouselPrivacyTitle => 'Gizlilik ve güvenlik';

  @override
  String get carouselPrivacyDescription =>
      'Konuşmalarınızı gizli tutun. Bir ihlal durumunda bile mesajlarınız güvende kalır.';

  @override
  String get carouselIdentityTitle => 'Kimliğinizi seçin';

  @override
  String get carouselIdentityDescription =>
      'Telefon numaranızı veya e-postanızı açıklamadan sohbet edin. Kimliğinizi seçin: gerçek ad, takma ad veya anonim.';

  @override
  String get carouselDecentralizedTitle => 'Merkezi olmayan ve izinsiz';

  @override
  String get carouselDecentralizedDescription =>
      'Hiçbir merkezi otorite iletişiminizi kontrol etmez – izin gerekmez, sansür mümkün değildir.';

  @override
  String get learnMore => 'Daha fazla bilgi';

  @override
  String get backToSignUp => 'Kayıta geri dön';

  @override
  String get deleteAllData => 'Tüm Verileri Sil';

  @override
  String get deleteAllDataConfirmation => 'Tüm veriler silinsin mi?';

  @override
  String get deleteAllDataWarning =>
      'Bu işlem, bu cihazdaki tüm sohbetlerinizi, mesajlarınızı ve ayarlarınızı kalıcı olarak silecektir. Bu işlem geri alınamaz.';

  @override
  String get deleteAllDataError => 'Tüm veriler silinemedi. Lütfen tekrar deneyin.';

  @override
  String get chatInformation => 'Sohbet Bilgileri';

  @override
  String get addAsContact => 'Kişi olarak ekle';

  @override
  String get removeAsContact => 'Kişilerden çıkar';

  @override
  String get addToGroup => 'Gruba ekle';

  @override
  String get addToAnotherGroup => 'Başka bir gruba ekle';

  @override
  String get relayResolutionTitle => 'Röle Ayarları';

  @override
  String get relayResolutionDescription =>
      'Röle listelerinizi ağda bulamadık. Listelerinizin yayınlandığı bir röle sağlayabilir veya başlamak için varsayılan rölelerimizi kullanabilirsiniz.';

  @override
  String get relayResolutionUseDefaults => 'Varsayılan röleleri kullan';

  @override
  String get relayResolutionTryRelay => 'Röle ara';

  @override
  String get relayResolutionRelayPlaceholder => 'wss://relay.example.com';

  @override
  String get relayResolutionRelayLabel => 'Röle URL\'si';

  @override
  String get relayResolutionNotFound =>
      'Bu rölede röle listesi bulunamadı. Başka bir tane deneyin veya varsayılanları kullanın.';

  @override
  String get loginErrorInvalidKey =>
      'Geçersiz özel anahtar biçimi. Lütfen kontrol edip tekrar deneyin.';

  @override
  String get loginErrorNoRelayConnections =>
      'Hiçbir röleye bağlanılamadı. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get loginErrorTimeout => 'Giriş zaman aşımına uğradı. Lütfen tekrar deneyin.';

  @override
  String get loginErrorGeneric => 'Giriş sırasında bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get loginErrorNoLoginInProgress => 'Devam eden giriş yok. Lütfen yeniden başlayın.';

  @override
  String get loginErrorInternal => 'Dahili bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get loginPasteNothingToPaste => 'Yapıştırılacak bir şey yok';

  @override
  String get loginPasteFailed => 'Panodan yapıştırma başarısız';

  @override
  String get openSettings => 'Ayarları aç';

  @override
  String get scannerError => 'Tarayıcı hatası';

  @override
  String get scannerErrorDescription => 'Tarayıcıda bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get cameraPermissionDeniedDescription =>
      'QR kodlarını taramak için cihaz ayarlarınızda kamera erişimini etkinleştirin.';

  @override
  String get retry => 'Yeniden dene';

  @override
  String get groupInformation => 'Grup Bilgileri';

  @override
  String get editGroup => 'Grubu düzenle';

  @override
  String get editGroupAction => 'Grubu düzenle';

  @override
  String get groupNameLabel => 'Ad';

  @override
  String get groupDescriptionLabel => 'Hakkında';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Üye',
      one: '1 Üye',
    );
    return '$_temp0';
  }

  @override
  String get adminBadge => 'Yönetici';

  @override
  String get membersLabel => 'Üyeler:';

  @override
  String get memberBadge => 'Üye';

  @override
  String get sendMessage => 'Mesaj gönder';

  @override
  String get makeAdmin => 'Yönetici yap';

  @override
  String get removeAdminRole => 'Yöneticilikten çıkar';

  @override
  String get removeFromGroup => 'Gruptan çıkar';

  @override
  String get removeFromGroupConfirmation => 'Gruptan çıkarılsın mı?';

  @override
  String get removeFromGroupWarning =>
      'Bu üye gruptan çıkarılacak ve artık yeni mesajları göremeyecek.';

  @override
  String get makeAdminConfirmation => 'Yönetici yapılsın mı?';

  @override
  String get makeAdminWarning =>
      'Bu üye grubu yönetebilecek, üye ekleyip çıkarabilecek ve grup ayarlarını değiştirebilecek.';

  @override
  String get removeAdminConfirmation => 'Yöneticilik kaldırılsın mı?';

  @override
  String get removeAdminWarning =>
      'Bu üye artık grubu yönetemeyecek, üye ekleyip çıkaramayacak veya grup ayarlarını değiştiremeyecek.';

  @override
  String get failedToRemoveFromGroup => 'Üye çıkarılamadı. Lütfen tekrar deneyin.';

  @override
  String get failedToMakeAdmin => 'Yönetici yapılamadı. Lütfen tekrar deneyin.';

  @override
  String get failedToRemoveAdmin => 'Yöneticilik kaldırılamadı. Lütfen tekrar deneyin.';

  @override
  String get groupUpdatedSuccessfully => 'Grup başarıyla güncellendi';

  @override
  String get groupLoadError => 'Grup yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String get groupSaveError => 'Grup kaydedilemedi. Lütfen tekrar deneyin.';

  @override
  String get failedToFetchGroupMembers => 'Grup üyeleri yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String get failedToAddMembers => 'Üye eklenemedi. Lütfen tekrar deneyin.';

  @override
  String get userNeedsUpdate => 'Anahtar güncellemesi gerekli';

  @override
  String userNeedsUpdateDescription(String name) {
    return '$name ile henüz güvenli sohbet başlatamazsınız. Güvenli mesajlaşmanın çalışması için White Noise\'u güncellemesi gerekiyor.';
  }

  @override
  String addToGroupConfirmation(String userName, String groupName) {
    return '$userName kişisini $groupName grubuna eklensin mi?';
  }

  @override
  String get unknownInviteToWhiteNoiseDescription =>
      'Bu kullanıcı henüz White Noise\'da değil. Güvenli bir sohbet başlatmak için uygulamayı paylaşın.';

  @override
  String get unknownUserNeedsUpdateDescription =>
      'Bu kullanıcıyla henüz güvenli sohbet başlatamazsınız. Güvenli mesajlaşmanın çalışması için White Noise\'u güncellemesi gerekiyor.';

  @override
  String get add => 'Ekle';

  @override
  String get noGroupsAvailable => 'Kullanılabilir grup yok';

  @override
  String get noAdminGroupsAvailable =>
      'Henüz hiçbir grupta yönetici değilsiniz. Kişi eklemek için bir grup oluşturun.';
}
