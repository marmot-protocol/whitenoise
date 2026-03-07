// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
  String get sloganDecentralized => 'Descentralizado';

  @override
  String get sloganUncensorable => 'Incensurable';

  @override
  String get sloganSecureMessaging => 'Mensajería Segura';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get signUp => 'Registrarse';

  @override
  String get loginTitle => 'Introduce tu llave privada';

  @override
  String get enterPrivateKey => 'Introduce tu llave privada';

  @override
  String get nsecPlaceholder => 'nsec...';

  @override
  String get setupProfile => 'Configurar perfil';

  @override
  String get chooseName => 'Elige un nombre';

  @override
  String get enterYourName => 'Introduce tu nombre';

  @override
  String get introduceYourself => 'Preséntate';

  @override
  String get writeSomethingAboutYourself => 'Escribe algo sobre ti';

  @override
  String get cancel => 'Cancelar';

  @override
  String get profileReady => '¡Tu perfil está listo!';

  @override
  String get startConversationHint =>
      'Inicia una conversación añadiendo amigos o compartiendo tu perfil.';

  @override
  String get share => 'Compartir';

  @override
  String get shareYourProfile => 'Compartir tu perfil';

  @override
  String get startChat => 'Iniciar chat';

  @override
  String get settings => 'Configuración';

  @override
  String get shareAndConnect => 'Compartir y conectar';

  @override
  String get switchProfile => 'Cambiar perfil';

  @override
  String get addNewProfile => 'Añadir un nuevo perfil';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get profileKeys => 'Llaves del perfil';

  @override
  String get networkRelays => 'Relés de red';

  @override
  String get appearance => 'Apariencia';

  @override
  String get privacySecurity => 'Privacidad y seguridad';

  @override
  String get donateToWhiteNoise => 'Donar a White Noise';

  @override
  String get developerSettings => 'Ajustes de desarrollador';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get appearanceTitle => 'Apariencia';

  @override
  String get privacySecurityTitle => 'Privacidad y seguridad';

  @override
  String get deleteAllAppData => 'Eliminar Todos los Datos de la App';

  @override
  String get deleteAppData => 'Eliminar datos de la app';

  @override
  String get deleteAllAppDataDescription =>
      'Borrar todos los perfiles, claves, chats y archivos locales de este dispositivo.';

  @override
  String get deleteAllAppDataConfirmation => '¿Eliminar todos los datos de la app?';

  @override
  String get deleteAllAppDataWarning =>
      'Esto eliminará todos los perfiles, claves, chats y archivos locales de este dispositivo. Esta acción no se puede deshacer.';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get profileKeysTitle => 'Llaves del perfil';

  @override
  String get publicKey => 'Llave pública';

  @override
  String get publicKeyCopied => 'Llave pública copiada al portapapeles';

  @override
  String get publicKeyDescription =>
      'Tu llave pública (npub) puede compartirse con otros. Se usa para identificarte en la red.';

  @override
  String get privateKey => 'Llave privada';

  @override
  String get privateKeyCopied => 'Llave privada copiada al portapapeles';

  @override
  String get privateKeyDescription =>
      'Tu llave privada (nsec) debe mantenerse en secreto. Cualquiera con acceso a ella puede controlar tu cuenta.';

  @override
  String get keepPrivateKeySecure => 'Mantén tu llave privada segura';

  @override
  String get privateKeyWarning =>
      'No compartas tu llave privada públicamente y úsala solo para iniciar sesión en otros servicios de Nostr.';

  @override
  String get nsecOnExternalSigner => 'La llave privada está almacenada en un firmante externo';

  @override
  String get nsecOnExternalSignerDescription =>
      'Tu llave privada no está disponible en White Noise. Abre tu firmante para verla o gestionarla.';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get profileName => 'Nombre del perfil';

  @override
  String get nostrAddress => 'Dirección Nostr';

  @override
  String get nostrAddressPlaceholder => 'ejemplo@whitenoise.chat';

  @override
  String get aboutYou => 'Sobre ti';

  @override
  String get profileIsPublic => 'El perfil es público';

  @override
  String get profilePublicDescription =>
      'La información de tu perfil será visible para todos en la red.';

  @override
  String get discard => 'Descartar';

  @override
  String get discardChanges => 'Descartar cambios';

  @override
  String get save => 'Guardar';

  @override
  String get profileUpdatedSuccessfully => 'Perfil actualizado correctamente';

  @override
  String errorLoadingProfile(String error) {
    return 'Error al cargar el perfil: $error';
  }

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String get profileLoadError => 'No se pudo cargar el perfil. Por favor, inténtelo de nuevo.';

  @override
  String get failedToLoadPrivateKey =>
      'No se pudo cargar la llave privada. Por favor, inténtelo de nuevo.';

  @override
  String get profileSaveError => 'No se pudo guardar el perfil. Por favor, inténtelo de nuevo.';

  @override
  String get networkRelaysTitle => 'Relés de Red';

  @override
  String get myRelays => 'Mis Relés';

  @override
  String get myRelaysHelp => 'Relés que has definido para usar en todas tus aplicaciones Nostr.';

  @override
  String get inboxRelays => 'Relés de Bandeja de Entrada';

  @override
  String get inboxRelaysHelp =>
      'Relés usados para recibir invitaciones e iniciar conversaciones seguras con nuevos usuarios.';

  @override
  String get keyPackageRelays => 'Relés de Paquete de Llaves';

  @override
  String get keyPackageRelaysHelp =>
      'Relés que almacenan tu llave segura para que otros puedan invitarte a conversaciones cifradas.';

  @override
  String get errorLoadingRelays => 'Error al cargar los relés';

  @override
  String get noRelaysConfigured => 'No hay relés configurados';

  @override
  String get donateTitle => 'Donar a White Noise';

  @override
  String get donateDescription =>
      'Como organización sin fines de lucro, White Noise existe únicamente para tu privacidad y libertad, no para obtener ganancias. Tu apoyo nos mantiene independientes y sin compromisos.';

  @override
  String get lightningAddress => 'Dirección Lightning';

  @override
  String get bitcoinSilentPayment => 'Pago Silencioso de Bitcoin';

  @override
  String get copiedToClipboardThankYou => 'Copiado al portapapeles. ¡Gracias!';

  @override
  String get shareProfileTitle => 'Compartir perfil';

  @override
  String get scanToConnect => 'Escanear para conectar';

  @override
  String get signOutTitle => 'Cerrar sesión';

  @override
  String get signOutConfirmation => '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get signOutWarning =>
      'Cuando cierres sesión en White Noise, tus chats se eliminarán de este dispositivo y no podrán restaurarse en otro dispositivo.';

  @override
  String get signOutWarningBackupKey =>
      'Si no has respaldado tu llave privada, no podrás usar este perfil en ningún otro servicio Nostr.';

  @override
  String get backUpPrivateKey => 'Respalda tu llave privada';

  @override
  String get copyPrivateKeyHint =>
      'Copia tu llave privada para restaurar tu cuenta en otro dispositivo.';

  @override
  String get publicKeyCopyError =>
      'Error al copiar la llave pública. Por favor, inténtalo de nuevo.';

  @override
  String get noChatsYet => 'Aún no hay chats';

  @override
  String get startConversation => 'Inicia una conversación';

  @override
  String get welcomeNoticeTitle => 'Tu perfil está listo';

  @override
  String welcomeNoticeDescription(String findPeople, String shareProfile, String startANewChat) {
    return 'Toca $findPeople para encontrar a tus amigos. $shareProfile para conectar con gente que conoces, o $startANewChat usando el icono de chat.';
  }

  @override
  String get findPeople => 'Buscar personas';

  @override
  String get startANewChat => 'inicia un nuevo chat';

  @override
  String get noMessagesYet => 'Aún no hay mensajes';

  @override
  String get messagePlaceholder => 'Mensaje';

  @override
  String get failedToSendMessage => 'Error al enviar el mensaje. Por favor, inténtalo de nuevo.';

  @override
  String get invitedToSecureChat => 'Has sido invitado a un chat seguro';

  @override
  String get invitedYouToChatSuffix => ' te ha invitado al chat';

  @override
  String get decline => 'Rechazar';

  @override
  String get accept => 'Aceptar';

  @override
  String failedToAcceptInvitation(String error) {
    return 'Error al aceptar la invitación: $error';
  }

  @override
  String failedToDeclineInvitation(String error) {
    return 'Error al rechazar la invitación: $error';
  }

  @override
  String get startNewChat => 'Iniciar nuevo chat';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get noFollowsYet => 'Aún no hay seguidos';

  @override
  String get searchByNameOrNpub => 'Nombre o npub1...';

  @override
  String get developerSettingsTitle => 'Ajustes de Desarrollador';

  @override
  String get publishNewKeyPackage => 'Publicar Nuevo Paquete de Llaves';

  @override
  String get refreshKeyPackages => 'Actualizar Paquetes de Llaves';

  @override
  String get deleteAllKeyPackages => 'Eliminar Todos los Paquetes de Llaves';

  @override
  String keyPackagesCount(int count) {
    return 'Paquetes de Llaves ($count)';
  }

  @override
  String get noKeyPackagesFound => 'No se encontraron paquetes de llaves';

  @override
  String get keyPackagePublished => 'Paquete de llaves publicado';

  @override
  String get keyPackagesRefreshed => 'Paquetes de llaves actualizados';

  @override
  String get keyPackagesDeleted => 'Todos los paquetes de llaves eliminados';

  @override
  String get keyPackageDeleted => 'Paquete de llaves eliminado';

  @override
  String packageNumber(int number) {
    return 'Paquete $number';
  }

  @override
  String get goBack => 'Volver';

  @override
  String get createGroup => 'Crear grupo';

  @override
  String get newGroupChat => 'Nuevo chat grupal';

  @override
  String get selectMembers => 'Seleccionar Miembros';

  @override
  String selectedCount(int count) {
    return '$count seleccionados';
  }

  @override
  String get clearSelection => 'Limpiar';

  @override
  String get continueButton => 'Continuar';

  @override
  String get setUpGroup => 'Configurar grupo';

  @override
  String get groupName => 'Nombre del Grupo';

  @override
  String get groupNamePlaceholder => 'Ingrese el nombre del grupo';

  @override
  String get groupDescription => 'Descripción del Grupo';

  @override
  String get description => 'Descripción';

  @override
  String get groupDescriptionPlaceholder => '¿Para qué es este grupo?';

  @override
  String members(int count) {
    return '$count miembros';
  }

  @override
  String invitingMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Invitando miembros:',
      one: 'Invitando miembro:',
    );
    return '$_temp0';
  }

  @override
  String get usersWithoutKeyPackages => 'Usuarios sin paquetes de claves (no se pueden agregar)';

  @override
  String usersNotOnWhiteNoise(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Estos usuarios no están en White Noise',
      one: 'Este usuario no está en White Noise',
    );
    return '$_temp0';
  }

  @override
  String usersNotOnWhiteNoiseDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Estos usuarios no se pueden agregar al grupo porque no tienen White Noise instalado o aún no han publicado sus paquetes de claves.',
      one:
          'Este usuario no se puede agregar al grupo porque no tiene White Noise instalado o aún no ha publicado su paquete de claves.',
    );
    return '$_temp0';
  }

  @override
  String get uploadingImage => 'Subiendo imagen...';

  @override
  String get creatingGroup => 'Creando grupo...';

  @override
  String get groupNameRequired => 'Se requiere el nombre del grupo';

  @override
  String get noUsersWithKeyPackages => 'No hay usuarios con paquetes de claves para agregar';

  @override
  String get createGroupFailed => 'Error al crear grupo';

  @override
  String get reportError => 'Reportar error';

  @override
  String get wipMessage =>
      'Estamos trabajando en esta función. Para apoyar el desarrollo, dona a White Noise';

  @override
  String get donate => 'Donar';

  @override
  String get addRelay => 'Añadir Relé';

  @override
  String get enterRelayAddress => 'Introduce la dirección del relé';

  @override
  String get relayAddressPlaceholder => 'wss://rele.ejemplo.com';

  @override
  String get removeRelay => '¿Eliminar Relé?';

  @override
  String get removeRelayConfirmation =>
      '¿Estás seguro de que quieres eliminar este relé? Esta acción no se puede deshacer.';

  @override
  String get remove => 'Eliminar';

  @override
  String get messageActions => 'Acciones del mensaje';

  @override
  String get reply => 'Responder';

  @override
  String get copyMessage => 'Copiar';

  @override
  String get delete => 'Eliminar';

  @override
  String get failedToDeleteMessage =>
      'Error al eliminar el mensaje. Por favor, inténtalo de nuevo.';

  @override
  String get failedToSendReaction => 'Error al enviar la reacción. Por favor, inténtalo de nuevo.';

  @override
  String get failedToRemoveReaction =>
      'Error al eliminar la reacción. Por favor, inténtalo de nuevo.';

  @override
  String get unknownUser => 'Usuario desconocido';

  @override
  String get unknownGroup => 'Grupo desconocido';

  @override
  String get hasInvitedYouToSecureChat => 'Te ha invitado a un chat seguro';

  @override
  String userInvitedYouToSecureChat(String name) {
    return '$name te ha invitado a un chat seguro';
  }

  @override
  String get youHaveBeenInvitedToSecureChat => 'Has sido invitado a un chat seguro';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageUpdateFailed =>
      'Error al guardar la preferencia de idioma. Por favor, inténtalo de nuevo.';

  @override
  String get timeJustNow => 'ahora mismo';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count minutos',
      one: 'hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count horas',
      one: 'hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'ayer',
    );
    return '$_temp0';
  }

  @override
  String get profile => 'Perfil';

  @override
  String get follow => 'Seguir';

  @override
  String get unfollow => 'Dejar de seguir';

  @override
  String chatSearchMatchCount(int current, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total coincidencias',
      one: '1 coincidencia',
    );
    return '$current de $_temp0';
  }

  @override
  String get failedToStartChat => 'Error al iniciar el chat. Por favor, inténtalo de nuevo.';

  @override
  String get inviteToWhiteNoise => 'Invitar a White Noise';

  @override
  String inviteToWhiteNoiseDescription(String name) {
    return '$name aún no está en White Noise. Comparte la app para iniciar un chat seguro.';
  }

  @override
  String get inviteMessage =>
      'Únete a mí en White Noise. Sin número de teléfono. Sin vigilancia. Solo privacidad real. Descárgalo aquí: https://www.whitenoise.chat/download';

  @override
  String get failedToUpdateFollow =>
      'Error al actualizar el estado de seguimiento. Por favor, inténtalo de nuevo.';

  @override
  String get imagePickerError => 'Error al seleccionar imagen. Por favor, inténtalo de nuevo.';

  @override
  String get scanNsec => 'Escanear código QR';

  @override
  String get scanNsecHint => 'Escanea el código QR de tu llave privada para iniciar sesión.';

  @override
  String get cameraPermissionDenied => 'Permiso de cámara denegado';

  @override
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String get scanNpub => 'Escanear código QR';

  @override
  String get scanNpubHint => 'Escanea el código QR de un contacto.';

  @override
  String get invalidNpub => 'Llave pública inválida. Por favor, inténtalo de nuevo.';

  @override
  String get you => 'Tú';

  @override
  String get timestampNow => 'Ahora';

  @override
  String timestampMinutes(int count) {
    return '${count}m';
  }

  @override
  String timestampHours(int count) {
    return '${count}h';
  }

  @override
  String get timestampYesterday => 'Ayer';

  @override
  String get weekdayMonday => 'Lunes';

  @override
  String get weekdayTuesday => 'Martes';

  @override
  String get weekdayWednesday => 'Miércoles';

  @override
  String get weekdayThursday => 'Jueves';

  @override
  String get weekdayFriday => 'Viernes';

  @override
  String get weekdaySaturday => 'Sábado';

  @override
  String get weekdaySunday => 'Domingo';

  @override
  String get monthJanShort => 'Ene';

  @override
  String get monthFebShort => 'Feb';

  @override
  String get monthMarShort => 'Mar';

  @override
  String get monthAprShort => 'Abr';

  @override
  String get monthMayShort => 'May';

  @override
  String get monthJunShort => 'Jun';

  @override
  String get monthJulShort => 'Jul';

  @override
  String get monthAugShort => 'Ago';

  @override
  String get monthSepShort => 'Sep';

  @override
  String get monthOctShort => 'Oct';

  @override
  String get monthNovShort => 'Nov';

  @override
  String get monthDecShort => 'Dic';

  @override
  String get loginWithAmber => 'Iniciar sesión con Amber';

  @override
  String get signerConnectionError =>
      'No se pudo conectar al signer. Por favor, inténtalo de nuevo.';

  @override
  String get search => 'Buscar';

  @override
  String get filterChats => 'Chats';

  @override
  String get filterArchive => 'Archivados';

  @override
  String get signerErrorUserRejected => 'Inicio de sesión cancelado';

  @override
  String get signerErrorNotConnected => 'No conectado al signer. Por favor, inténtalo de nuevo.';

  @override
  String get signerErrorNoSigner =>
      'No se encontró ninguna app de signer. Instala un signer compatible con NIP-55.';

  @override
  String get signerErrorNoResponse => 'El signer no respondió. Por favor, inténtalo de nuevo.';

  @override
  String get signerErrorNoPubkey => 'No se pudo obtener la llave pública del signer.';

  @override
  String get signerErrorNoResult => 'El signer no devolvió un resultado.';

  @override
  String get signerErrorNoEvent => 'El signer no devolvió un evento firmado.';

  @override
  String get signerErrorRequestInProgress => 'Hay otra solicitud en curso. Por favor, espera.';

  @override
  String get signerErrorNoActivity => 'No se pudo abrir el signer. Por favor, inténtalo de nuevo.';

  @override
  String get signerErrorLaunchError => 'Error al abrir la app del signer.';

  @override
  String get signerErrorUnknown => 'Ocurrió un error con el signer. Por favor, inténtalo de nuevo.';

  @override
  String get messageNotFound => 'Mensaje no encontrado';

  @override
  String get pin => 'Fijar';

  @override
  String get unpin => 'Desfijar';

  @override
  String get mute => 'Silenciar';

  @override
  String get archive => 'Archivar';

  @override
  String get failedToPinChat => 'Error al fijar. Por favor, inténtalo de nuevo.';

  @override
  String get carouselPrivacyTitle => 'Privacidad y seguridad';

  @override
  String get carouselPrivacyDescription =>
      'Mantén tus conversaciones privadas. Incluso en caso de una brecha, tus mensajes permanecen seguros.';

  @override
  String get carouselIdentityTitle => 'Elige tu identidad';

  @override
  String get carouselIdentityDescription =>
      'Chatea sin revelar tu número de teléfono o correo electrónico. Elige tu identidad: nombre real, seudónimo o anónimo.';

  @override
  String get carouselDecentralizedTitle => 'Descentralizado y sin permisos';

  @override
  String get carouselDecentralizedDescription =>
      'Ninguna autoridad central controla tu comunicación, sin permisos necesarios, sin censura posible.';

  @override
  String get learnMore => 'Más información';

  @override
  String get backToSignUp => 'Volver al registro';

  @override
  String get deleteAllData => 'Eliminar Todos los Datos';

  @override
  String get deleteAllDataConfirmation => '¿Eliminar todos los datos?';

  @override
  String get deleteAllDataWarning =>
      'Esto eliminará permanentemente todos tus chats, mensajes y configuraciones de este dispositivo. Esta acción no se puede deshacer.';

  @override
  String get deleteAllDataError =>
      'No se pudieron eliminar todos los datos. Por favor, inténtalo de nuevo.';

  @override
  String get chatInformation => 'Información del chat';

  @override
  String get addAsContact => 'Añadir como contacto';

  @override
  String get removeAsContact => 'Eliminar como contacto';

  @override
  String get addToGroup => 'Añadir al grupo';

  @override
  String get addToAnotherGroup => 'Añadir a otro grupo';

  @override
  String get relayResolutionTitle => 'Configuración de relé';

  @override
  String get relayResolutionDescription =>
      'No pudimos encontrar tus listas de relés en la red. Puedes proporcionar un relé donde estén publicadas tus listas o usar nuestros relés predeterminados para comenzar.';

  @override
  String get relayResolutionUseDefaults => 'Usar relés predeterminados';

  @override
  String get relayResolutionTryRelay => 'Buscar relé';

  @override
  String get relayResolutionRelayPlaceholder => 'wss://rele.ejemplo.com';

  @override
  String get relayResolutionRelayLabel => 'URL del relé';

  @override
  String get relayResolutionNotFound =>
      'No se encontraron listas de relés en este relé. Prueba con otro o usa los predeterminados.';

  @override
  String get loginErrorInvalidKey => 'Nsec inválida. Asegúrate de haberla ingresado correctamente.';

  @override
  String get loginErrorNoRelayConnections =>
      'No se pudo conectar a ningún relé. Verifica tu conexión e inténtalo de nuevo.';

  @override
  String get loginErrorTimeout => 'La conexión ha expirado. Inténtalo de nuevo.';

  @override
  String get loginErrorGeneric =>
      'Se produjo un error durante el inicio de sesión. Inténtalo de nuevo.';

  @override
  String get loginErrorNoLoginInProgress =>
      'No hay inicio de sesión en curso. Por favor, empieza de nuevo.';

  @override
  String get loginErrorInternal => 'Se produjo un error interno. Inténtalo de nuevo.';

  @override
  String get loginPasteNothingToPaste => 'Nada que pegar';

  @override
  String get loginPasteFailed => 'Error al pegar desde el portapapeles';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get scannerError => 'Error del escáner';

  @override
  String get scannerErrorDescription =>
      'Algo salió mal con el escáner. Por favor, inténtalo de nuevo.';

  @override
  String get cameraPermissionDeniedDescription =>
      'Por favor, habilita el acceso a la cámara en los ajustes de tu dispositivo para escanear códigos QR.';

  @override
  String get retry => 'Reintentar';

  @override
  String get groupInformation => 'Información del grupo';

  @override
  String get editGroup => 'Editar grupo';

  @override
  String get editGroupAction => 'Editar grupo';

  @override
  String get groupNameLabel => 'Nombre';

  @override
  String get groupDescriptionLabel => 'Acerca de';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Miembros',
      one: '1 Miembro',
    );
    return '$_temp0';
  }

  @override
  String get adminBadge => 'Admin';

  @override
  String get membersLabel => 'Miembros:';

  @override
  String get memberBadge => 'Miembro';

  @override
  String get sendMessage => 'Enviar mensaje';

  @override
  String get makeAdmin => 'Hacer admin';

  @override
  String get removeAdminRole => 'Quitar admin';

  @override
  String get removeFromGroup => 'Eliminar del grupo';

  @override
  String get removeFromGroupConfirmation => '¿Eliminar del grupo?';

  @override
  String get removeFromGroupWarning =>
      'Este miembro será eliminado del grupo y ya no podrá ver los nuevos mensajes.';

  @override
  String get makeAdminConfirmation => '¿Hacer admin?';

  @override
  String get makeAdminWarning =>
      'Este miembro podrá gestionar el grupo, añadir o eliminar miembros y cambiar la configuración del grupo.';

  @override
  String get removeAdminConfirmation => '¿Quitar admin?';

  @override
  String get removeAdminWarning =>
      'Este miembro ya no podrá gestionar el grupo, añadir o eliminar miembros ni cambiar la configuración del grupo.';

  @override
  String get failedToRemoveFromGroup => 'No se pudo eliminar al miembro. Inténtalo de nuevo.';

  @override
  String get failedToMakeAdmin => 'No se pudo hacer admin. Inténtalo de nuevo.';

  @override
  String get failedToRemoveAdmin => 'No se pudo quitar admin. Inténtalo de nuevo.';

  @override
  String get groupUpdatedSuccessfully => 'Grupo actualizado correctamente';

  @override
  String get groupLoadError => 'No se pudo cargar el grupo. Inténtalo de nuevo.';

  @override
  String get groupSaveError => 'No se pudo guardar el grupo. Inténtalo de nuevo.';

  @override
  String get failedToFetchGroupMembers =>
      'No se pudieron cargar los miembros del grupo. Inténtalo de nuevo.';

  @override
  String get failedToAddMembers => 'No se pudieron añadir miembros. Inténtalo de nuevo.';

  @override
  String get groupImageUploadFailed => 'Grupo creado, pero la imagen no se pudo subir.';

  @override
  String updateNeeded(String name) {
    return '$name necesita actualizar';
  }

  @override
  String updateNeededDescription(String name) {
    return 'Aún no puedes iniciar un chat seguro con $name. Necesita actualizar White Noise antes de que funcione la mensajería segura.';
  }

  @override
  String addToGroupConfirmation(String userName, String groupName) {
    return '¿Añadir a $userName a $groupName?';
  }

  @override
  String get unknownInviteToWhiteNoiseDescription =>
      'Este usuario aún no está en White Noise. Comparte la app para iniciar un chat seguro.';

  @override
  String get unknownUserNeedsUpdate => 'El usuario necesita actualizar';

  @override
  String get unknownUserNeedsUpdateDescription =>
      'Aún no puedes iniciar un chat seguro con este usuario. Necesita actualizar White Noise antes de que funcione la mensajería segura.';

  @override
  String get add => 'Añadir';

  @override
  String get noGroupsAvailable => 'No hay grupos disponibles';

  @override
  String get noAdminGroupsAvailable =>
      'Aún no eres admin en ningún grupo. Crea un grupo para añadir personas.';

  @override
  String get profilesTitle => 'Perfiles';

  @override
  String get noAccountsAvailable => 'No hay cuentas disponibles';

  @override
  String get connectAnotherProfile => 'Conectar otro perfil';

  @override
  String get rawDebugView => 'Vista de depuración sin procesar';

  @override
  String get rawDebugViewDescription => 'Mostrar datos de mensajes sin procesar en el chat';

  @override
  String get rawDebugViewTitle => 'Vista de Depuración Sin Procesar';

  @override
  String get rawDebugViewGroupId => 'ID del Grupo';

  @override
  String rawDebugViewMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes',
      one: '1 mensaje',
    );
    return '$_temp0';
  }

  @override
  String get rawDebugViewCopied => 'Copiado al portapapeles';

  @override
  String get appLogsTitle => 'Registros de la aplicación';

  @override
  String get appLogsViewLogs => 'Ver registros';

  @override
  String get appLogsViewLogsDescription => 'Ver todas las salidas del Logger en la aplicación';

  @override
  String get appLogsClear => 'Borrar';

  @override
  String get appLogsEmpty => 'Aún no hay registros';

  @override
  String get appLogsSearchPlaceholder => 'Buscar registros...';

  @override
  String get appLogsAddPatternPlaceholder => 'Añadir filtro';

  @override
  String get appLogsIgnore => 'Ignorar';

  @override
  String get appLogsShow => 'Mostrar';

  @override
  String get appLogsClearFilters => 'Borrar filtros';

  @override
  String get appLogsLive => 'En vivo';

  @override
  String appLogsFilteredCount(int shown, int total) {
    return '$shown de $total';
  }

  @override
  String get invalidRelayUrlScheme => 'La URL debe comenzar con wss:// o ws://';

  @override
  String get invalidRelayUrl => 'URL de relé inválida';

  @override
  String get thisMessageWasDeleted => 'Este mensaje fue eliminado.';
}
