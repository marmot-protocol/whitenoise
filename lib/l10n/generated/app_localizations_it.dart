// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String photoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Foto',
      one: 'Foto',
    );
    return '$_temp0';
  }

  @override
  String get appTitle => 'White Noise';

  @override
  String get sloganDecentralized => 'Decentralizzato';

  @override
  String get sloganUncensorable => 'Incensurabile';

  @override
  String get sloganSecureMessaging => 'Messaggistica Sicura';

  @override
  String get login => 'Accedi';

  @override
  String get signUp => 'Registrati';

  @override
  String get loginTitle => 'Inserisci la tua chiave privata';

  @override
  String get enterPrivateKey => 'Inserisci la tua chiave privata';

  @override
  String get nsecPlaceholder => 'nsec...';

  @override
  String get setupProfile => 'Configura profilo';

  @override
  String get chooseName => 'Scegli un nome';

  @override
  String get enterYourName => 'Inserisci il tuo nome';

  @override
  String get introduceYourself => 'Presentati';

  @override
  String get writeSomethingAboutYourself => 'Scrivi qualcosa su di te';

  @override
  String get cancel => 'Annulla';

  @override
  String get profileReady => 'Il tuo profilo è pronto!';

  @override
  String get startConversationHint =>
      'Inizia una conversazione aggiungendo amici o condividendo il tuo profilo.';

  @override
  String get share => 'Condividi';

  @override
  String get shareYourProfile => 'Condividi il tuo profilo';

  @override
  String get startChat => 'Inizia una chat';

  @override
  String get settings => 'Impostazioni';

  @override
  String get shareAndConnect => 'Condividi e connetti';

  @override
  String get switchProfile => 'Cambia profilo';

  @override
  String get addNewProfile => 'Aggiungi un nuovo profilo';

  @override
  String get editProfile => 'Modifica profilo';

  @override
  String get profileKeys => 'Chiavi del profilo';

  @override
  String get networkRelays => 'Relay di rete';

  @override
  String get appearance => 'Aspetto';

  @override
  String get privacySecurity => 'Privacy e sicurezza';

  @override
  String get donateToWhiteNoise => 'Dona a White Noise';

  @override
  String get developerSettings => 'Impostazioni sviluppatore';

  @override
  String get signOut => 'Esci';

  @override
  String get appearanceTitle => 'Aspetto';

  @override
  String get privacySecurityTitle => 'Privacy e sicurezza';

  @override
  String get deleteAllAppData => 'Elimina Tutti i Dati dell\'App';

  @override
  String get deleteAppData => 'Elimina dati dell\'app';

  @override
  String get deleteAllAppDataDescription =>
      'Cancella tutti i profili, le chiavi, le chat e i file locali da questo dispositivo.';

  @override
  String get deleteAllAppDataConfirmation => 'Eliminare tutti i dati dell\'app?';

  @override
  String get deleteAllAppDataWarning =>
      'Verranno cancellati tutti i profili, le chiavi, le chat e i file locali da questo dispositivo. Questa azione non può essere annullata.';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get profileKeysTitle => 'Chiavi del profilo';

  @override
  String get publicKey => 'Chiave pubblica';

  @override
  String get publicKeyCopied => 'Chiave pubblica copiata negli appunti';

  @override
  String get publicKeyDescription =>
      'La tua chiave pubblica (npub) può essere condivisa con altri. Viene usata per identificarti sulla rete.';

  @override
  String get privateKey => 'Chiave privata';

  @override
  String get privateKeyCopied => 'Chiave privata copiata negli appunti';

  @override
  String get privateKeyDescription =>
      'La tua chiave privata (nsec) deve rimanere segreta. Chiunque vi abbia accesso può controllare il tuo account.';

  @override
  String get keepPrivateKeySecure => 'Mantieni la tua chiave privata al sicuro';

  @override
  String get privateKeyWarning =>
      'Non condividere la tua chiave privata pubblicamente e usala solo per accedere ad altre app Nostr.';

  @override
  String get nsecOnExternalSigner => 'La chiave privata è archiviata in un signer esterno';

  @override
  String get nsecOnExternalSignerDescription =>
      'La tua chiave privata non è disponibile in White Noise. Apri il tuo signer per visualizzarla o gestirla.';

  @override
  String get editProfileTitle => 'Modifica profilo';

  @override
  String get profileName => 'Nome profilo';

  @override
  String get nostrAddress => 'Indirizzo Nostr';

  @override
  String get nostrAddressPlaceholder => 'esempio@whitenoise.chat';

  @override
  String get aboutYou => 'Su di te';

  @override
  String get profileIsPublic => 'Il profilo è pubblico';

  @override
  String get profilePublicDescription =>
      'Le informazioni del tuo profilo saranno visibili a tutti sulla rete.';

  @override
  String get discard => 'Annulla';

  @override
  String get discardChanges => 'Annulla modifiche';

  @override
  String get save => 'Salva';

  @override
  String get profileUpdatedSuccessfully => 'Profilo aggiornato con successo';

  @override
  String errorLoadingProfile(String error) {
    return 'Errore nel caricamento del profilo: $error';
  }

  @override
  String error(String error) {
    return 'Errore: $error';
  }

  @override
  String get profileLoadError => 'Impossibile caricare il profilo. Riprova.';

  @override
  String get failedToLoadPrivateKey => 'Impossibile caricare la chiave privata. Riprova.';

  @override
  String get profileSaveError => 'Impossibile salvare il profilo. Riprova.';

  @override
  String get networkRelaysTitle => 'Relay di Rete';

  @override
  String get myRelays => 'I Miei Relay';

  @override
  String get myRelaysHelp =>
      'Relay che hai definito per l\'uso in tutte le tue applicazioni Nostr.';

  @override
  String get inboxRelays => 'Relay Posta in Arrivo';

  @override
  String get inboxRelaysHelp =>
      'Relay usati per ricevere inviti e avviare conversazioni sicure con nuovi utenti.';

  @override
  String get keyPackageRelays => 'Relay Pacchetti Chiavi';

  @override
  String get keyPackageRelaysHelp =>
      'Relay che memorizzano la tua chiave sicura affinché altri possano invitarti a conversazioni crittografate.';

  @override
  String get errorLoadingRelays => 'Errore nel caricamento dei relay';

  @override
  String get noRelaysConfigured => 'Nessun relay configurato';

  @override
  String get donateTitle => 'Dona a White Noise';

  @override
  String get donateDescription =>
      'Come organizzazione senza scopo di lucro, White Noise esiste unicamente per la tua privacy e libertà, non per profitto. Il tuo supporto ci mantiene indipendenti e senza compromessi.';

  @override
  String get donateContributionLetter =>
      'Se hai bisogno di una lettera di attestazione per una donazione, contattaci a info@ipf.dev';

  @override
  String get lightningAddress => 'Indirizzo Lightning';

  @override
  String get bitcoinSilentPayment => 'Pagamento Silenzioso Bitcoin';

  @override
  String get copiedToClipboardThankYou => 'Copiato negli appunti. Grazie!';

  @override
  String get shareProfileTitle => 'Condividi profilo';

  @override
  String get scanToConnect => 'Scansiona per connetterti';

  @override
  String get signOutTitle => 'Esci';

  @override
  String get signOutConfirmation => 'Sei sicuro di voler uscire?';

  @override
  String get signOutWarning =>
      'Quando esci da White Noise, le tue chat verranno eliminate da questo dispositivo e non potranno essere ripristinate su un altro dispositivo.';

  @override
  String get signOutWarningBackupKey =>
      'Se non hai fatto il backup della tua chiave privata, non potrai usare questo profilo su nessun altro servizio Nostr.';

  @override
  String get backUpPrivateKey => 'Fai il backup della tua chiave privata';

  @override
  String get copyPrivateKeyHint =>
      'Copia la tua chiave privata per ripristinare il tuo account su un altro dispositivo.';

  @override
  String get publicKeyCopyError => 'Copia della chiave pubblica fallita. Riprova.';

  @override
  String get noChatsYet => 'Ancora nessuna chat';

  @override
  String get startConversation => 'Inizia una conversazione';

  @override
  String get welcomeNoticeTitle => 'Il tuo profilo è pronto';

  @override
  String welcomeNoticeDescription(String findPeople, String shareProfile, String startANewChat) {
    return 'Tocca $findPeople per trovare i tuoi amici. $shareProfile per connetterti con persone che conosci, o $startANewChat usando l\'icona chat.';
  }

  @override
  String get findPeople => 'Trova persone';

  @override
  String get startANewChat => 'inizia una nuova chat';

  @override
  String get noMessagesYet => 'Ancora nessun messaggio';

  @override
  String get messagePlaceholder => 'Messaggio';

  @override
  String get failedToSendMessage => 'Invio del messaggio fallito. Riprova.';

  @override
  String get invitedToSecureChat => 'Sei stato invitato a una chat sicura';

  @override
  String get invitedYouToChatSuffix => ' ti ha invitato alla chat';

  @override
  String get decline => 'Rifiuta';

  @override
  String get accept => 'Accetta';

  @override
  String get failedToAcceptInvitation => 'Impossibile accettare l\'invito. Riprova.';

  @override
  String get failedToDeclineInvitation => 'Impossibile rifiutare l\'invito. Riprova.';

  @override
  String get startNewChat => 'Nuova chat';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String get noFollowsYet => 'Ancora nessun seguito';

  @override
  String get searchByNameOrNpub => 'Nome o npub1...';

  @override
  String get developerSettingsTitle => 'Impostazioni Sviluppatore';

  @override
  String get keyPackageManagementTitle => 'Gestione pacchetti chiavi';

  @override
  String get keyPackageManagementDescription =>
      'Pubblica, aggiorna ed elimina i pacchetti chiavi dell\'account';

  @override
  String get relayStateTitle => 'Stato relay';

  @override
  String get relayStateDescription => 'Ispeziona i piani di controllo relay attivi';

  @override
  String get relayControlStateDumpLabel => 'debug_relay_control_state:';

  @override
  String get relayControlStateSnapshotDescription =>
      'Istantanea dei piani attivi di rilevamento relay, inbox e gruppi.';

  @override
  String get relayControlStateLoading => 'Caricamento...';

  @override
  String get relayControlStateRefreshButton => 'Aggiorna dump';

  @override
  String get relayControlStateCopyButton => 'Copia dump';

  @override
  String get publishNewKeyPackage => 'Pubblica Nuovo Pacchetto Chiavi';

  @override
  String get refreshKeyPackages => 'Aggiorna Pacchetti Chiavi';

  @override
  String get deleteAllKeyPackages => 'Elimina Tutti i Pacchetti Chiavi';

  @override
  String keyPackagesCount(int count) {
    return 'Pacchetti Chiavi ($count)';
  }

  @override
  String get noKeyPackagesFound => 'Nessun pacchetto chiavi trovato';

  @override
  String get keyPackagePublished => 'Pacchetto chiavi pubblicato';

  @override
  String get keyPackagesRefreshed => 'Pacchetti chiavi aggiornati';

  @override
  String get keyPackagesDeleted => 'Tutti i pacchetti chiavi eliminati';

  @override
  String get keyPackageDeleted => 'Pacchetto chiavi eliminato';

  @override
  String get keyPackageFetchFailed => 'Impossibile aggiornare i pacchetti chiavi. Riprova.';

  @override
  String get keyPackagePublishFailed => 'Impossibile pubblicare il pacchetto chiavi. Riprova.';

  @override
  String get keyPackageDeleteFailed => 'Impossibile eliminare il pacchetto chiavi. Riprova.';

  @override
  String get keyPackageDeleteAllFailed =>
      'Impossibile eliminare tutti i pacchetti chiavi. Riprova.';

  @override
  String packageNumber(int number) {
    return 'Pacchetto $number';
  }

  @override
  String get goBack => 'Torna indietro';

  @override
  String get createGroup => 'Crea gruppo';

  @override
  String get newGroupChat => 'Nuova chat di gruppo';

  @override
  String get selectMembers => 'Seleziona Membri';

  @override
  String selectedCount(int count) {
    return '$count selezionati';
  }

  @override
  String get clearSelection => 'Cancella';

  @override
  String get continueButton => 'Continua';

  @override
  String get setUpGroup => 'Configura gruppo';

  @override
  String get groupName => 'Nome del Gruppo';

  @override
  String get groupNamePlaceholder => 'Inserisci il nome del gruppo';

  @override
  String get groupDescription => 'Descrizione del Gruppo';

  @override
  String get description => 'Descrizione';

  @override
  String get groupDescriptionPlaceholder => 'A cosa serve questo gruppo?';

  @override
  String members(int count) {
    return '$count membri';
  }

  @override
  String invitingMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Invito di membri:',
      one: 'Invito di membro:',
    );
    return '$_temp0';
  }

  @override
  String get usersWithoutKeyPackages =>
      'Utenti senza pacchetti di chiavi (non possono essere aggiunti)';

  @override
  String usersNotOnWhiteNoise(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Questi utenti non sono su White Noise',
      one: 'Questo utente non è su White Noise',
    );
    return '$_temp0';
  }

  @override
  String usersNotOnWhiteNoiseDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Questi utenti non possono essere aggiunti al gruppo perché non hanno White Noise installato o non hanno ancora pubblicato i loro pacchetti di chiavi.',
      one:
          'Questo utente non può essere aggiunto al gruppo perché non ha White Noise installato o non ha ancora pubblicato il suo pacchetto di chiavi.',
    );
    return '$_temp0';
  }

  @override
  String get uploadingImage => 'Caricamento immagine...';

  @override
  String get creatingGroup => 'Creazione gruppo...';

  @override
  String get groupNameRequired => 'Il nome del gruppo è obbligatorio';

  @override
  String get noUsersWithKeyPackages => 'Nessun utente con pacchetti di chiavi da aggiungere';

  @override
  String get createGroupFailed => 'Creazione gruppo non riuscita';

  @override
  String get reportError => 'Segnala errore';

  @override
  String get wipMessage =>
      'Stiamo lavorando su questa funzionalità. Per supportare lo sviluppo, dona a White Noise';

  @override
  String get donate => 'Dona';

  @override
  String get chatWithSupport => 'Chatta con il supporto';

  @override
  String get supportChatWelcomeMessage =>
      'Ciao! Raccontaci cosa hai in mente - domande, bug o feedback. Di solito rispondiamo in poche ore.';

  @override
  String get addRelay => 'Aggiungi Relay';

  @override
  String get enterRelayAddress => 'Inserisci l\'indirizzo del relay';

  @override
  String get relayAddressPlaceholder => 'wss://relay.example.com';

  @override
  String get removeRelay => 'Rimuovere il Relay?';

  @override
  String get removeRelayConfirmation =>
      'Sei sicuro di voler rimuovere questo relay? Questa azione non può essere annullata.';

  @override
  String get remove => 'Rimuovi';

  @override
  String get messageActions => 'Azioni messaggio';

  @override
  String get reply => 'Rispondi';

  @override
  String get copyMessage => 'Copia';

  @override
  String get delete => 'Elimina';

  @override
  String get failedToDeleteMessage => 'Eliminazione del messaggio fallita. Riprova.';

  @override
  String get failedToSendReaction => 'Invio della reazione fallito. Riprova.';

  @override
  String get failedToRemoveReaction => 'Rimozione della reazione fallita. Riprova.';

  @override
  String get unknownUser => 'Utente sconosciuto';

  @override
  String get noName => 'Nessun nome';

  @override
  String get unknownGroup => 'Gruppo sconosciuto';

  @override
  String get hasInvitedYouToSecureChat => 'Ti ha invitato a una chat sicura';

  @override
  String userInvitedYouToSecureChat(String name) {
    return '$name ti ha invitato a una chat sicura';
  }

  @override
  String get youHaveBeenInvitedToSecureChat => 'Sei stato invitato a una chat sicura';

  @override
  String get language => 'Lingua';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageUpdateFailed => 'Salvataggio della preferenza della lingua fallito. Riprova.';

  @override
  String get timeJustNow => 'proprio ora';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuti fa',
      one: '1 minuto fa',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore fa',
      one: '1 ora fa',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni fa',
      one: 'ieri',
    );
    return '$_temp0';
  }

  @override
  String get profile => 'Profilo';

  @override
  String get follow => 'Segui';

  @override
  String get unfollow => 'Smetti di seguire';

  @override
  String chatSearchMatchCount(int current, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total risultati',
      one: '1 risultato',
    );
    return '$current di $_temp0';
  }

  @override
  String get failedToStartChat => 'Impossibile avviare la chat. Riprova.';

  @override
  String get inviteToWhiteNoise => 'Invita su White Noise';

  @override
  String inviteToWhiteNoiseDescription(String name) {
    return '$name non è ancora su White Noise. Condividi l\'app per avviare una chat sicura.';
  }

  @override
  String get inviteMessage =>
      'Unisciti a me su White Noise. Nessun numero di telefono. Nessuna sorveglianza. Solo vera privacy. Scarica qui: https://www.whitenoise.chat/download';

  @override
  String get failedToUpdateFollow => 'Impossibile aggiornare lo stato del seguito. Riprova.';

  @override
  String get imagePickerError => 'Impossibile selezionare l\'immagine. Riprova.';

  @override
  String get scanNsec => 'Scansiona codice QR';

  @override
  String get scanNsecHint => 'Scansiona il codice QR della tua chiave privata per accedere.';

  @override
  String get cameraPermissionDenied => 'Permesso fotocamera negato';

  @override
  String get somethingWentWrong => 'Qualcosa è andato storto';

  @override
  String get scanNpub => 'Scansiona codice QR';

  @override
  String get scanNpubHint => 'Scansiona il codice QR di un contatto.';

  @override
  String get invalidNpub => 'Chiave pubblica non valida. Riprova.';

  @override
  String get you => 'Tu';

  @override
  String get timestampNow => 'Ora';

  @override
  String timestampMinutes(int count) {
    return '${count}m';
  }

  @override
  String timestampHours(int count) {
    return '${count}h';
  }

  @override
  String get timestampYesterday => 'Ieri';

  @override
  String get weekdayMonday => 'Lunedì';

  @override
  String get weekdayTuesday => 'Martedì';

  @override
  String get weekdayWednesday => 'Mercoledì';

  @override
  String get weekdayThursday => 'Giovedì';

  @override
  String get weekdayFriday => 'Venerdì';

  @override
  String get weekdaySaturday => 'Sabato';

  @override
  String get weekdaySunday => 'Domenica';

  @override
  String get monthJanShort => 'Gen';

  @override
  String get monthFebShort => 'Feb';

  @override
  String get monthMarShort => 'Mar';

  @override
  String get monthAprShort => 'Apr';

  @override
  String get monthMayShort => 'Mag';

  @override
  String get monthJunShort => 'Giu';

  @override
  String get monthJulShort => 'Lug';

  @override
  String get monthAugShort => 'Ago';

  @override
  String get monthSepShort => 'Set';

  @override
  String get monthOctShort => 'Ott';

  @override
  String get monthNovShort => 'Nov';

  @override
  String get monthDecShort => 'Dic';

  @override
  String get loginWithAmber => 'Accedi con Amber';

  @override
  String get signerConnectionError => 'Impossibile connettersi al signer. Riprova.';

  @override
  String get search => 'Cerca';

  @override
  String get filterChats => 'Chat';

  @override
  String get filterArchive => 'Archivio';

  @override
  String get signerErrorUserRejected => 'Accesso annullato';

  @override
  String get signerErrorNotConnected => 'Non connesso al signer. Riprova.';

  @override
  String get signerErrorNoSigner =>
      'Nessuna app signer trovata. Installa un signer compatibile con NIP-55.';

  @override
  String get signerErrorNoResponse => 'Nessuna risposta dal signer. Riprova.';

  @override
  String get signerErrorNoPubkey => 'Impossibile ottenere la chiave pubblica dal signer.';

  @override
  String get signerErrorNoResult => 'Il signer non ha restituito un risultato.';

  @override
  String get signerErrorNoEvent => 'Il signer non ha restituito un evento firmato.';

  @override
  String get signerErrorRequestInProgress => 'Un\'altra richiesta è in corso. Attendi.';

  @override
  String get signerErrorNoActivity => 'Impossibile avviare il signer. Riprova.';

  @override
  String get signerErrorLaunchError => 'Avvio dell\'app signer non riuscito.';

  @override
  String get signerErrorUnknown => 'Si è verificato un errore con il signer. Riprova.';

  @override
  String get messageNotFound => 'Messaggio non trovato';

  @override
  String get pin => 'Fissa';

  @override
  String get unpin => 'Rimuovi';

  @override
  String get mute => 'Silenzia';

  @override
  String get archive => 'Archivia';

  @override
  String get failedToPinChat => 'Impossibile aggiornare il fissaggio. Riprova.';

  @override
  String get carouselPrivacyTitle => 'Privacy e sicurezza';

  @override
  String get carouselPrivacyDescription =>
      'Mantieni le tue conversazioni private. Anche in caso di violazione, i tuoi messaggi rimangono sicuri.';

  @override
  String get carouselIdentityTitle => 'Scegli la tua identità';

  @override
  String get carouselIdentityDescription =>
      'Chatta senza rivelare il tuo numero di telefono o email. Scegli la tua identità: nome reale, pseudonimo o anonimo.';

  @override
  String get carouselDecentralizedTitle => 'Decentralizzato e senza permessi';

  @override
  String get carouselDecentralizedDescription =>
      'Nessuna autorità centrale controlla la tua comunicazione – nessun permesso necessario, nessuna censura possibile.';

  @override
  String get learnMore => 'Scopri di più';

  @override
  String get backToSignUp => 'Torna alla registrazione';

  @override
  String get deleteAllData => 'Elimina Tutti i Dati';

  @override
  String get deleteAllDataConfirmation => 'Eliminare tutti i dati?';

  @override
  String get deleteAllDataWarning =>
      'Questo eliminerà permanentemente tutte le tue chat, messaggi e impostazioni da questo dispositivo. Questa azione non può essere annullata.';

  @override
  String get deleteAllDataError => 'Impossibile eliminare tutti i dati. Riprova.';

  @override
  String get chatInformation => 'Informazioni chat';

  @override
  String get addAsContact => 'Aggiungi come contatto';

  @override
  String get removeAsContact => 'Rimuovi come contatto';

  @override
  String get addToGroup => 'Aggiungi al gruppo';

  @override
  String get addToAnotherGroup => 'Aggiungi a un altro gruppo';

  @override
  String get relayResolutionTitle => 'Configurazione relay';

  @override
  String get relayResolutionDescription =>
      'Non abbiamo trovato le tue liste di relay sulla rete. Puoi fornire un relay dove sono pubblicate le tue liste oppure utilizzare i nostri relay predefiniti per iniziare.';

  @override
  String get relayResolutionUseDefaults => 'Usa relay predefiniti';

  @override
  String get relayResolutionTryRelay => 'Cerca relay';

  @override
  String get relayResolutionRelayPlaceholder => 'wss://relay.example.com';

  @override
  String get relayResolutionRelayLabel => 'URL del relay';

  @override
  String get relayResolutionNotFound =>
      'Nessuna lista di relay trovata su questo relay. Prova con un altro o usa quelli predefiniti.';

  @override
  String get loginErrorInvalidKey =>
      'nsec non valido. Assicurati di averlo inserito correttamente.';

  @override
  String get loginErrorNoRelayConnections =>
      'Impossibile connettersi ai relay. Controlla la connessione e riprova.';

  @override
  String get loginErrorTimeout => 'Accesso scaduto. Riprova.';

  @override
  String get loginErrorGeneric => 'Si è verificato un errore durante l\'accesso. Riprova.';

  @override
  String get loginErrorNoLoginInProgress => 'Nessun accesso in corso. Ricomincia da capo.';

  @override
  String get loginErrorInternal => 'Si è verificato un errore interno. Riprova.';

  @override
  String get loginPasteNothingToPaste => 'Niente da incollare';

  @override
  String get loginPasteFailed => 'Impossibile incollare dagli appunti';

  @override
  String get openSettings => 'Apri impostazioni';

  @override
  String get scannerError => 'Errore scanner';

  @override
  String get scannerErrorDescription => 'Qualcosa è andato storto con lo scanner. Riprova.';

  @override
  String get cameraPermissionDeniedDescription =>
      'Abilita l\'accesso alla fotocamera nelle impostazioni del dispositivo per scansionare i codici QR.';

  @override
  String get retry => 'Riprova';

  @override
  String get groupInformation => 'Informazioni del gruppo';

  @override
  String get editGroup => 'Modifica gruppo';

  @override
  String get editGroupAction => 'Modifica gruppo';

  @override
  String get groupNameLabel => 'Nome';

  @override
  String get groupDescriptionLabel => 'Informazioni';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Membri',
      one: '1 Membro',
    );
    return '$_temp0';
  }

  @override
  String get adminBadge => 'Admin';

  @override
  String get membersLabel => 'Membri:';

  @override
  String get memberBadge => 'Membro';

  @override
  String get sendMessage => 'Invia messaggio';

  @override
  String get makeAdmin => 'Rendi admin';

  @override
  String get removeAdminRole => 'Rimuovi admin';

  @override
  String get removeFromGroup => 'Rimuovi dal gruppo';

  @override
  String get removeFromGroupConfirmation => 'Rimuovere dal gruppo?';

  @override
  String get removeFromGroupWarning =>
      'Questo membro verrà rimosso dal gruppo e non potrà più vedere i nuovi messaggi.';

  @override
  String get makeAdminConfirmation => 'Rendere admin?';

  @override
  String get makeAdminWarning =>
      'Questo membro potrà gestire il gruppo, aggiungere o rimuovere membri e modificare le impostazioni del gruppo.';

  @override
  String get removeAdminConfirmation => 'Rimuovere admin?';

  @override
  String get removeAdminWarning =>
      'Questo membro non potrà più gestire il gruppo, aggiungere o rimuovere membri né modificare le impostazioni del gruppo.';

  @override
  String get failedToRemoveFromGroup => 'Impossibile rimuovere il membro. Riprova.';

  @override
  String get failedToMakeAdmin => 'Impossibile rendere admin. Riprova.';

  @override
  String get failedToRemoveAdmin => 'Impossibile rimuovere admin. Riprova.';

  @override
  String get groupUpdatedSuccessfully => 'Gruppo aggiornato con successo';

  @override
  String get groupLoadError => 'Impossibile caricare il gruppo. Riprova.';

  @override
  String get groupSaveError => 'Impossibile salvare il gruppo. Riprova.';

  @override
  String get failedToFetchGroupMembers => 'Impossibile caricare i membri del gruppo. Riprova.';

  @override
  String get failedToAddMembers => 'Impossibile aggiungere membri. Riprova.';

  @override
  String get groupImageUploadFailed => 'Gruppo creato, ma il caricamento dell\'immagine è fallito.';

  @override
  String updateNeeded(String name) {
    return '$name deve aggiornare';
  }

  @override
  String updateNeededDescription(String name) {
    return 'Non puoi ancora avviare una chat sicura con $name. Deve aggiornare White Noise prima che la messaggistica sicura funzioni.';
  }

  @override
  String addToGroupConfirmation(String userName, String groupName) {
    return 'Aggiungere $userName a $groupName?';
  }

  @override
  String get unknownInviteToWhiteNoiseDescription =>
      'Questo utente non è ancora su White Noise. Condividi l\'app per avviare una chat sicura.';

  @override
  String get unknownUserNeedsUpdate => 'L\'utente deve aggiornare';

  @override
  String get unknownUserNeedsUpdateDescription =>
      'Non puoi ancora avviare una chat sicura con questo utente. Deve aggiornare White Noise prima che la messaggistica sicura funzioni.';

  @override
  String get add => 'Aggiungi';

  @override
  String get noGroupsAvailable => 'Nessun gruppo disponibile';

  @override
  String get noAdminGroupsAvailable =>
      'Non sei ancora admin in nessun gruppo. Crea un gruppo per aggiungere persone.';

  @override
  String get profilesTitle => 'Profili';

  @override
  String get noAccountsAvailable => 'Nessun account disponibile';

  @override
  String get connectAnotherProfile => 'Collega un altro profilo';

  @override
  String get rawDebugView => 'Modalità debug';

  @override
  String get rawDebugViewDescription => 'Mostra i dati grezzi dei messaggi nella chat';

  @override
  String get rawDebugViewTitle => 'Modalità Debug';

  @override
  String get rawDebugViewGroupId => 'ID del Gruppo';

  @override
  String rawDebugViewMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messaggi',
      one: '1 messaggio',
    );
    return '$_temp0';
  }

  @override
  String get rawDebugViewCopied => 'Copiato negli appunti';

  @override
  String get appLogsTitle => 'Registri dell\'app';

  @override
  String get appLogsViewLogs => 'Visualizza registri';

  @override
  String get appLogsViewLogsDescription => 'Visualizza tutti gli output del Logger nell\'app';

  @override
  String get appLogsClear => 'Cancella';

  @override
  String get appLogsEraseAll => 'Cancella tutto';

  @override
  String get appLogsEmpty => 'Nessun registro ancora';

  @override
  String get appLogsSearchPlaceholder => 'Cerca nei registri...';

  @override
  String get appLogsAddPatternPlaceholder => 'Aggiungi filtro';

  @override
  String get appLogsIgnore => 'Ignora';

  @override
  String get appLogsShow => 'Mostra';

  @override
  String get appLogsClearFilters => 'Cancella filtri';

  @override
  String get appLogsLive => 'Live';

  @override
  String appLogsFilteredCount(int shown, int total) {
    return '$shown di $total';
  }

  @override
  String get appLogsCopyAll => 'Copia tutto';

  @override
  String get invalidRelayUrlScheme => 'L\'URL deve iniziare con wss:// o ws://';

  @override
  String get invalidRelayUrl => 'URL relay non valida';

  @override
  String get thisMessageWasDeleted => 'Questo messaggio è stato eliminato.';

  @override
  String get relayControlStateLoadError =>
      'Impossibile caricare lo stato di controllo del relay. Per favore, riprova.';

  @override
  String get fatalErrorCopyError => 'Copia errore';

  @override
  String get fatalErrorErrorCopied => 'Errore copiato negli appunti';

  @override
  String get fatalErrorTitle => 'Oh no!';

  @override
  String get fatalErrorDescription =>
      'Abbiamo avuto un problema nel caricamento dell\'app. Non sei tu, siamo noi e ci scusiamo.\n\nAiutaci a risolverlo. Tocca sotto per inviare questo errore al nostro team.';

  @override
  String get reportBug => 'Segnala un bug';

  @override
  String get reportBugDescription =>
      'Aiutaci a migliorare White Noise descrivendo il problema riscontrato.';

  @override
  String get reportBugWhatWentWrong => 'Cosa è andato storto?';

  @override
  String get reportBugWhatWentWrongPlaceholder => 'Descrivi il problema riscontrato...';

  @override
  String get reportBugStepsToReproduce => 'Passaggi per riprodurre';

  @override
  String get reportBugStepsToReproducePlaceholder => '1. Vai a...\n2. Tocca su...\n3. Vedi errore';

  @override
  String get reportBugFrequency => 'Quanto spesso succede?';

  @override
  String get reportBugFrequencyOnce => 'Una volta';

  @override
  String get reportBugFrequencyAlways => 'Sempre';

  @override
  String get reportBugFrequencySometimes => 'A volte';

  @override
  String get reportBugIncludeNpub => 'Includi il tuo npub';

  @override
  String get reportBugIncludeNpubDescription =>
      'Ci permette di ricontattarti se necessario; lasciando il toggle disattivato la segnalazione rimane anonima.';

  @override
  String get reportBugSend => 'Invia segnalazione';

  @override
  String get reportBugSuccess => 'Segnalazione bug inviata. Grazie!';

  @override
  String get reportBugError => 'Invio della segnalazione fallito. Riprova.';

  @override
  String get reportBugWhatWentWrongRequired => 'Descrivi cosa è andato storto.';

  @override
  String get failedToStartHelpChat => 'Failed to start help chat';
}
