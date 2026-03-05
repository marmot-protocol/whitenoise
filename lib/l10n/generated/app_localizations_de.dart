// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String photoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fotos',
      one: 'Foto',
    );
    return '$_temp0';
  }

  @override
  String get appTitle => 'White Noise';

  @override
  String get sloganDecentralized => 'Dezentralisiert';

  @override
  String get sloganUncensorable => 'Unzensierbar';

  @override
  String get sloganSecureMessaging => 'Sichere Nachrichten';

  @override
  String get login => 'Anmelden';

  @override
  String get signUp => 'Registrieren';

  @override
  String get loginTitle => 'Anmelden';

  @override
  String get enterPrivateKey => 'Privaten Schlüssel eingeben';

  @override
  String get nsecPlaceholder => 'nsec...';

  @override
  String get setupProfile => 'Profil einrichten';

  @override
  String get chooseName => 'Namen wählen';

  @override
  String get enterYourName => 'Namen eingeben';

  @override
  String get introduceYourself => 'Stell dich vor';

  @override
  String get writeSomethingAboutYourself => 'Schreib etwas über dich';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get profileReady => 'Dein Profil ist bereit!';

  @override
  String get startConversationHint =>
      'Starte ein Gespräch, indem du Freunde hinzufügst oder dein Profil teilst.';

  @override
  String get share => 'Teilen';

  @override
  String get shareYourProfile => 'Profil teilen';

  @override
  String get startChat => 'Chat starten';

  @override
  String get settings => 'Einstellungen';

  @override
  String get shareAndConnect => 'Teilen & verbinden';

  @override
  String get switchProfile => 'Profil wechseln';

  @override
  String get addNewProfile => 'Neues Profil hinzufügen';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get profileKeys => 'Profilschlüssel';

  @override
  String get networkRelays => 'Netzwerk-Relays';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get privacySecurity => 'Datenschutz & Sicherheit';

  @override
  String get donateToWhiteNoise => 'An White Noise spenden';

  @override
  String get developerSettings => 'Entwicklereinstellungen';

  @override
  String get signOut => 'Abmelden';

  @override
  String get appearanceTitle => 'Erscheinungsbild';

  @override
  String get privacySecurityTitle => 'Datenschutz & Sicherheit';

  @override
  String get deleteAllAppData => 'Alle App-Daten löschen';

  @override
  String get deleteAppData => 'App-Daten löschen';

  @override
  String get deleteAllAppDataDescription =>
      'Alle Profile, Schlüssel, Chats und lokalen Dateien von diesem Gerät löschen.';

  @override
  String get deleteAllAppDataConfirmation => 'Alle App-Daten löschen?';

  @override
  String get deleteAllAppDataWarning =>
      'Hiermit werden alle Profile, Schlüssel, Chats und lokalen Dateien von diesem Gerät gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get theme => 'Design';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get profileKeysTitle => 'Profilschlüssel';

  @override
  String get publicKey => 'Öffentlicher Schlüssel';

  @override
  String get publicKeyCopied => 'Öffentlicher Schlüssel in Zwischenablage kopiert';

  @override
  String get publicKeyDescription =>
      'Dein öffentlicher Schlüssel (npub) kann mit anderen geteilt werden. Er wird verwendet, um dich im Netzwerk zu identifizieren.';

  @override
  String get privateKey => 'Privater Schlüssel';

  @override
  String get privateKeyCopied => 'Privater Schlüssel in Zwischenablage kopiert';

  @override
  String get privateKeyDescription =>
      'Dein privater Schlüssel (nsec) sollte geheim gehalten werden. Jeder mit Zugriff darauf kann dein Konto kontrollieren.';

  @override
  String get keepPrivateKeySecure => 'Halte deinen privaten Schlüssel sicher';

  @override
  String get privateKeyWarning =>
      'Teile deinen privaten Schlüssel nicht öffentlich und verwende ihn nur zum Anmelden bei anderen Nostr-Apps.';

  @override
  String get nsecOnExternalSigner => 'Privater Schlüssel ist im externen Signer gespeichert';

  @override
  String get nsecOnExternalSignerDescription =>
      'Dein privater Schlüssel ist in White Noise nicht verfügbar. Öffne deinen Signer, um ihn anzusehen oder zu verwalten.';

  @override
  String get editProfileTitle => 'Profil bearbeiten';

  @override
  String get profileName => 'Profilname';

  @override
  String get nostrAddress => 'Nostr-Adresse';

  @override
  String get nostrAddressPlaceholder => 'beispiel@whitenoise.chat';

  @override
  String get aboutYou => 'Über dich';

  @override
  String get profileIsPublic => 'Profil ist öffentlich';

  @override
  String get profilePublicDescription =>
      'Deine Profilinformationen sind für alle im Netzwerk sichtbar.';

  @override
  String get discard => 'Verwerfen';

  @override
  String get discardChanges => 'Änderungen verwerfen';

  @override
  String get save => 'Speichern';

  @override
  String get profileUpdatedSuccessfully => 'Profil erfolgreich aktualisiert';

  @override
  String errorLoadingProfile(String error) {
    return 'Fehler beim Laden des Profils: $error';
  }

  @override
  String error(String error) {
    return 'Fehler: $error';
  }

  @override
  String get profileLoadError =>
      'Profil konnte nicht geladen werden. Bitte versuchen Sie es erneut.';

  @override
  String get failedToLoadPrivateKey =>
      'Privater Schlüssel konnte nicht geladen werden. Bitte versuchen Sie es erneut.';

  @override
  String get profileSaveError =>
      'Profil konnte nicht gespeichert werden. Bitte versuchen Sie es erneut.';

  @override
  String get networkRelaysTitle => 'Netzwerk-Relays';

  @override
  String get myRelays => 'Meine Relays';

  @override
  String get myRelaysHelp => 'Relays, die du für alle deine Nostr-Anwendungen definiert hast.';

  @override
  String get inboxRelays => 'Posteingang-Relays';

  @override
  String get inboxRelaysHelp =>
      'Relays zum Empfangen von Einladungen und zum Starten sicherer Gespräche mit neuen Benutzern.';

  @override
  String get keyPackageRelays => 'Schlüsselpaket-Relays';

  @override
  String get keyPackageRelaysHelp =>
      'Relays, die deinen sicheren Schlüssel speichern, damit andere dich zu verschlüsselten Gesprächen einladen können.';

  @override
  String get errorLoadingRelays => 'Fehler beim Laden der Relays';

  @override
  String get noRelaysConfigured => 'Keine Relays konfiguriert';

  @override
  String get donateTitle => 'An White Noise spenden';

  @override
  String get donateDescription =>
      'Als gemeinnützige Organisation existiert White Noise ausschließlich für deine Privatsphäre und Freiheit, nicht für Profit. Deine Unterstützung hält uns unabhängig und kompromisslos.';

  @override
  String get lightningAddress => 'Lightning-Adresse';

  @override
  String get bitcoinSilentPayment => 'Bitcoin Silent Payment';

  @override
  String get copiedToClipboardThankYou => 'In Zwischenablage kopiert. Danke!';

  @override
  String get shareProfileTitle => 'Profil teilen';

  @override
  String get scanToConnect => 'Zum Verbinden scannen';

  @override
  String get signOutTitle => 'Abmelden';

  @override
  String get signOutConfirmation => 'Möchtest du dich wirklich abmelden?';

  @override
  String get signOutWarning =>
      'Wenn du dich bei White Noise abmeldest, werden deine Chats von diesem Gerät gelöscht und können auf einem anderen Gerät nicht wiederhergestellt werden.';

  @override
  String get signOutWarningBackupKey =>
      'Wenn du deinen privaten Schlüssel nicht gesichert hast, kannst du dieses Profil bei keinem anderen Nostr-Dienst verwenden.';

  @override
  String get backUpPrivateKey => 'Privaten Schlüssel sichern';

  @override
  String get copyPrivateKeyHint =>
      'Kopiere deinen privaten Schlüssel, um dein Konto auf einem anderen Gerät wiederherzustellen.';

  @override
  String get publicKeyCopyError =>
      'Öffentlicher Schlüssel konnte nicht kopiert werden. Bitte erneut versuchen.';

  @override
  String get noChatsYet => 'Noch keine Chats';

  @override
  String get startConversation => 'Starte ein Gespräch';

  @override
  String get welcomeNoticeTitle => 'Dein Profil ist bereit';

  @override
  String welcomeNoticeDescription(String findPeople, String shareProfile, String startANewChat) {
    return 'Tippe auf $findPeople, um deine Freunde zu finden. $shareProfile, um dich mit Bekannten zu verbinden, oder $startANewChat über das Chat-Plus-Symbol.';
  }

  @override
  String get findPeople => 'Personen finden';

  @override
  String get startANewChat => 'starte einen neuen Chat';

  @override
  String get noMessagesYet => 'Noch keine Nachrichten';

  @override
  String get messagePlaceholder => 'Nachricht';

  @override
  String get failedToSendMessage =>
      'Nachricht konnte nicht gesendet werden. Bitte erneut versuchen.';

  @override
  String get invitedToSecureChat => 'Du wurdest zu einem sicheren Chat eingeladen';

  @override
  String get invitedYouToChatSuffix => ' hat dich zum Chat eingeladen';

  @override
  String get decline => 'Ablehnen';

  @override
  String get accept => 'Annehmen';

  @override
  String failedToAcceptInvitation(String error) {
    return 'Einladung konnte nicht angenommen werden: $error';
  }

  @override
  String failedToDeclineInvitation(String error) {
    return 'Einladung konnte nicht abgelehnt werden: $error';
  }

  @override
  String get startNewChat => 'Neuen Chat starten';

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String get noFollowsYet => 'Noch keine Follows';

  @override
  String get searchByNameOrNpub => 'Name oder npub1...';

  @override
  String get developerSettingsTitle => 'Entwicklereinstellungen';

  @override
  String get publishNewKeyPackage => 'Neues Schlüsselpaket veröffentlichen';

  @override
  String get refreshKeyPackages => 'Schlüsselpakete aktualisieren';

  @override
  String get deleteAllKeyPackages => 'Alle Schlüsselpakete löschen';

  @override
  String keyPackagesCount(int count) {
    return 'Schlüsselpakete ($count)';
  }

  @override
  String get noKeyPackagesFound => 'Keine Schlüsselpakete gefunden';

  @override
  String get keyPackagePublished => 'Schlüsselpaket veröffentlicht';

  @override
  String get keyPackagesRefreshed => 'Schlüsselpakete aktualisiert';

  @override
  String get keyPackagesDeleted => 'Alle Schlüsselpakete gelöscht';

  @override
  String get keyPackageDeleted => 'Schlüsselpaket gelöscht';

  @override
  String packageNumber(int number) {
    return 'Paket $number';
  }

  @override
  String get goBack => 'Zurück';

  @override
  String get createGroup => 'Gruppe erstellen';

  @override
  String get newGroupChat => 'Neuer Gruppenchat';

  @override
  String get selectMembers => 'Mitglieder auswählen';

  @override
  String selectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get clearSelection => 'Löschen';

  @override
  String get continueButton => 'Weiter';

  @override
  String get setUpGroup => 'Gruppe einrichten';

  @override
  String get groupName => 'Gruppenname';

  @override
  String get groupNamePlaceholder => 'Gruppenname eingeben';

  @override
  String get groupDescription => 'Gruppenbeschreibung';

  @override
  String get description => 'Beschreibung';

  @override
  String get groupDescriptionPlaceholder => 'Wofür ist diese Gruppe?';

  @override
  String members(int count) {
    return '$count Mitglieder';
  }

  @override
  String invitingMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mitglieder einladen:',
      one: 'Mitglied einladen:',
    );
    return '$_temp0';
  }

  @override
  String get usersWithoutKeyPackages =>
      'Benutzer ohne Schlüsselpakete (können nicht hinzugefügt werden)';

  @override
  String usersNotOnWhiteNoise(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Diese Benutzer sind nicht auf White Noise',
      one: 'Dieser Benutzer ist nicht auf White Noise',
    );
    return '$_temp0';
  }

  @override
  String usersNotOnWhiteNoiseDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Diese Benutzer können nicht zur Gruppe hinzugefügt werden, da sie White Noise nicht installiert haben oder ihre Schlüsselpakete noch nicht veröffentlicht haben.',
      one:
          'Dieser Benutzer kann nicht zur Gruppe hinzugefügt werden, da White Noise nicht installiert ist oder das Schlüsselpaket noch nicht veröffentlicht wurde.',
    );
    return '$_temp0';
  }

  @override
  String get uploadingImage => 'Bild wird hochgeladen...';

  @override
  String get creatingGroup => 'Gruppe wird erstellt...';

  @override
  String get groupNameRequired => 'Gruppenname ist erforderlich';

  @override
  String get noUsersWithKeyPackages => 'Keine Benutzer mit Schlüsselpaketen zum Hinzufügen';

  @override
  String get createGroupFailed => 'Gruppe erstellen fehlgeschlagen';

  @override
  String get reportError => 'Fehler melden';

  @override
  String get wipMessage =>
      'Wir arbeiten an dieser Funktion. Um die Entwicklung zu unterstützen, spende bitte an White Noise';

  @override
  String get donate => 'Spenden';

  @override
  String get addRelay => 'Relay hinzufügen';

  @override
  String get enterRelayAddress => 'Relay-Adresse eingeben';

  @override
  String get relayAddressPlaceholder => 'wss://relay.example.com';

  @override
  String get removeRelay => 'Relay entfernen?';

  @override
  String get removeRelayConfirmation =>
      'Möchtest du dieses Relay wirklich entfernen? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get remove => 'Entfernen';

  @override
  String get messageActions => 'Nachrichtenaktionen';

  @override
  String get reply => 'Antworten';

  @override
  String get copyMessage => 'Kopieren';

  @override
  String get delete => 'Löschen';

  @override
  String get failedToDeleteMessage =>
      'Nachricht konnte nicht gelöscht werden. Bitte erneut versuchen.';

  @override
  String get failedToSendReaction =>
      'Reaktion konnte nicht gesendet werden. Bitte erneut versuchen.';

  @override
  String get failedToRemoveReaction =>
      'Reaktion konnte nicht entfernt werden. Bitte erneut versuchen.';

  @override
  String get unknownUser => 'Unbekannter Benutzer';

  @override
  String get unknownGroup => 'Unbekannte Gruppe';

  @override
  String get hasInvitedYouToSecureChat => 'Hat dich zu einem sicheren Chat eingeladen';

  @override
  String userInvitedYouToSecureChat(String name) {
    return '$name hat dich zu einem sicheren Chat eingeladen';
  }

  @override
  String get youHaveBeenInvitedToSecureChat => 'Du wurdest zu einem sicheren Chat eingeladen';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get languageUpdateFailed =>
      'Spracheinstellung konnte nicht gespeichert werden. Bitte erneut versuchen.';

  @override
  String get timeJustNow => 'gerade eben';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Minuten',
      one: 'vor 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'gestern',
    );
    return '$_temp0';
  }

  @override
  String get profile => 'Profil';

  @override
  String get follow => 'Folgen';

  @override
  String get unfollow => 'Entfolgen';

  @override
  String chatSearchMatchCount(int current, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total Treffer',
      one: '1 Treffer',
    );
    return '$current von $_temp0';
  }

  @override
  String get failedToStartChat =>
      'Chat konnte nicht gestartet werden. Bitte versuchen Sie es erneut.';

  @override
  String get inviteToWhiteNoise => 'Zu White Noise einladen';

  @override
  String inviteToWhiteNoiseDescription(String name) {
    return '$name ist noch nicht bei White Noise. Teilen Sie die App, um einen sicheren Chat zu starten.';
  }

  @override
  String get inviteMessage =>
      'Treten Sie mir bei White Noise bei. Keine Telefonnummer. Keine Überwachung. Nur echte Privatsphäre. Hier herunterladen: https://www.whitenoise.chat/download';

  @override
  String get failedToUpdateFollow =>
      'Folgestatus konnte nicht aktualisiert werden. Bitte versuchen Sie es erneut.';

  @override
  String get imagePickerError =>
      'Bild konnte nicht ausgewählt werden. Bitte versuchen Sie es erneut.';

  @override
  String get scanNsec => 'QR-Code scannen';

  @override
  String get scanNsecHint => 'Scannen Sie den QR-Code Ihres privaten Schlüssels zum Anmelden.';

  @override
  String get cameraPermissionDenied => 'Kamerazugriff verweigert';

  @override
  String get somethingWentWrong => 'Etwas ist schiefgelaufen';

  @override
  String get scanNpub => 'QR-Code scannen';

  @override
  String get scanNpubHint => 'Scannen Sie den QR-Code eines Kontakts.';

  @override
  String get invalidNpub => 'Ungültiger öffentlicher Schlüssel. Bitte versuchen Sie es erneut.';

  @override
  String get you => 'Du';

  @override
  String get timestampNow => 'Jetzt';

  @override
  String timestampMinutes(int count) {
    return '${count}m';
  }

  @override
  String timestampHours(int count) {
    return '${count}h';
  }

  @override
  String get timestampYesterday => 'Gestern';

  @override
  String get weekdayMonday => 'Montag';

  @override
  String get weekdayTuesday => 'Dienstag';

  @override
  String get weekdayWednesday => 'Mittwoch';

  @override
  String get weekdayThursday => 'Donnerstag';

  @override
  String get weekdayFriday => 'Freitag';

  @override
  String get weekdaySaturday => 'Samstag';

  @override
  String get weekdaySunday => 'Sonntag';

  @override
  String get monthJanShort => 'Jan';

  @override
  String get monthFebShort => 'Feb';

  @override
  String get monthMarShort => 'Mär';

  @override
  String get monthAprShort => 'Apr';

  @override
  String get monthMayShort => 'Mai';

  @override
  String get monthJunShort => 'Jun';

  @override
  String get monthJulShort => 'Jul';

  @override
  String get monthAugShort => 'Aug';

  @override
  String get monthSepShort => 'Sep';

  @override
  String get monthOctShort => 'Okt';

  @override
  String get monthNovShort => 'Nov';

  @override
  String get monthDecShort => 'Dez';

  @override
  String get loginWithAmber => 'Mit Amber anmelden';

  @override
  String get signerConnectionError =>
      'Verbindung zum Signer fehlgeschlagen. Bitte versuch es erneut.';

  @override
  String get search => 'Suche';

  @override
  String get filterChats => 'Chats';

  @override
  String get filterArchive => 'Archiv';

  @override
  String get signerErrorUserRejected => 'Anmeldung abgebrochen';

  @override
  String get signerErrorNotConnected => 'Nicht mit dem Signer verbunden. Bitte versuch es erneut.';

  @override
  String get signerErrorNoSigner =>
      'Keine Signer-App gefunden. Bitte installiere einen NIP-55-kompatiblen Signer.';

  @override
  String get signerErrorNoResponse => 'Keine Antwort vom Signer. Bitte versuch es erneut.';

  @override
  String get signerErrorNoPubkey =>
      'Öffentlicher Schlüssel konnte nicht vom Signer abgerufen werden.';

  @override
  String get signerErrorNoResult => 'Der Signer hat kein Ergebnis zurückgegeben.';

  @override
  String get signerErrorNoEvent => 'Der Signer hat kein signiertes Event zurückgegeben.';

  @override
  String get signerErrorRequestInProgress =>
      'Eine andere Anfrage wird gerade bearbeitet. Warte bitte.';

  @override
  String get signerErrorNoActivity =>
      'Signer konnte nicht gestartet werden. Bitte versuch es erneut.';

  @override
  String get signerErrorLaunchError => 'Signer-App konnte nicht gestartet werden.';

  @override
  String get signerErrorUnknown =>
      'Ein Fehler ist beim Signer aufgetreten. Bitte versuch es erneut.';

  @override
  String get messageNotFound => 'Nachricht nicht gefunden';

  @override
  String get pin => 'Anheften';

  @override
  String get unpin => 'Loslösen';

  @override
  String get mute => 'Stummschalten';

  @override
  String get archive => 'Archivieren';

  @override
  String get failedToPinChat => 'Anheften fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get carouselPrivacyTitle => 'Privatsphäre und Sicherheit';

  @override
  String get carouselPrivacyDescription =>
      'Halte deine Gespräche privat. Selbst bei einem Datenleck bleiben deine Nachrichten sicher.';

  @override
  String get carouselIdentityTitle => 'Wähle deine Identität';

  @override
  String get carouselIdentityDescription =>
      'Chatte ohne deine Telefonnummer oder E-Mail preiszugeben. Wähle deine Identität: echter Name, Pseudonym oder anonym.';

  @override
  String get carouselDecentralizedTitle => 'Dezentralisiert und genehmigungsfrei';

  @override
  String get carouselDecentralizedDescription =>
      'Keine zentrale Instanz kontrolliert deine Kommunikation – keine Genehmigungen nötig, keine Zensur möglich.';

  @override
  String get learnMore => 'Mehr erfahren';

  @override
  String get backToSignUp => 'Zurück zur Registrierung';

  @override
  String get deleteAllData => 'Alle Daten löschen';

  @override
  String get deleteAllDataConfirmation => 'Alle Daten löschen?';

  @override
  String get deleteAllDataWarning =>
      'Dies wird alle deine Chats, Nachrichten und Einstellungen von diesem Gerät dauerhaft löschen. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get deleteAllDataError => 'Fehler beim Löschen aller Daten. Bitte versuche es erneut.';

  @override
  String get chatInformation => 'Chat-Informationen';

  @override
  String get addAsContact => 'Als Kontakt hinzufügen';

  @override
  String get removeAsContact => 'Als Kontakt entfernen';

  @override
  String get addToGroup => 'Zur Gruppe hinzufügen';

  @override
  String get addToAnotherGroup => 'Zu einer anderen Gruppe hinzufügen';

  @override
  String get relayResolutionTitle => 'Relay-Einrichtung';

  @override
  String get relayResolutionDescription =>
      'Wir konnten Ihre Relay-Listen nicht im Netzwerk finden. Sie können ein Relay angeben, auf dem Ihre Listen veröffentlicht sind, oder unsere Standard-Relays verwenden, um loszulegen.';

  @override
  String get relayResolutionUseDefaults => 'Standard-Relays verwenden';

  @override
  String get relayResolutionTryRelay => 'Relay durchsuchen';

  @override
  String get relayResolutionRelayPlaceholder => 'wss://relay.example.com';

  @override
  String get relayResolutionRelayLabel => 'Relay-URL';

  @override
  String get relayResolutionNotFound =>
      'Keine Relay-Listen auf diesem Relay gefunden. Versuchen Sie ein anderes oder verwenden Sie die Standardeinstellungen.';

  @override
  String get loginErrorInvalidKey =>
      'Ungültiges Format des privaten Schlüssels. Bitte überprüfen und erneut versuchen.';

  @override
  String get loginErrorNoRelayConnections =>
      'Verbindung zu Relays nicht möglich. Bitte überprüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get loginErrorTimeout => 'Zeitüberschreitung bei der Anmeldung. Bitte erneut versuchen.';

  @override
  String get loginErrorGeneric =>
      'Bei der Anmeldung ist ein Fehler aufgetreten. Bitte erneut versuchen.';

  @override
  String get loginErrorNoLoginInProgress => 'Kein Anmeldevorgang aktiv. Bitte starten Sie erneut.';

  @override
  String get loginErrorInternal => 'Ein interner Fehler ist aufgetreten. Bitte erneut versuchen.';

  @override
  String get loginPasteNothingToPaste => 'Nichts zum Einfügen';

  @override
  String get loginPasteFailed => 'Einfügen aus der Zwischenablage fehlgeschlagen';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get scannerError => 'Scanner-Fehler';

  @override
  String get scannerErrorDescription =>
      'Ein Fehler ist beim Scanner aufgetreten. Bitte versuchen Sie es erneut.';

  @override
  String get cameraPermissionDeniedDescription =>
      'Bitte aktivieren Sie den Kamerazugriff in Ihren Geräteeinstellungen, um QR-Codes zu scannen.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get groupInformation => 'Gruppeninformationen';

  @override
  String get editGroup => 'Gruppe bearbeiten';

  @override
  String get editGroupAction => 'Gruppe bearbeiten';

  @override
  String get groupNameLabel => 'Name';

  @override
  String get groupDescriptionLabel => 'Über';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
    );
    return '$_temp0';
  }

  @override
  String get adminBadge => 'Admin';

  @override
  String get membersLabel => 'Mitglieder:';

  @override
  String get memberBadge => 'Mitglied';

  @override
  String get sendMessage => 'Nachricht senden';

  @override
  String get makeAdmin => 'Zum Admin machen';

  @override
  String get removeAdminRole => 'Admin entfernen';

  @override
  String get removeFromGroup => 'Aus Gruppe entfernen';

  @override
  String get removeFromGroupConfirmation => 'Aus Gruppe entfernen?';

  @override
  String get removeFromGroupWarning =>
      'Dieses Mitglied wird aus der Gruppe entfernt und kann keine neuen Nachrichten mehr sehen.';

  @override
  String get makeAdminConfirmation => 'Zum Admin machen?';

  @override
  String get makeAdminWarning =>
      'Dieses Mitglied kann die Gruppe verwalten, Mitglieder hinzufügen oder entfernen und Gruppeneinstellungen ändern.';

  @override
  String get removeAdminConfirmation => 'Admin entfernen?';

  @override
  String get removeAdminWarning =>
      'Dieses Mitglied kann die Gruppe nicht mehr verwalten, keine Mitglieder hinzufügen oder entfernen und keine Gruppeneinstellungen ändern.';

  @override
  String get failedToRemoveFromGroup =>
      'Mitglied konnte nicht entfernt werden. Bitte erneut versuchen.';

  @override
  String get failedToMakeAdmin => 'Admin konnte nicht ernannt werden. Bitte erneut versuchen.';

  @override
  String get failedToRemoveAdmin => 'Admin konnte nicht entfernt werden. Bitte erneut versuchen.';

  @override
  String get groupUpdatedSuccessfully => 'Gruppe erfolgreich aktualisiert';

  @override
  String get groupLoadError => 'Gruppe konnte nicht geladen werden. Bitte erneut versuchen.';

  @override
  String get groupSaveError => 'Gruppe konnte nicht gespeichert werden. Bitte erneut versuchen.';

  @override
  String get failedToFetchGroupMembers =>
      'Gruppenmitglieder konnten nicht geladen werden. Bitte erneut versuchen.';

  @override
  String get failedToAddMembers =>
      'Mitglieder konnten nicht hinzugefügt werden. Bitte erneut versuchen.';

  @override
  String get groupImageUploadFailed =>
      'Gruppe erstellt, aber das Hochladen des Bildes ist fehlgeschlagen.';

  @override
  String updateNeeded(String name) {
    return '$name muss aktualisieren';
  }

  @override
  String updateNeededDescription(String name) {
    return 'Du kannst noch keinen sicheren Chat mit $name starten. Die Person muss White Noise aktualisieren, bevor sichere Nachrichten funktionieren.';
  }

  @override
  String addToGroupConfirmation(String userName, String groupName) {
    return '$userName zu $groupName hinzufügen?';
  }

  @override
  String get unknownInviteToWhiteNoiseDescription =>
      'Dieser Benutzer ist noch nicht bei White Noise. Teile die App, um einen sicheren Chat zu starten.';

  @override
  String get unknownUserNeedsUpdate => 'Benutzer muss aktualisieren';

  @override
  String get unknownUserNeedsUpdateDescription =>
      'Du kannst noch keinen sicheren Chat mit diesem Benutzer starten. Die Person muss White Noise aktualisieren, bevor sichere Nachrichten funktionieren.';

  @override
  String get add => 'Hinzufügen';

  @override
  String get noGroupsAvailable => 'Keine Gruppen verfügbar';

  @override
  String get noAdminGroupsAvailable =>
      'Du bist noch in keiner Gruppe Admin. Erstelle eine Gruppe, um Personen hinzuzufügen.';

  @override
  String get profilesTitle => 'Profile';

  @override
  String get noAccountsAvailable => 'Keine Konten verfügbar';

  @override
  String get connectAnotherProfile => 'Weiteres Profil verbinden';

  @override
  String get rawDebugView => 'Rohe Debug-Ansicht';

  @override
  String get rawDebugViewDescription => 'Rohe Nachrichtendaten im Chat anzeigen';

  @override
  String get rawDebugViewTitle => 'Rohe Debug-Ansicht';

  @override
  String get rawDebugViewGroupId => 'Gruppen-ID';

  @override
  String rawDebugViewMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nachrichten',
      one: '1 Nachricht',
    );
    return '$_temp0';
  }

  @override
  String get rawDebugViewCopied => 'In die Zwischenablage kopiert';

  @override
  String get appLogsTitle => 'App-Logs';

  @override
  String get appLogsViewLogs => 'Logs anzeigen';

  @override
  String get appLogsViewLogsDescription => 'Alle Logger-Ausgaben in der App anzeigen';

  @override
  String get appLogsClear => 'Löschen';

  @override
  String get appLogsEmpty => 'Noch keine Logs';

  @override
  String get appLogsSearchPlaceholder => 'Logs durchsuchen...';

  @override
  String get appLogsAddPatternPlaceholder => 'Filter hinzufügen';

  @override
  String get appLogsIgnore => 'Ignorieren';

  @override
  String get appLogsShow => 'Anzeigen';

  @override
  String get appLogsClearFilters => 'Filter löschen';

  @override
  String appLogsFilteredCount(int shown, int total) {
    return '$shown von $total';
  }

  @override
  String get invalidRelayUrlScheme => 'Die URL muss mit wss:// oder ws:// beginnen';

  @override
  String get invalidRelayUrl => 'Ungültige Relay-URL';
}
