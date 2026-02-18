// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'White Noise';

  @override
  String get sloganDecentralized => 'Décentralisé';

  @override
  String get sloganUncensorable => 'Incensurable';

  @override
  String get sloganSecureMessaging => 'Messagerie Sécurisée';

  @override
  String get login => 'Connexion';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get enterPrivateKey => 'Entrez votre clé privée';

  @override
  String get nsecPlaceholder => 'nsec...';

  @override
  String get setupProfile => 'Configurer le profil';

  @override
  String get chooseName => 'Choisissez un nom';

  @override
  String get enterYourName => 'Entrez votre nom';

  @override
  String get introduceYourself => 'Présentez-vous';

  @override
  String get writeSomethingAboutYourself => 'Écrivez quelque chose sur vous';

  @override
  String get cancel => 'Annuler';

  @override
  String get profileReady => 'Votre profil est prêt !';

  @override
  String get startConversationHint =>
      'Démarrez une conversation en ajoutant des amis ou en partageant votre profil.';

  @override
  String get shareYourProfile => 'Partager votre profil';

  @override
  String get startChat => 'Démarrer une discussion';

  @override
  String get settings => 'Paramètres';

  @override
  String get shareAndConnect => 'Partager et connecter';

  @override
  String get switchProfile => 'Changer de profil';

  @override
  String get addNewProfile => 'Ajouter un nouveau profil';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get profileKeys => 'Clés du profil';

  @override
  String get networkRelays => 'Relais réseau';

  @override
  String get appearance => 'Apparence';

  @override
  String get privacySecurity => 'Confidentialité et sécurité';

  @override
  String get donateToWhiteNoise => 'Faire un don à White Noise';

  @override
  String get developerSettings => 'Paramètres développeur';

  @override
  String get signOut => 'Déconnexion';

  @override
  String get appearanceTitle => 'Apparence';

  @override
  String get privacySecurityTitle => 'Confidentialité et sécurité';

  @override
  String get deleteAllAppData => 'Supprimer Toutes les Données de l\'App';

  @override
  String get deleteAppData => 'Supprimer les données de l\'app';

  @override
  String get deleteAllAppDataDescription =>
      'Effacer tous les profils, clés, chats et fichiers locaux de cet appareil.';

  @override
  String get deleteAllAppDataConfirmation => 'Supprimer toutes les données de l\'app ?';

  @override
  String get deleteAllAppDataWarning =>
      'Cela effacera tous les profils, clés, chats et fichiers locaux de cet appareil. Cette action est irréversible.';

  @override
  String get theme => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get profileKeysTitle => 'Clés du profil';

  @override
  String get publicKey => 'Clé publique';

  @override
  String get publicKeyCopied => 'Clé publique copiée dans le presse-papiers';

  @override
  String get publicKeyDescription =>
      'Votre clé publique (npub) peut être partagée avec d\'autres. Elle est utilisée pour vous identifier sur le réseau.';

  @override
  String get privateKey => 'Clé privée';

  @override
  String get privateKeyCopied => 'Clé privée copiée dans le presse-papiers';

  @override
  String get privateKeyDescription =>
      'Votre clé privée (nsec) doit rester secrète. Toute personne y ayant accès peut contrôler votre compte.';

  @override
  String get keepPrivateKeySecure => 'Gardez votre clé privée en sécurité';

  @override
  String get privateKeyWarning =>
      'Ne partagez pas votre clé privée publiquement et utilisez-la uniquement pour vous connecter à d\'autres apps Nostr.';

  @override
  String get nsecOnExternalSigner => 'La clé privée est stockée dans un signataire externe';

  @override
  String get nsecOnExternalSignerDescription =>
      'Votre clé privée n\'est pas disponible dans White Noise. Ouvrez votre signataire pour la consulter ou la gérer.';

  @override
  String get editProfileTitle => 'Modifier le profil';

  @override
  String get profileName => 'Nom du profil';

  @override
  String get nostrAddress => 'Adresse Nostr';

  @override
  String get nostrAddressPlaceholder => 'exemple@whitenoise.chat';

  @override
  String get aboutYou => 'À propos de vous';

  @override
  String get profileIsPublic => 'Le profil est public';

  @override
  String get profilePublicDescription =>
      'Les informations de votre profil seront visibles par tous sur le réseau.';

  @override
  String get discard => 'Annuler';

  @override
  String get discardChanges => 'Annuler les modifications';

  @override
  String get save => 'Enregistrer';

  @override
  String get profileUpdatedSuccessfully => 'Profil mis à jour avec succès';

  @override
  String errorLoadingProfile(String error) {
    return 'Erreur lors du chargement du profil : $error';
  }

  @override
  String error(String error) {
    return 'Erreur : $error';
  }

  @override
  String get profileLoadError => 'Impossible de charger le profil. Veuillez réessayer.';

  @override
  String get failedToLoadPrivateKey => 'Impossible de charger la clé privée. Veuillez réessayer.';

  @override
  String get profileSaveError => 'Impossible d\'enregistrer le profil. Veuillez réessayer.';

  @override
  String get networkRelaysTitle => 'Relais Réseau';

  @override
  String get myRelays => 'Mes Relais';

  @override
  String get myRelaysHelp =>
      'Relais que vous avez définis pour une utilisation dans toutes vos applications Nostr.';

  @override
  String get inboxRelays => 'Relais de Boîte de Réception';

  @override
  String get inboxRelaysHelp =>
      'Relais utilisés pour recevoir des invitations et démarrer des conversations sécurisées avec de nouveaux utilisateurs.';

  @override
  String get keyPackageRelays => 'Relais de Paquet de Clés';

  @override
  String get keyPackageRelaysHelp =>
      'Relais qui stockent votre clé sécurisée pour que d\'autres puissent vous inviter à des conversations chiffrées.';

  @override
  String get errorLoadingRelays => 'Erreur lors du chargement des relais';

  @override
  String get noRelaysConfigured => 'Aucun relais configuré';

  @override
  String get donateTitle => 'Faire un don à White Noise';

  @override
  String get donateDescription =>
      'En tant qu\'organisation à but non lucratif, White Noise existe uniquement pour votre vie privée et votre liberté, pas pour le profit. Votre soutien nous maintient indépendants et sans compromis.';

  @override
  String get lightningAddress => 'Adresse Lightning';

  @override
  String get bitcoinSilentPayment => 'Paiement Silencieux Bitcoin';

  @override
  String get copiedToClipboardThankYou => 'Copié dans le presse-papiers. Merci !';

  @override
  String get shareProfileTitle => 'Partager le profil';

  @override
  String get scanToConnect => 'Scanner pour se connecter';

  @override
  String get signOutTitle => 'Déconnexion';

  @override
  String get signOutConfirmation => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get signOutWarning =>
      'Lorsque vous vous déconnectez de White Noise, vos discussions seront supprimées de cet appareil et ne pourront pas être restaurées sur un autre appareil.';

  @override
  String get signOutWarningBackupKey =>
      'Si vous n\'avez pas sauvegardé votre clé privée, vous ne pourrez pas utiliser ce profil sur un autre service Nostr.';

  @override
  String get backUpPrivateKey => 'Sauvegardez votre clé privée';

  @override
  String get copyPrivateKeyHint =>
      'Copiez votre clé privée pour restaurer votre compte sur un autre appareil.';

  @override
  String get publicKeyCopyError => 'Échec de la copie de la clé publique. Veuillez réessayer.';

  @override
  String get noChatsYet => 'Pas encore de discussions';

  @override
  String get startConversation => 'Démarrer une conversation';

  @override
  String get welcomeNoticeTitle => 'Votre profil est prêt';

  @override
  String welcomeNoticeDescription(String findPeople, String shareProfile, String startANewChat) {
    return 'Appuyez sur $findPeople pour trouver vos amis. $shareProfile pour vous connecter avec des gens que vous connaissez, ou $startANewChat avec l\'icône de chat.';
  }

  @override
  String get findPeople => 'Trouver des personnes';

  @override
  String get startANewChat => 'démarrez une nouvelle discussion';

  @override
  String get noMessagesYet => 'Pas encore de messages';

  @override
  String get messagePlaceholder => 'Message';

  @override
  String get failedToSendMessage => 'Échec de l\'envoi du message. Veuillez réessayer.';

  @override
  String get invitedToSecureChat => 'Vous êtes invité à une discussion sécurisée';

  @override
  String get decline => 'Refuser';

  @override
  String get accept => 'Accepter';

  @override
  String failedToAcceptInvitation(String error) {
    return 'Échec de l\'acceptation de l\'invitation : $error';
  }

  @override
  String failedToDeclineInvitation(String error) {
    return 'Échec du refus de l\'invitation : $error';
  }

  @override
  String get startNewChat => 'Nouvelle discussion';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get noFollowsYet => 'Pas encore d\'abonnements';

  @override
  String get searchByNameOrNpub => 'Nom ou npub1...';

  @override
  String get developerSettingsTitle => 'Paramètres Développeur';

  @override
  String get publishNewKeyPackage => 'Publier un Nouveau Paquet de Clés';

  @override
  String get refreshKeyPackages => 'Actualiser les Paquets de Clés';

  @override
  String get deleteAllKeyPackages => 'Supprimer Tous les Paquets de Clés';

  @override
  String keyPackagesCount(int count) {
    return 'Paquets de Clés ($count)';
  }

  @override
  String get noKeyPackagesFound => 'Aucun paquet de clés trouvé';

  @override
  String get keyPackagePublished => 'Paquet de clés publié';

  @override
  String get keyPackagesRefreshed => 'Paquets de clés actualisés';

  @override
  String get keyPackagesDeleted => 'Tous les paquets de clés supprimés';

  @override
  String get keyPackageDeleted => 'Paquet de clés supprimé';

  @override
  String packageNumber(int number) {
    return 'Paquet $number';
  }

  @override
  String get goBack => 'Retour';

  @override
  String get reportError => 'Signaler une erreur';

  @override
  String get workInProgress => 'Nous y travaillons';

  @override
  String get wipMessage =>
      'Nous travaillons sur cette fonctionnalité. Pour soutenir le développement, faites un don à White Noise';

  @override
  String get donate => 'Faire un don';

  @override
  String get addRelay => 'Ajouter un Relais';

  @override
  String get enterRelayAddress => 'Entrez l\'adresse du relais';

  @override
  String get relayAddressPlaceholder => 'wss://relay.example.com';

  @override
  String get removeRelay => 'Supprimer le Relais ?';

  @override
  String get removeRelayConfirmation =>
      'Êtes-vous sûr de vouloir supprimer ce relais ? Cette action ne peut pas être annulée.';

  @override
  String get remove => 'Supprimer';

  @override
  String get messageActions => 'Actions du message';

  @override
  String get reply => 'Répondre';

  @override
  String get delete => 'Supprimer';

  @override
  String get failedToDeleteMessage => 'Échec de la suppression du message. Veuillez réessayer.';

  @override
  String get failedToSendReaction => 'Échec de l\'envoi de la réaction. Veuillez réessayer.';

  @override
  String get failedToRemoveReaction =>
      'Échec de la suppression de la réaction. Veuillez réessayer.';

  @override
  String get unknownUser => 'Utilisateur inconnu';

  @override
  String get unknownGroup => 'Groupe inconnu';

  @override
  String get hasInvitedYouToSecureChat => 'Vous a invité à une discussion sécurisée';

  @override
  String userInvitedYouToSecureChat(String name) {
    return '$name vous a invité à une discussion sécurisée';
  }

  @override
  String get youHaveBeenInvitedToSecureChat => 'Vous avez été invité à une discussion sécurisée';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Système';

  @override
  String get languageUpdateFailed =>
      'Échec de l\'enregistrement de la préférence linguistique. Veuillez réessayer.';

  @override
  String get timeJustNow => 'à l\'instant';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'hier',
    );
    return '$_temp0';
  }

  @override
  String get profile => 'Profil';

  @override
  String get follow => 'Suivre';

  @override
  String get unfollow => 'Ne plus suivre';

  @override
  String get failedToStartChat => 'Échec du démarrage de la discussion. Veuillez réessayer.';

  @override
  String get inviteToWhiteNoise => 'Inviter sur White Noise';

  @override
  String inviteToWhiteNoiseDescription(String name) {
    return '$name n\'est pas encore sur White Noise. Partagez l\'application pour démarrer une discussion sécurisée.';
  }

  @override
  String get failedToUpdateFollow =>
      'Échec de la mise à jour du statut de suivi. Veuillez réessayer.';

  @override
  String get imagePickerError => 'Échec de la sélection de l\'image. Veuillez réessayer.';

  @override
  String get scanNsec => 'Scanner le code QR';

  @override
  String get scanNsecHint => 'Scannez le code QR de votre clé privée pour vous connecter.';

  @override
  String get cameraPermissionDenied => 'Autorisation caméra refusée';

  @override
  String get somethingWentWrong => 'Une erreur s\'est produite';

  @override
  String get scanNpub => 'Scanner le code QR';

  @override
  String get scanNpubHint => 'Scannez le code QR d\'un contact.';

  @override
  String get invalidNpub => 'Clé publique invalide. Veuillez réessayer.';

  @override
  String get you => 'Vous';

  @override
  String get timestampNow => 'Maintenant';

  @override
  String timestampMinutes(int count) {
    return '${count}m';
  }

  @override
  String timestampHours(int count) {
    return '${count}h';
  }

  @override
  String get timestampYesterday => 'Hier';

  @override
  String get weekdayMonday => 'Lundi';

  @override
  String get weekdayTuesday => 'Mardi';

  @override
  String get weekdayWednesday => 'Mercredi';

  @override
  String get weekdayThursday => 'Jeudi';

  @override
  String get weekdayFriday => 'Vendredi';

  @override
  String get weekdaySaturday => 'Samedi';

  @override
  String get weekdaySunday => 'Dimanche';

  @override
  String get monthJanShort => 'Jan';

  @override
  String get monthFebShort => 'Fév';

  @override
  String get monthMarShort => 'Mar';

  @override
  String get monthAprShort => 'Avr';

  @override
  String get monthMayShort => 'Mai';

  @override
  String get monthJunShort => 'Juin';

  @override
  String get monthJulShort => 'Juil';

  @override
  String get monthAugShort => 'Août';

  @override
  String get monthSepShort => 'Sep';

  @override
  String get monthOctShort => 'Oct';

  @override
  String get monthNovShort => 'Nov';

  @override
  String get monthDecShort => 'Déc';

  @override
  String get loginWithAmber => 'Se connecter avec Amber';

  @override
  String get signerConnectionError => 'Impossible de se connecter au signer. Veuillez réessayer.';

  @override
  String get search => 'Rechercher';

  @override
  String get filterChats => 'Discussions';

  @override
  String get filterArchive => 'Archives';

  @override
  String get signerErrorUserRejected => 'Connexion annulée';

  @override
  String get signerErrorNotConnected => 'Non connecté au signer. Veuillez réessayer.';

  @override
  String get signerErrorNoSigner =>
      'Aucune application signer trouvée. Veuillez installer un signer compatible NIP-55.';

  @override
  String get signerErrorNoResponse => 'Aucune réponse du signer. Veuillez réessayer.';

  @override
  String get signerErrorNoPubkey => 'Impossible d\'obtenir la clé publique du signer.';

  @override
  String get signerErrorNoResult => 'Le signer n\'a renvoyé aucun résultat.';

  @override
  String get signerErrorNoEvent => 'Le signer n\'a renvoyé aucun événement signé.';

  @override
  String get signerErrorRequestInProgress => 'Une autre requête est en cours. Veuillez patienter.';

  @override
  String get signerErrorNoActivity => 'Impossible de lancer le signer. Veuillez réessayer.';

  @override
  String get signerErrorLaunchError => 'Échec du lancement de l\'application signer.';

  @override
  String get signerErrorUnknown => 'Une erreur s\'est produite avec le signer. Veuillez réessayer.';

  @override
  String get messageNotFound => 'Message introuvable';

  @override
  String get pin => 'Épingler';

  @override
  String get unpin => 'Désépingler';

  @override
  String get mute => 'Muet';

  @override
  String get archive => 'Archiver';

  @override
  String get failedToPinChat => 'Échec de l\'épinglage. Veuillez réessayer.';

  @override
  String get carouselPrivacyTitle => 'Confidentialité et sécurité';

  @override
  String get carouselPrivacyDescription =>
      'Gardez vos conversations privées. Même en cas de violation, vos messages restent sécurisés.';

  @override
  String get carouselIdentityTitle => 'Choisissez votre identité';

  @override
  String get carouselIdentityDescription =>
      'Discutez sans révéler votre numéro de téléphone ou votre e-mail. Choisissez votre identité : nom réel, pseudonyme ou anonyme.';

  @override
  String get carouselDecentralizedTitle => 'Décentralisé et sans permission';

  @override
  String get carouselDecentralizedDescription =>
      'Aucune autorité centrale ne contrôle votre communication – pas de permissions nécessaires, pas de censure possible.';

  @override
  String get learnMore => 'En savoir plus';

  @override
  String get backToSignUp => 'Retour à l\'inscription';

  @override
  String get deleteAllData => 'Supprimer Toutes les Données';

  @override
  String get deleteAllDataConfirmation => 'Supprimer toutes les données ?';

  @override
  String get deleteAllDataWarning =>
      'Cela supprimera définitivement tous vos chats, messages et paramètres de cet appareil. Cette action ne peut pas être annulée.';

  @override
  String get deleteAllDataError =>
      'Échec de la suppression de toutes les données. Veuillez réessayer.';

  @override
  String get chatInformation => 'Informations du chat';

  @override
  String get addAsContact => 'Ajouter comme contact';

  @override
  String get removeAsContact => 'Retirer des contacts';

  @override
  String get addToGroup => 'Ajouter à un groupe';

  @override
  String get relayResolutionTitle => 'Configuration du relais';

  @override
  String get relayResolutionDescription =>
      'Nous n\'avons pas trouvé vos listes de relais sur le réseau. Vous pouvez fournir un relais où vos listes sont publiées ou utiliser nos relais par défaut pour commencer.';

  @override
  String get relayResolutionUseDefaults => 'Utiliser les relais par défaut';

  @override
  String get relayResolutionTryRelay => 'Rechercher un relais';

  @override
  String get relayResolutionRelayPlaceholder => 'wss://relais.exemple.com';

  @override
  String get relayResolutionRelayLabel => 'URL du relais';

  @override
  String get relayResolutionNotFound =>
      'Aucune liste de relais trouvée sur ce relais. Essayez un autre ou utilisez les valeurs par défaut.';

  @override
  String get loginErrorInvalidKey =>
      'Format de clé privée invalide. Veuillez vérifier et réessayer.';

  @override
  String get loginErrorNoRelayConnections =>
      'Impossible de se connecter à des relais. Vérifiez votre connexion et réessayez.';

  @override
  String get loginErrorTimeout => 'La connexion a expiré. Veuillez réessayer.';

  @override
  String get loginErrorGeneric =>
      'Une erreur est survenue lors de la connexion. Veuillez réessayer.';

  @override
  String get loginErrorNoLoginInProgress => 'Aucune connexion en cours. Veuillez recommencer.';

  @override
  String get loginErrorInternal => 'Une erreur interne est survenue. Veuillez réessayer.';

  @override
  String get loginPasteNothingToPaste => 'Rien à coller';

  @override
  String get loginPasteFailed => 'Échec du collage depuis le presse-papiers';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get scannerError => 'Erreur du scanner';

  @override
  String get scannerErrorDescription =>
      'Une erreur s\'est produite avec le scanner. Veuillez réessayer.';

  @override
  String get cameraPermissionDeniedDescription =>
      'Veuillez activer l\'accès à la caméra dans les paramètres de votre appareil pour scanner les codes QR.';

  @override
  String get retry => 'Réessayer';
}
