// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

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
  String get sloganUncensorable => 'Incensurável';

  @override
  String get sloganSecureMessaging => 'Mensagens Seguras';

  @override
  String get login => 'Entrar';

  @override
  String get signUp => 'Cadastrar';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get enterPrivateKey => 'Digite sua chave privada';

  @override
  String get nsecPlaceholder => 'nsec...';

  @override
  String get setupProfile => 'Configurar perfil';

  @override
  String get chooseName => 'Escolha um nome';

  @override
  String get enterYourName => 'Digite seu nome';

  @override
  String get introduceYourself => 'Apresente-se';

  @override
  String get writeSomethingAboutYourself => 'Escreva algo sobre você';

  @override
  String get cancel => 'Cancelar';

  @override
  String get profileReady => 'Seu perfil está pronto!';

  @override
  String get startConversationHint =>
      'Inicie uma conversa adicionando amigos ou compartilhando seu perfil.';

  @override
  String get share => 'Compartilhar';

  @override
  String get shareYourProfile => 'Compartilhar seu perfil';

  @override
  String get startChat => 'Iniciar conversa';

  @override
  String get settings => 'Configurações';

  @override
  String get shareAndConnect => 'Compartilhar e conectar';

  @override
  String get switchProfile => 'Trocar perfil';

  @override
  String get addNewProfile => 'Adicionar um novo perfil';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get profileKeys => 'Chaves do perfil';

  @override
  String get networkRelays => 'Relays de rede';

  @override
  String get appearance => 'Aparência';

  @override
  String get privacySecurity => 'Privacidade e segurança';

  @override
  String get donateToWhiteNoise => 'Doar para o White Noise';

  @override
  String get developerSettings => 'Configurações de desenvolvedor';

  @override
  String get signOut => 'Sair';

  @override
  String get appearanceTitle => 'Aparência';

  @override
  String get privacySecurityTitle => 'Privacidade e segurança';

  @override
  String get deleteAllAppData => 'Excluir Todos os Dados do App';

  @override
  String get deleteAppData => 'Excluir dados do app';

  @override
  String get deleteAllAppDataDescription =>
      'Apagar todos os perfis, chaves, chats e arquivos locais deste dispositivo.';

  @override
  String get deleteAllAppDataConfirmation => 'Excluir todos os dados do app?';

  @override
  String get deleteAllAppDataWarning =>
      'Isso apagará todos os perfis, chaves, chats e arquivos locais deste dispositivo. Esta ação não pode ser desfeita.';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get profileKeysTitle => 'Chaves do perfil';

  @override
  String get publicKey => 'Chave pública';

  @override
  String get publicKeyCopied => 'Chave pública copiada para a área de transferência';

  @override
  String get publicKeyDescription =>
      'Sua chave pública (npub) pode ser compartilhada com outros. Ela é usada para identificá-lo na rede.';

  @override
  String get privateKey => 'Chave privada';

  @override
  String get privateKeyCopied => 'Chave privada copiada para a área de transferência';

  @override
  String get privateKeyDescription =>
      'Sua chave privada (nsec) deve ser mantida em segredo. Qualquer pessoa com acesso a ela pode controlar sua conta.';

  @override
  String get keepPrivateKeySecure => 'Mantenha sua chave privada segura';

  @override
  String get privateKeyWarning =>
      'Não compartilhe sua chave privada publicamente e use-a apenas para entrar em outros apps Nostr.';

  @override
  String get nsecOnExternalSigner => 'A chave privada está armazenada em um assinador externo';

  @override
  String get nsecOnExternalSignerDescription =>
      'Sua chave privada não está disponível no White Noise. Abra seu assinador para visualizá-la ou gerenciá-la.';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get profileName => 'Nome do perfil';

  @override
  String get nostrAddress => 'Endereço Nostr';

  @override
  String get nostrAddressPlaceholder => 'exemplo@whitenoise.chat';

  @override
  String get aboutYou => 'Sobre você';

  @override
  String get profileIsPublic => 'O perfil é público';

  @override
  String get profilePublicDescription =>
      'As informações do seu perfil serão visíveis para todos na rede.';

  @override
  String get discard => 'Descartar';

  @override
  String get discardChanges => 'Descartar alterações';

  @override
  String get save => 'Salvar';

  @override
  String get profileUpdatedSuccessfully => 'Perfil atualizado com sucesso';

  @override
  String errorLoadingProfile(String error) {
    return 'Erro ao carregar o perfil: $error';
  }

  @override
  String error(String error) {
    return 'Erro: $error';
  }

  @override
  String get profileLoadError => 'Não foi possível carregar o perfil. Por favor, tente novamente.';

  @override
  String get failedToLoadPrivateKey =>
      'Não foi possível carregar a chave privada. Por favor, tente novamente.';

  @override
  String get profileSaveError => 'Não foi possível salvar o perfil. Por favor, tente novamente.';

  @override
  String get networkRelaysTitle => 'Relays de Rede';

  @override
  String get myRelays => 'Meus Relays';

  @override
  String get myRelaysHelp => 'Relays que você definiu para uso em todas as suas aplicações Nostr.';

  @override
  String get inboxRelays => 'Relays de Caixa de Entrada';

  @override
  String get inboxRelaysHelp =>
      'Relays usados para receber convites e iniciar conversas seguras com novos usuários.';

  @override
  String get keyPackageRelays => 'Relays de Pacote de Chaves';

  @override
  String get keyPackageRelaysHelp =>
      'Relays que armazenam sua chave segura para que outros possam convidá-lo para conversas criptografadas.';

  @override
  String get errorLoadingRelays => 'Erro ao carregar os relays';

  @override
  String get noRelaysConfigured => 'Nenhum relay configurado';

  @override
  String get donateTitle => 'Doar para o White Noise';

  @override
  String get donateDescription =>
      'Como uma organização sem fins lucrativos, o White Noise existe apenas para sua privacidade e liberdade, não para lucro. Seu apoio nos mantém independentes e sem compromissos.';

  @override
  String get lightningAddress => 'Endereço Lightning';

  @override
  String get bitcoinSilentPayment => 'Pagamento Silencioso Bitcoin';

  @override
  String get copiedToClipboardThankYou => 'Copiado para a área de transferência. Obrigado!';

  @override
  String get shareProfileTitle => 'Compartilhar perfil';

  @override
  String get scanToConnect => 'Escaneie para conectar';

  @override
  String get signOutTitle => 'Sair';

  @override
  String get signOutConfirmation => 'Tem certeza de que deseja sair?';

  @override
  String get signOutWarning =>
      'Quando você sair do White Noise, suas conversas serão excluídas deste dispositivo e não poderão ser restauradas em outro dispositivo.';

  @override
  String get signOutWarningBackupKey =>
      'Se você não fez backup da sua chave privada, não poderá usar este perfil em nenhum outro serviço Nostr.';

  @override
  String get backUpPrivateKey => 'Faça backup da sua chave privada';

  @override
  String get copyPrivateKeyHint =>
      'Copie sua chave privada para restaurar sua conta em outro dispositivo.';

  @override
  String get publicKeyCopyError => 'Falha ao copiar a chave pública. Por favor, tente novamente.';

  @override
  String get noChatsYet => 'Ainda não há conversas';

  @override
  String get startConversation => 'Inicie uma conversa';

  @override
  String get welcomeNoticeTitle => 'Seu perfil está pronto';

  @override
  String welcomeNoticeDescription(String findPeople, String shareProfile, String startANewChat) {
    return 'Toque em $findPeople para encontrar seus amigos. $shareProfile para se conectar com pessoas que você conhece, ou $startANewChat usando o ícone de chat.';
  }

  @override
  String get findPeople => 'Encontrar pessoas';

  @override
  String get startANewChat => 'inicie uma nova conversa';

  @override
  String get noMessagesYet => 'Ainda não há mensagens';

  @override
  String get messagePlaceholder => 'Mensagem';

  @override
  String get failedToSendMessage => 'Falha ao enviar mensagem. Por favor, tente novamente.';

  @override
  String get invitedToSecureChat => 'Você foi convidado para uma conversa segura';

  @override
  String get invitedYouToChatSuffix => ' convidou você para o chat';

  @override
  String get decline => 'Recusar';

  @override
  String get accept => 'Aceitar';

  @override
  String failedToAcceptInvitation(String error) {
    return 'Falha ao aceitar o convite: $error';
  }

  @override
  String failedToDeclineInvitation(String error) {
    return 'Falha ao recusar o convite: $error';
  }

  @override
  String get startNewChat => 'Nova conversa';

  @override
  String get noResults => 'Sem resultados';

  @override
  String get noFollowsYet => 'Ainda não há seguidos';

  @override
  String get searchByNameOrNpub => 'Nome ou npub1...';

  @override
  String get developerSettingsTitle => 'Configurações de Desenvolvedor';

  @override
  String get publishNewKeyPackage => 'Publicar Novo Pacote de Chaves';

  @override
  String get refreshKeyPackages => 'Atualizar Pacotes de Chaves';

  @override
  String get deleteAllKeyPackages => 'Excluir Todos os Pacotes de Chaves';

  @override
  String keyPackagesCount(int count) {
    return 'Pacotes de Chaves ($count)';
  }

  @override
  String get noKeyPackagesFound => 'Nenhum pacote de chaves encontrado';

  @override
  String get keyPackagePublished => 'Pacote de chaves publicado';

  @override
  String get keyPackagesRefreshed => 'Pacotes de chaves atualizados';

  @override
  String get keyPackagesDeleted => 'Todos os pacotes de chaves excluídos';

  @override
  String get keyPackageDeleted => 'Pacote de chaves excluído';

  @override
  String packageNumber(int number) {
    return 'Pacote $number';
  }

  @override
  String get goBack => 'Voltar';

  @override
  String get createGroup => 'Criar grupo';

  @override
  String get newGroupChat => 'Novo chat em grupo';

  @override
  String get selectMembers => 'Selecionar Membros';

  @override
  String selectedCount(int count) {
    return '$count selecionados';
  }

  @override
  String get clearSelection => 'Limpar';

  @override
  String get continueButton => 'Continuar';

  @override
  String get setUpGroup => 'Configurar grupo';

  @override
  String get groupName => 'Nome do Grupo';

  @override
  String get groupNamePlaceholder => 'Digite o nome do grupo';

  @override
  String get groupDescription => 'Descrição do Grupo';

  @override
  String get description => 'Descrição';

  @override
  String get groupDescriptionPlaceholder => 'Para que é este grupo?';

  @override
  String members(int count) {
    return '$count membros';
  }

  @override
  String invitingMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Convidando membros:',
      one: 'Convidando membro:',
    );
    return '$_temp0';
  }

  @override
  String get usersWithoutKeyPackages =>
      'Usuários sem pacotes de chaves (não podem ser adicionados)';

  @override
  String usersNotOnWhiteNoise(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Estes usuários não estão no White Noise',
      one: 'Este usuário não está no White Noise',
    );
    return '$_temp0';
  }

  @override
  String usersNotOnWhiteNoiseDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Estes usuários não podem ser adicionados ao grupo porque não têm o White Noise instalado ou ainda não publicaram seus pacotes de chaves.',
      one:
          'Este usuário não pode ser adicionado ao grupo porque não tem o White Noise instalado ou ainda não publicou seu pacote de chaves.',
    );
    return '$_temp0';
  }

  @override
  String get uploadingImage => 'Enviando imagem...';

  @override
  String get creatingGroup => 'Criando grupo...';

  @override
  String get groupNameRequired => 'O nome do grupo é obrigatório';

  @override
  String get noUsersWithKeyPackages => 'Nenhum usuário com pacotes de chaves para adicionar';

  @override
  String get createGroupFailed => 'Falha ao criar grupo';

  @override
  String get reportError => 'Reportar erro';

  @override
  String get wipMessage =>
      'Estamos trabalhando nesta funcionalidade. Para apoiar o desenvolvimento, doe ao White Noise';

  @override
  String get donate => 'Doar';

  @override
  String get addRelay => 'Adicionar Relay';

  @override
  String get enterRelayAddress => 'Digite o endereço do relay';

  @override
  String get relayAddressPlaceholder => 'wss://relay.example.com';

  @override
  String get removeRelay => 'Remover Relay?';

  @override
  String get removeRelayConfirmation =>
      'Tem certeza de que deseja remover este relay? Esta ação não pode ser desfeita.';

  @override
  String get remove => 'Remover';

  @override
  String get messageActions => 'Ações da mensagem';

  @override
  String get reply => 'Responder';

  @override
  String get copyMessage => 'Copiar';

  @override
  String get delete => 'Excluir';

  @override
  String get failedToDeleteMessage => 'Falha ao excluir mensagem. Por favor, tente novamente.';

  @override
  String get failedToSendReaction => 'Falha ao enviar reação. Por favor, tente novamente.';

  @override
  String get failedToRemoveReaction => 'Falha ao remover reação. Por favor, tente novamente.';

  @override
  String get unknownUser => 'Usuário desconhecido';

  @override
  String get unknownGroup => 'Grupo desconhecido';

  @override
  String get hasInvitedYouToSecureChat => 'Convidou você para uma conversa segura';

  @override
  String userInvitedYouToSecureChat(String name) {
    return '$name convidou você para uma conversa segura';
  }

  @override
  String get youHaveBeenInvitedToSecureChat => 'Você foi convidado para uma conversa segura';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageUpdateFailed =>
      'Falha ao salvar preferência de idioma. Por favor, tente novamente.';

  @override
  String get timeJustNow => 'agora mesmo';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count minutos',
      one: 'há 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count horas',
      one: 'há 1 hora',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count dias',
      one: 'ontem',
    );
    return '$_temp0';
  }

  @override
  String get profile => 'Perfil';

  @override
  String get follow => 'Seguir';

  @override
  String get unfollow => 'Deixar de seguir';

  @override
  String chatSearchMatchCount(int current, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total resultados',
      one: '1 resultado',
    );
    return '$current de $_temp0';
  }

  @override
  String get failedToStartChat => 'Falha ao iniciar a conversa. Por favor, tente novamente.';

  @override
  String get inviteToWhiteNoise => 'Convidar para o White Noise';

  @override
  String inviteToWhiteNoiseDescription(String name) {
    return '$name ainda não está no White Noise. Compartilhe o app para iniciar uma conversa segura.';
  }

  @override
  String get inviteMessage =>
      'Junte-se a mim no White Noise. Sem número de telefone. Sem vigilância. Apenas privacidade real. Baixe aqui: https://www.whitenoise.chat/download';

  @override
  String get failedToUpdateFollow =>
      'Falha ao atualizar o status de seguir. Por favor, tente novamente.';

  @override
  String get imagePickerError => 'Falha ao selecionar imagem. Por favor, tente novamente.';

  @override
  String get scanNsec => 'Escanear código QR';

  @override
  String get scanNsecHint => 'Escaneie o código QR da sua chave privada para fazer login.';

  @override
  String get cameraPermissionDenied => 'Permissão de câmera negada';

  @override
  String get somethingWentWrong => 'Algo deu errado';

  @override
  String get scanNpub => 'Escanear código QR';

  @override
  String get scanNpubHint => 'Escaneie o código QR de um contato.';

  @override
  String get invalidNpub => 'Chave pública inválida. Por favor, tente novamente.';

  @override
  String get you => 'Você';

  @override
  String get timestampNow => 'Agora';

  @override
  String timestampMinutes(int count) {
    return '${count}m';
  }

  @override
  String timestampHours(int count) {
    return '${count}h';
  }

  @override
  String get timestampYesterday => 'Ontem';

  @override
  String get weekdayMonday => 'Segunda';

  @override
  String get weekdayTuesday => 'Terça';

  @override
  String get weekdayWednesday => 'Quarta';

  @override
  String get weekdayThursday => 'Quinta';

  @override
  String get weekdayFriday => 'Sexta';

  @override
  String get weekdaySaturday => 'Sábado';

  @override
  String get weekdaySunday => 'Domingo';

  @override
  String get monthJanShort => 'Jan';

  @override
  String get monthFebShort => 'Fev';

  @override
  String get monthMarShort => 'Mar';

  @override
  String get monthAprShort => 'Abr';

  @override
  String get monthMayShort => 'Mai';

  @override
  String get monthJunShort => 'Jun';

  @override
  String get monthJulShort => 'Jul';

  @override
  String get monthAugShort => 'Ago';

  @override
  String get monthSepShort => 'Set';

  @override
  String get monthOctShort => 'Out';

  @override
  String get monthNovShort => 'Nov';

  @override
  String get monthDecShort => 'Dez';

  @override
  String get loginWithAmber => 'Entrar com Amber';

  @override
  String get signerConnectionError =>
      'Não foi possível conectar ao signer. Por favor, tente novamente.';

  @override
  String get search => 'Pesquisar';

  @override
  String get filterChats => 'Conversas';

  @override
  String get filterArchive => 'Arquivo';

  @override
  String get signerErrorUserRejected => 'Login cancelado';

  @override
  String get signerErrorNotConnected => 'Não conectado ao signer. Por favor, tente novamente.';

  @override
  String get signerErrorNoSigner =>
      'Nenhum app de signer encontrado. Instale um signer compatível com NIP-55.';

  @override
  String get signerErrorNoResponse => 'Sem resposta do signer. Por favor, tente novamente.';

  @override
  String get signerErrorNoPubkey => 'Não foi possível obter a chave pública do signer.';

  @override
  String get signerErrorNoResult => 'O signer não retornou um resultado.';

  @override
  String get signerErrorNoEvent => 'O signer não retornou um evento assinado.';

  @override
  String get signerErrorRequestInProgress => 'Outra solicitação em andamento. Por favor, aguarde.';

  @override
  String get signerErrorNoActivity =>
      'Não foi possível iniciar o signer. Por favor, tente novamente.';

  @override
  String get signerErrorLaunchError => 'Falha ao iniciar o app do signer.';

  @override
  String get signerErrorUnknown => 'Ocorreu um erro com o signer. Por favor, tente novamente.';

  @override
  String get messageNotFound => 'Mensagem não encontrada';

  @override
  String get pin => 'Fixar';

  @override
  String get unpin => 'Desafixar';

  @override
  String get mute => 'Silenciar';

  @override
  String get archive => 'Arquivar';

  @override
  String get failedToPinChat => 'Erro ao fixar. Por favor, tente novamente.';

  @override
  String get carouselPrivacyTitle => 'Privacidade e segurança';

  @override
  String get carouselPrivacyDescription =>
      'Mantenha suas conversas privadas. Mesmo em caso de violação, suas mensagens permanecem seguras.';

  @override
  String get carouselIdentityTitle => 'Escolha sua identidade';

  @override
  String get carouselIdentityDescription =>
      'Converse sem revelar seu número de telefone ou email. Escolha sua identidade: nome real, pseudônimo ou anônimo.';

  @override
  String get carouselDecentralizedTitle => 'Descentralizado e sem permissões';

  @override
  String get carouselDecentralizedDescription =>
      'Nenhuma autoridade central controla sua comunicação – sem permissões necessárias, sem censura possível.';

  @override
  String get learnMore => 'Saiba mais';

  @override
  String get backToSignUp => 'Voltar ao cadastro';

  @override
  String get deleteAllData => 'Excluir Todos os Dados';

  @override
  String get deleteAllDataConfirmation => 'Excluir todos os dados?';

  @override
  String get deleteAllDataWarning =>
      'Isso excluirá permanentemente todos os seus chats, mensagens e configurações deste dispositivo. Esta ação não pode ser desfeita.';

  @override
  String get deleteAllDataError => 'Falha ao excluir todos os dados. Por favor, tente novamente.';

  @override
  String get chatInformation => 'Informações do chat';

  @override
  String get addAsContact => 'Adicionar como contato';

  @override
  String get removeAsContact => 'Remover como contato';

  @override
  String get addToGroup => 'Adicionar ao grupo';

  @override
  String get addToAnotherGroup => 'Adicionar a outro grupo';

  @override
  String get relayResolutionTitle => 'Configuração de relay';

  @override
  String get relayResolutionDescription =>
      'Não conseguimos encontrar as suas listas de relays na rede. Pode fornecer um relay onde as suas listas estejam publicadas ou utilizar os nossos relays predefinidos para começar.';

  @override
  String get relayResolutionUseDefaults => 'Usar relays predefinidos';

  @override
  String get relayResolutionTryRelay => 'Pesquisar relay';

  @override
  String get relayResolutionRelayPlaceholder => 'wss://relay.example.com';

  @override
  String get relayResolutionRelayLabel => 'URL do relay';

  @override
  String get relayResolutionNotFound =>
      'Nenhuma lista de relays encontrada neste relay. Tente outro ou use os predefinidos.';

  @override
  String get loginErrorInvalidKey =>
      'Formato de chave privada inválido. Verifique e tente novamente.';

  @override
  String get loginErrorNoRelayConnections =>
      'Não foi possível conectar a nenhum relay. Verifique a sua conexão e tente novamente.';

  @override
  String get loginErrorTimeout => 'Tempo de login esgotado. Tente novamente.';

  @override
  String get loginErrorGeneric => 'Ocorreu um erro durante o login. Tente novamente.';

  @override
  String get loginErrorNoLoginInProgress =>
      'Nenhum login em andamento. Por favor, comece novamente.';

  @override
  String get loginErrorInternal => 'Ocorreu um erro interno. Tente novamente.';

  @override
  String get loginPasteNothingToPaste => 'Nada para colar';

  @override
  String get loginPasteFailed => 'Falha ao colar da área de transferência';

  @override
  String get openSettings => 'Abrir configurações';

  @override
  String get scannerError => 'Erro do scanner';

  @override
  String get scannerErrorDescription =>
      'Algo deu errado com o scanner. Por favor, tente novamente.';

  @override
  String get cameraPermissionDeniedDescription =>
      'Por favor, habilite o acesso à câmera nas configurações do seu dispositivo para escanear códigos QR.';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get groupInformation => 'Informações do grupo';

  @override
  String get editGroup => 'Editar grupo';

  @override
  String get editGroupAction => 'Editar grupo';

  @override
  String get groupNameLabel => 'Nome';

  @override
  String get groupDescriptionLabel => 'Sobre';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Membros',
      one: '1 Membro',
    );
    return '$_temp0';
  }

  @override
  String get adminBadge => 'Admin';

  @override
  String get membersLabel => 'Membros:';

  @override
  String get memberBadge => 'Membro';

  @override
  String get sendMessage => 'Enviar mensagem';

  @override
  String get makeAdmin => 'Tornar admin';

  @override
  String get removeAdminRole => 'Remover admin';

  @override
  String get removeFromGroup => 'Remover do grupo';

  @override
  String get removeFromGroupConfirmation => 'Remover do grupo?';

  @override
  String get removeFromGroupWarning =>
      'Este membro será removido do grupo e não poderá mais ver novas mensagens.';

  @override
  String get makeAdminConfirmation => 'Tornar admin?';

  @override
  String get makeAdminWarning =>
      'Este membro poderá gerenciar o grupo, adicionar ou remover membros e alterar as configurações do grupo.';

  @override
  String get removeAdminConfirmation => 'Remover admin?';

  @override
  String get removeAdminWarning =>
      'Este membro não poderá mais gerenciar o grupo, adicionar ou remover membros nem alterar as configurações do grupo.';

  @override
  String get failedToRemoveFromGroup => 'Não foi possível remover o membro. Tente novamente.';

  @override
  String get failedToMakeAdmin => 'Não foi possível tornar admin. Tente novamente.';

  @override
  String get failedToRemoveAdmin => 'Não foi possível remover admin. Tente novamente.';

  @override
  String get groupUpdatedSuccessfully => 'Grupo atualizado com sucesso';

  @override
  String get groupLoadError => 'Não foi possível carregar o grupo. Tente novamente.';

  @override
  String get groupSaveError => 'Não foi possível salvar o grupo. Tente novamente.';

  @override
  String get failedToFetchGroupMembers =>
      'Não foi possível carregar os membros do grupo. Tente novamente.';

  @override
  String get failedToAddMembers => 'Não foi possível adicionar membros. Tente novamente.';

  @override
  String get groupImageUploadFailed => 'Grupo criado, mas a imagem falhou ao enviar.';

  @override
  String updateNeeded(String name) {
    return '$name precisa atualizar';
  }

  @override
  String updateNeededDescription(String name) {
    return 'Você ainda não pode iniciar uma conversa segura com $name. A pessoa precisa atualizar o White Noise antes que as mensagens seguras funcionem.';
  }

  @override
  String addToGroupConfirmation(String userName, String groupName) {
    return 'Adicionar $userName a $groupName?';
  }

  @override
  String get unknownInviteToWhiteNoiseDescription =>
      'Este usuário ainda não está no White Noise. Compartilhe o app para iniciar uma conversa segura.';

  @override
  String get unknownUserNeedsUpdate => 'Usuário precisa atualizar';

  @override
  String get unknownUserNeedsUpdateDescription =>
      'Você ainda não pode iniciar uma conversa segura com este usuário. A pessoa precisa atualizar o White Noise antes que as mensagens seguras funcionem.';

  @override
  String get add => 'Adicionar';

  @override
  String get noGroupsAvailable => 'Nenhum grupo disponível';

  @override
  String get noAdminGroupsAvailable =>
      'Você ainda não é admin em nenhum grupo. Crie um grupo para adicionar pessoas.';

  @override
  String get profilesTitle => 'Perfis';

  @override
  String get noAccountsAvailable => 'Nenhuma conta disponível';

  @override
  String get connectAnotherProfile => 'Conectar outro perfil';

  @override
  String get rawDebugView => 'Vista de depuração bruta';

  @override
  String get rawDebugViewDescription => 'Mostrar dados brutos das mensagens no chat';

  @override
  String get rawDebugViewTitle => 'Vista de Depuração Bruta';

  @override
  String get rawDebugViewGroupId => 'ID do Grupo';

  @override
  String rawDebugViewMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens',
      one: '1 mensagem',
    );
    return '$_temp0';
  }

  @override
  String get rawDebugViewCopied => 'Copiado para a área de transferência';

  @override
  String get appLogsTitle => 'Registros do App';

  @override
  String get appLogsViewLogs => 'Ver registros';

  @override
  String get appLogsViewLogsDescription => 'Ver todas as saídas do Logger no app';

  @override
  String get appLogsClear => 'Limpar';

  @override
  String get appLogsEmpty => 'Nenhum registro ainda';

  @override
  String get appLogsSearchPlaceholder => 'Pesquisar registros...';

  @override
  String get appLogsAddPatternPlaceholder => 'Adicionar filtro';

  @override
  String get appLogsIgnore => 'Ignorar';

  @override
  String get appLogsShow => 'Mostrar';

  @override
  String get appLogsClearFilters => 'Limpar filtros';

  @override
  String appLogsFilteredCount(int shown, int total) {
    return '$shown de $total';
  }

  @override
  String get invalidRelayUrlScheme => 'O URL deve começar com wss:// ou ws://';

  @override
  String get invalidRelayUrl => 'URL de relay inválida';
}
