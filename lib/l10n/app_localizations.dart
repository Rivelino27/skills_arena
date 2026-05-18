import 'package:flutter/material.dart';

/// Hand-rolled localizations — no codegen dependency. To add a new
/// string:
///   1. Add it to each of `_pt / _en / _es / _zh / _fr` below.
///   2. Add a getter to the `AppLocalizations` class above.
///   3. Use it in a widget: `AppLocalizations.of(context).myKey`.
///
/// Strings are plain getters so the Dart analyzer catches typos
/// immediately, instead of failing silently at runtime like a Map.
class AppLocalizations {
  final Locale locale;
  final Map<String, String> _strings;

  AppLocalizations._(this.locale, this._strings);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String _s(String key) => _strings[key] ?? key;

  // ── App / nav ────────────────────────────────────────────────────
  String get appTitle => _s('appTitle');
  String get tabHome => _s('tabHome');
  String get tabExplore => _s('tabExplore');
  String get tabMessages => _s('tabMessages');
  String get tabProfile => _s('tabProfile');

  // ── Login ────────────────────────────────────────────────────────
  String get loginTitle => _s('loginTitle');
  String get loginSubtitle => _s('loginSubtitle');
  String get loginEmail => _s('loginEmail');
  String get loginPassword => _s('loginPassword');
  String get loginButton => _s('loginButton');
  String get loginCreateAccount => _s('loginCreateAccount');
  String get loginWithGoogle => _s('loginWithGoogle');
  String get loginForgotPassword => _s('loginForgotPassword');
  String get loginNoAccount => _s('loginNoAccount');
  String get loginInvalidCredentials => _s('loginInvalidCredentials');

  // ── Register ─────────────────────────────────────────────────────
  String get registerTitle => _s('registerTitle');
  String get registerName => _s('registerName');
  String get registerButton => _s('registerButton');
  String get registerHaveAccount => _s('registerHaveAccount');

  // ── Profile ──────────────────────────────────────────────────────
  String get profileTitle => _s('profileTitle');
  String get profileAccountSection => _s('profileAccountSection');
  String get profileDeveloperSection => _s('profileDeveloperSection');
  String get profileEmail => _s('profileEmail');
  String get profileMyAddress => _s('profileMyAddress');
  String get profileMyAddressSubtitle => _s('profileMyAddressSubtitle');
  String get profileRanking => _s('profileRanking');
  String get profileRankingSubtitle => _s('profileRankingSubtitle');
  String get profileTeams => _s('profileTeams');
  String get profileTeamsSubtitle => _s('profileTeamsSubtitle');
  String get profileSignOut => _s('profileSignOut');
  String get profileSignOutConfirm => _s('profileSignOutConfirm');
  String get profileLanguage => _s('profileLanguage');
  String get profileLanguageSubtitle => _s('profileLanguageSubtitle');
  String get profileSearchableByEmail => _s('profileSearchableByEmail');
  String get profileSearchableByEmailSubtitle =>
      _s('profileSearchableByEmailSubtitle');
  String get profilePremium => _s('profilePremium');
  String get profileFree => _s('profileFree');
  String get profileFollowers => _s('profileFollowers');
  String get profileFollowing => _s('profileFollowing');
  String get profileUpgradeTitle => _s('profileUpgradeTitle');
  String get profileUpgradeBody => _s('profileUpgradeBody');
  String get profileUpgradeButton => _s('profileUpgradeButton');

  // ── Language picker labels ───────────────────────────────────────
  String get languageSystem => _s('languageSystem');
  String get languagePortuguese => _s('languagePortuguese');
  String get languageEnglish => _s('languageEnglish');
  String get languageSpanish => _s('languageSpanish');
  String get languageChinese => _s('languageChinese');
  String get languageFrench => _s('languageFrench');

  // ── Common ───────────────────────────────────────────────────────
  String get commonCancel => _s('commonCancel');
  String get commonSave => _s('commonSave');
  String get commonDelete => _s('commonDelete');
  String get commonConfirm => _s('commonConfirm');
  String get commonOk => _s('commonOk');
  String get commonClose => _s('commonClose');
  String get commonLoading => _s('commonLoading');
  String get commonError => _s('commonError');
  String get commonRetry => _s('commonRetry');
  String get commonSearch => _s('commonSearch');
  String get commonShare => _s('commonShare');
  String get commonEdit => _s('commonEdit');
  String get commonYes => _s('commonYes');
  String get commonNo => _s('commonNo');

  // ── Chat ─────────────────────────────────────────────────────────
  String get chatNewMessage => _s('chatNewMessage');
  String get chatSend => _s('chatSend');
  String get chatShareLocation => _s('chatShareLocation');
  String get chatTapToViewProfile => _s('chatTapToViewProfile');
  String get chatNoConversations => _s('chatNoConversations');
  String get chatStartConversation => _s('chatStartConversation');
  String get chatSayHi => _s('chatSayHi');

  // ── Map / Explore ────────────────────────────────────────────────
  String get mapSearchRadius => _s('mapSearchRadius');
  String get mapGlobalSearch => _s('mapGlobalSearch');
  String get mapGlobalSearchSubtitle => _s('mapGlobalSearchSubtitle');
  String get mapVerifiedOnly => _s('mapVerifiedOnly');
  String get mapVerifiedOnlySubtitle => _s('mapVerifiedOnlySubtitle');
  String get mapMyLocation => _s('mapMyLocation');
  String get mapWantToPlay => _s('mapWantToPlay');
  String get mapWantToPlayHere => _s('mapWantToPlayHere');
  String get mapAddVenue => _s('mapAddVenue');
  String get mapCenter => _s('mapCenter');
  String get mapDetails => _s('mapDetails');
  String get mapNoGps => _s('mapNoGps');

  // ── Home / posts ─────────────────────────────────────────────────
  String get homeFeedGlobal => _s('homeFeedGlobal');
  String get homeFeedFollowing => _s('homeFeedFollowing');
  String get homeEmptyTitle => _s('homeEmptyTitle');
  String get homeEmptyHint => _s('homeEmptyHint');
  String get homeFollowingEmptyTitle => _s('homeFollowingEmptyTitle');
  String get homeFollowingEmptyHint => _s('homeFollowingEmptyHint');
  String get homeNewPost => _s('homeNewPost');
  String get homeShortsMode => _s('homeShortsMode');
  String get postLike => _s('postLike');
  String get postComment => _s('postComment');
  String get postShare => _s('postShare');
  String get postSendMessage => _s('postSendMessage');
  String get postDelete => _s('postDelete');
  String get postDeleteConfirm => _s('postDeleteConfirm');
  String get commentsNone => _s('commentsNone');
  String get commentReply => _s('commentReply');
  String get commentReplyingTo => _s('commentReplyingTo');
  String get commentWrite => _s('commentWrite');

  // ── Teams ────────────────────────────────────────────────────────
  String get teamsHubTitle => _s('teamsHubTitle');
  String get teamsTabMine => _s('teamsTabMine');
  String get teamsTabExplore => _s('teamsTabExplore');
  String get teamsTabChallenges => _s('teamsTabChallenges');
  String get teamsCreate => _s('teamsCreate');
  String get teamsChallenge => _s('teamsChallenge');
  String get teamsInvite => _s('teamsInvite');
  String get teamsLeave => _s('teamsLeave');
  String get teamsPremiumRequired => _s('teamsPremiumRequired');
  String get teamsPremiumRequiredBody => _s('teamsPremiumRequiredBody');

  // ── Player card ──────────────────────────────────────────────────
  String get cardTitle => _s('cardTitle');
  String get cardCoins => _s('cardCoins');
  String get cardClaimInitial => _s('cardClaimInitial');
  String get cardClaimMonthly => _s('cardClaimMonthly');
  String get cardPlaystyles => _s('cardPlaystyles');
  String get cardStats => _s('cardStats');
  String get cardSaveStats => _s('cardSaveStats');
  String get cardVotePlaystyles => _s('cardVotePlaystyles');
  String get cardVoteSaved => _s('cardVoteSaved');
}

// ─── Delegate ──────────────────────────────────────────────────────────

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      _strings.containsKey(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final code = _strings.containsKey(locale.languageCode)
        ? locale.languageCode
        : 'pt';
    return AppLocalizations._(locale, _strings[code]!);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

// ─── String tables ─────────────────────────────────────────────────────

const Map<String, Map<String, String>> _strings = {
  'pt': _pt,
  'en': _en,
  'es': _es,
  'zh': _zh,
  'fr': _fr,
};

const _pt = <String, String>{
  'appTitle': 'Skills Arena',
  'tabHome': 'Home',
  'tabExplore': 'Explorar',
  'tabMessages': 'Mensagens',
  'tabProfile': 'Perfil',

  'loginTitle': 'Entrar',
  'loginSubtitle': 'Bem-vindo de volta à Skills Arena',
  'loginEmail': 'E-mail',
  'loginPassword': 'Senha',
  'loginButton': 'Entrar',
  'loginCreateAccount': 'Criar conta',
  'loginWithGoogle': 'Entrar com Google',
  'loginForgotPassword': 'Esqueceu a senha?',
  'loginNoAccount': 'Ainda não tem conta?',
  'loginInvalidCredentials': 'E-mail ou senha inválidos.',

  'registerTitle': 'Criar conta',
  'registerName': 'Nome',
  'registerButton': 'Criar conta',
  'registerHaveAccount': 'Já tem conta? Entrar',

  'profileTitle': 'Perfil',
  'profileAccountSection': 'CONTA',
  'profileDeveloperSection': 'DESENVOLVEDOR',
  'profileEmail': 'E-mail',
  'profileMyAddress': 'Meu endereço',
  'profileMyAddressSubtitle': 'Defina um endereço fixo para o mapa',
  'profileRanking': 'Ranking geral',
  'profileRankingSubtitle': 'Top jogadores por seguidores',
  'profileTeams': 'Times',
  'profileTeamsSubtitle': 'Crie um time, desafie outros e marque jogos',
  'profileSignOut': 'Sair da conta',
  'profileSignOutConfirm': 'Tem certeza que deseja sair?',
  'profileLanguage': 'Idioma',
  'profileLanguageSubtitle': 'Português, Inglês, Espanhol, Chinês, Francês',
  'profileSearchableByEmail': 'Buscável por e-mail',
  'profileSearchableByEmailSubtitle':
      'Outros usuários podem te achar pelo e-mail',
  'profilePremium': 'Premium',
  'profileFree': 'Gratuito',
  'profileFollowers': 'seguidores',
  'profileFollowing': 'seguindo',
  'profileUpgradeTitle': 'Upgrade para Premium',
  'profileUpgradeBody':
      'Acesse recursos exclusivos, sem anúncios e com suporte prioritário.',
  'profileUpgradeButton': 'Ver planos',

  'languageSystem': 'Padrão do sistema',
  'languagePortuguese': 'Português',
  'languageEnglish': 'Inglês',
  'languageSpanish': 'Espanhol',
  'languageChinese': 'Chinês',
  'languageFrench': 'Francês',

  'commonCancel': 'Cancelar',
  'commonSave': 'Salvar',
  'commonDelete': 'Apagar',
  'commonConfirm': 'Confirmar',
  'commonOk': 'OK',
  'commonClose': 'Fechar',
  'commonLoading': 'Carregando…',
  'commonError': 'Erro',
  'commonRetry': 'Tentar de novo',
  'commonSearch': 'Buscar',
  'commonShare': 'Compartilhar',
  'commonEdit': 'Editar',
  'commonYes': 'Sim',
  'commonNo': 'Não',

  'chatNewMessage': 'Mensagem...',
  'chatSend': 'Enviar',
  'chatShareLocation': 'Compartilhar localização',
  'chatTapToViewProfile': 'Toque para ver perfil',
  'chatNoConversations': 'Nenhuma conversa ainda',
  'chatStartConversation': 'Comece uma conversa nova',
  'chatSayHi': 'Diga olá!',

  'mapSearchRadius': 'Raio de busca',
  'mapGlobalSearch': 'Busca global',
  'mapGlobalSearchSubtitle':
      'Ignora o raio. Mostra tudo num raio de 60 km.',
  'mapVerifiedOnly': 'Somente quadras verificadas',
  'mapVerifiedOnlySubtitle': 'Mostra só locais conferidos pela equipe.',
  'mapMyLocation': 'Minha localização',
  'mapWantToPlay': 'Quero jogar',
  'mapWantToPlayHere': 'Quero jogar aqui',
  'mapAddVenue': 'Adicionar quadra',
  'mapCenter': 'Centralizar',
  'mapDetails': 'Detalhes',
  'mapNoGps': 'Sem GPS nem endereço fixo. Cadastre seu endereço no perfil.',

  'homeFeedGlobal': 'Global',
  'homeFeedFollowing': 'Seguindo',
  'homeEmptyTitle': 'Nenhuma publicação ainda',
  'homeEmptyHint': 'Seja o primeiro a publicar!',
  'homeFollowingEmptyTitle': 'Você ainda não segue ninguém',
  'homeFollowingEmptyHint': 'Siga jogadores para ver as publicações deles.',
  'homeNewPost': 'Nova publicação',
  'homeShortsMode': 'Modo Shorts',
  'postLike': 'Curtir',
  'postComment': 'Comentar',
  'postShare': 'Compartilhar',
  'postSendMessage': 'Mensagem',
  'postDelete': 'Apagar publicação',
  'postDeleteConfirm':
      'Esta ação não pode ser desfeita. Comentários e curtidas serão removidos.',
  'commentsNone': 'Sem comentários ainda.',
  'commentReply': 'Responder',
  'commentReplyingTo': 'Respondendo a',
  'commentWrite': 'Escreva um comentário...',

  'teamsHubTitle': 'Times',
  'teamsTabMine': 'Meus',
  'teamsTabExplore': 'Explorar',
  'teamsTabChallenges': 'Desafios',
  'teamsCreate': 'Criar time',
  'teamsChallenge': 'Desafiar outro time',
  'teamsInvite': 'Convidar membro',
  'teamsLeave': 'Sair do time',
  'teamsPremiumRequired': 'Premium necessário',
  'teamsPremiumRequiredBody':
      'Criar e gerenciar times é um recurso Premium. Faça upgrade para liberar.',

  'cardTitle': 'Card de Jogador',
  'cardCoins': 'Moedas Skills Arena',
  'cardClaimInitial': 'Reivindicar bônus inicial (+5 moedas)',
  'cardClaimMonthly': 'Reivindicar bônus mensal (+2 moedas)',
  'cardPlaystyles': 'PLAYSTYLES',
  'cardStats': 'STATS',
  'cardSaveStats': 'Salvar stats',
  'cardVotePlaystyles': 'Votar nas playstyles deste jogador',
  'cardVoteSaved': 'Voto salvo!',
};

const _en = <String, String>{
  'appTitle': 'Skills Arena',
  'tabHome': 'Home',
  'tabExplore': 'Explore',
  'tabMessages': 'Messages',
  'tabProfile': 'Profile',

  'loginTitle': 'Sign in',
  'loginSubtitle': 'Welcome back to Skills Arena',
  'loginEmail': 'Email',
  'loginPassword': 'Password',
  'loginButton': 'Sign in',
  'loginCreateAccount': 'Create account',
  'loginWithGoogle': 'Sign in with Google',
  'loginForgotPassword': 'Forgot password?',
  'loginNoAccount': "Don't have an account yet?",
  'loginInvalidCredentials': 'Invalid email or password.',

  'registerTitle': 'Create account',
  'registerName': 'Name',
  'registerButton': 'Create account',
  'registerHaveAccount': 'Already have an account? Sign in',

  'profileTitle': 'Profile',
  'profileAccountSection': 'ACCOUNT',
  'profileDeveloperSection': 'DEVELOPER',
  'profileEmail': 'Email',
  'profileMyAddress': 'My address',
  'profileMyAddressSubtitle': 'Set a fixed address for the map',
  'profileRanking': 'Global ranking',
  'profileRankingSubtitle': 'Top players by followers',
  'profileTeams': 'Teams',
  'profileTeamsSubtitle': 'Create a team, challenge others and schedule games',
  'profileSignOut': 'Sign out',
  'profileSignOutConfirm': 'Are you sure you want to sign out?',
  'profileLanguage': 'Language',
  'profileLanguageSubtitle':
      'Portuguese, English, Spanish, Chinese, French',
  'profileSearchableByEmail': 'Searchable by email',
  'profileSearchableByEmailSubtitle': 'Other users can find you by email',
  'profilePremium': 'Premium',
  'profileFree': 'Free',
  'profileFollowers': 'followers',
  'profileFollowing': 'following',
  'profileUpgradeTitle': 'Upgrade to Premium',
  'profileUpgradeBody':
      'Get exclusive features, no ads and priority support.',
  'profileUpgradeButton': 'See plans',

  'languageSystem': 'System default',
  'languagePortuguese': 'Portuguese',
  'languageEnglish': 'English',
  'languageSpanish': 'Spanish',
  'languageChinese': 'Chinese',
  'languageFrench': 'French',

  'commonCancel': 'Cancel',
  'commonSave': 'Save',
  'commonDelete': 'Delete',
  'commonConfirm': 'Confirm',
  'commonOk': 'OK',
  'commonClose': 'Close',
  'commonLoading': 'Loading…',
  'commonError': 'Error',
  'commonRetry': 'Retry',
  'commonSearch': 'Search',
  'commonShare': 'Share',
  'commonEdit': 'Edit',
  'commonYes': 'Yes',
  'commonNo': 'No',

  'chatNewMessage': 'Message...',
  'chatSend': 'Send',
  'chatShareLocation': 'Share location',
  'chatTapToViewProfile': 'Tap to view profile',
  'chatNoConversations': 'No conversations yet',
  'chatStartConversation': 'Start a new conversation',
  'chatSayHi': 'Say hi!',

  'mapSearchRadius': 'Search radius',
  'mapGlobalSearch': 'Global search',
  'mapGlobalSearchSubtitle':
      'Ignores the radius. Shows everything within 60 km.',
  'mapVerifiedOnly': 'Verified venues only',
  'mapVerifiedOnlySubtitle': 'Show only places reviewed by the team.',
  'mapMyLocation': 'My location',
  'mapWantToPlay': 'I want to play',
  'mapWantToPlayHere': 'I want to play here',
  'mapAddVenue': 'Add venue',
  'mapCenter': 'Center',
  'mapDetails': 'Details',
  'mapNoGps': 'No GPS or fixed address. Set your address in profile.',

  'homeFeedGlobal': 'Global',
  'homeFeedFollowing': 'Following',
  'homeEmptyTitle': 'No posts yet',
  'homeEmptyHint': 'Be the first to post!',
  'homeFollowingEmptyTitle': "You don't follow anyone yet",
  'homeFollowingEmptyHint': 'Follow players to see their posts here.',
  'homeNewPost': 'New post',
  'homeShortsMode': 'Shorts mode',
  'postLike': 'Like',
  'postComment': 'Comment',
  'postShare': 'Share',
  'postSendMessage': 'Message',
  'postDelete': 'Delete post',
  'postDeleteConfirm':
      'This cannot be undone. Comments and likes will be removed.',
  'commentsNone': 'No comments yet.',
  'commentReply': 'Reply',
  'commentReplyingTo': 'Replying to',
  'commentWrite': 'Write a comment...',

  'teamsHubTitle': 'Teams',
  'teamsTabMine': 'Mine',
  'teamsTabExplore': 'Explore',
  'teamsTabChallenges': 'Challenges',
  'teamsCreate': 'Create team',
  'teamsChallenge': 'Challenge another team',
  'teamsInvite': 'Invite member',
  'teamsLeave': 'Leave team',
  'teamsPremiumRequired': 'Premium required',
  'teamsPremiumRequiredBody':
      'Creating and managing teams is a Premium feature. Upgrade to unlock.',

  'cardTitle': 'Player Card',
  'cardCoins': 'Skills Arena coins',
  'cardClaimInitial': 'Claim initial bonus (+5 coins)',
  'cardClaimMonthly': 'Claim monthly bonus (+2 coins)',
  'cardPlaystyles': 'PLAYSTYLES',
  'cardStats': 'STATS',
  'cardSaveStats': 'Save stats',
  'cardVotePlaystyles': "Vote on this player's playstyles",
  'cardVoteSaved': 'Vote saved!',
};

const _es = <String, String>{
  'appTitle': 'Skills Arena',
  'tabHome': 'Inicio',
  'tabExplore': 'Explorar',
  'tabMessages': 'Mensajes',
  'tabProfile': 'Perfil',

  'loginTitle': 'Iniciar sesión',
  'loginSubtitle': 'Bienvenido de nuevo a Skills Arena',
  'loginEmail': 'Correo electrónico',
  'loginPassword': 'Contraseña',
  'loginButton': 'Iniciar sesión',
  'loginCreateAccount': 'Crear cuenta',
  'loginWithGoogle': 'Entrar con Google',
  'loginForgotPassword': '¿Olvidaste la contraseña?',
  'loginNoAccount': '¿Aún no tienes cuenta?',
  'loginInvalidCredentials': 'Correo o contraseña inválidos.',

  'registerTitle': 'Crear cuenta',
  'registerName': 'Nombre',
  'registerButton': 'Crear cuenta',
  'registerHaveAccount': '¿Ya tienes cuenta? Iniciar sesión',

  'profileTitle': 'Perfil',
  'profileAccountSection': 'CUENTA',
  'profileDeveloperSection': 'DESARROLLADOR',
  'profileEmail': 'Correo electrónico',
  'profileMyAddress': 'Mi dirección',
  'profileMyAddressSubtitle': 'Define una dirección fija para el mapa',
  'profileRanking': 'Ranking general',
  'profileRankingSubtitle': 'Mejores jugadores por seguidores',
  'profileTeams': 'Equipos',
  'profileTeamsSubtitle': 'Crea un equipo, desafía a otros y agenda partidos',
  'profileSignOut': 'Cerrar sesión',
  'profileSignOutConfirm': '¿Seguro que deseas cerrar sesión?',
  'profileLanguage': 'Idioma',
  'profileLanguageSubtitle': 'Portugués, Inglés, Español, Chino, Francés',
  'profileSearchableByEmail': 'Buscable por correo',
  'profileSearchableByEmailSubtitle':
      'Otros usuarios pueden encontrarte por correo',
  'profilePremium': 'Premium',
  'profileFree': 'Gratuito',
  'profileFollowers': 'seguidores',
  'profileFollowing': 'siguiendo',
  'profileUpgradeTitle': 'Mejorar a Premium',
  'profileUpgradeBody':
      'Accede a funciones exclusivas, sin anuncios y con soporte prioritario.',
  'profileUpgradeButton': 'Ver planes',

  'languageSystem': 'Predeterminado del sistema',
  'languagePortuguese': 'Portugués',
  'languageEnglish': 'Inglés',
  'languageSpanish': 'Español',
  'languageChinese': 'Chino',
  'languageFrench': 'Francés',

  'commonCancel': 'Cancelar',
  'commonSave': 'Guardar',
  'commonDelete': 'Eliminar',
  'commonConfirm': 'Confirmar',
  'commonOk': 'OK',
  'commonClose': 'Cerrar',
  'commonLoading': 'Cargando…',
  'commonError': 'Error',
  'commonRetry': 'Reintentar',
  'commonSearch': 'Buscar',
  'commonShare': 'Compartir',
  'commonEdit': 'Editar',
  'commonYes': 'Sí',
  'commonNo': 'No',

  'chatNewMessage': 'Mensaje...',
  'chatSend': 'Enviar',
  'chatShareLocation': 'Compartir ubicación',
  'chatTapToViewProfile': 'Toca para ver perfil',
  'chatNoConversations': 'Aún no hay conversaciones',
  'chatStartConversation': 'Iniciar una nueva conversación',
  'chatSayHi': '¡Saluda!',

  'mapSearchRadius': 'Radio de búsqueda',
  'mapGlobalSearch': 'Búsqueda global',
  'mapGlobalSearchSubtitle':
      'Ignora el radio. Muestra todo dentro de 60 km.',
  'mapVerifiedOnly': 'Solo canchas verificadas',
  'mapVerifiedOnlySubtitle': 'Mostrar solo lugares revisados por el equipo.',
  'mapMyLocation': 'Mi ubicación',
  'mapWantToPlay': 'Quiero jugar',
  'mapWantToPlayHere': 'Quiero jugar aquí',
  'mapAddVenue': 'Añadir cancha',
  'mapCenter': 'Centrar',
  'mapDetails': 'Detalles',
  'mapNoGps': 'Sin GPS ni dirección fija. Configura tu dirección en el perfil.',

  'homeFeedGlobal': 'Global',
  'homeFeedFollowing': 'Siguiendo',
  'homeEmptyTitle': 'Aún no hay publicaciones',
  'homeEmptyHint': '¡Sé el primero en publicar!',
  'homeFollowingEmptyTitle': 'Aún no sigues a nadie',
  'homeFollowingEmptyHint': 'Sigue a jugadores para ver sus publicaciones.',
  'homeNewPost': 'Nueva publicación',
  'homeShortsMode': 'Modo Shorts',
  'postLike': 'Me gusta',
  'postComment': 'Comentar',
  'postShare': 'Compartir',
  'postSendMessage': 'Mensaje',
  'postDelete': 'Eliminar publicación',
  'postDeleteConfirm':
      'Esto no se puede deshacer. Los comentarios y me gusta serán eliminados.',
  'commentsNone': 'Aún no hay comentarios.',
  'commentReply': 'Responder',
  'commentReplyingTo': 'Respondiendo a',
  'commentWrite': 'Escribe un comentario...',

  'teamsHubTitle': 'Equipos',
  'teamsTabMine': 'Míos',
  'teamsTabExplore': 'Explorar',
  'teamsTabChallenges': 'Desafíos',
  'teamsCreate': 'Crear equipo',
  'teamsChallenge': 'Desafiar otro equipo',
  'teamsInvite': 'Invitar miembro',
  'teamsLeave': 'Salir del equipo',
  'teamsPremiumRequired': 'Premium requerido',
  'teamsPremiumRequiredBody':
      'Crear y gestionar equipos es una función Premium. Mejora para desbloquear.',

  'cardTitle': 'Tarjeta de Jugador',
  'cardCoins': 'Monedas Skills Arena',
  'cardClaimInitial': 'Reclamar bono inicial (+5 monedas)',
  'cardClaimMonthly': 'Reclamar bono mensual (+2 monedas)',
  'cardPlaystyles': 'ESTILOS',
  'cardStats': 'STATS',
  'cardSaveStats': 'Guardar stats',
  'cardVotePlaystyles': 'Votar los estilos de este jugador',
  'cardVoteSaved': '¡Voto guardado!',
};

const _zh = <String, String>{
  'appTitle': 'Skills Arena',
  'tabHome': '首页',
  'tabExplore': '探索',
  'tabMessages': '消息',
  'tabProfile': '个人资料',

  'loginTitle': '登录',
  'loginSubtitle': '欢迎回到 Skills Arena',
  'loginEmail': '电子邮件',
  'loginPassword': '密码',
  'loginButton': '登录',
  'loginCreateAccount': '创建账户',
  'loginWithGoogle': '使用 Google 登录',
  'loginForgotPassword': '忘记密码？',
  'loginNoAccount': '还没有账户？',
  'loginInvalidCredentials': '邮箱或密码无效。',

  'registerTitle': '创建账户',
  'registerName': '姓名',
  'registerButton': '创建账户',
  'registerHaveAccount': '已有账户？登录',

  'profileTitle': '个人资料',
  'profileAccountSection': '账户',
  'profileDeveloperSection': '开发者',
  'profileEmail': '电子邮件',
  'profileMyAddress': '我的地址',
  'profileMyAddressSubtitle': '为地图设置固定地址',
  'profileRanking': '全球排行榜',
  'profileRankingSubtitle': '按粉丝数排名的顶级球员',
  'profileTeams': '队伍',
  'profileTeamsSubtitle': '创建队伍、挑战其他队伍并安排比赛',
  'profileSignOut': '退出登录',
  'profileSignOutConfirm': '确定要退出吗？',
  'profileLanguage': '语言',
  'profileLanguageSubtitle': '葡萄牙语、英语、西班牙语、中文、法语',
  'profileSearchableByEmail': '可通过电子邮件搜索',
  'profileSearchableByEmailSubtitle': '其他用户可以通过电子邮件找到您',
  'profilePremium': '高级版',
  'profileFree': '免费',
  'profileFollowers': '位粉丝',
  'profileFollowing': '关注中',
  'profileUpgradeTitle': '升级到高级版',
  'profileUpgradeBody': '获得独家功能、无广告和优先支持。',
  'profileUpgradeButton': '查看方案',

  'languageSystem': '系统默认',
  'languagePortuguese': '葡萄牙语',
  'languageEnglish': '英语',
  'languageSpanish': '西班牙语',
  'languageChinese': '中文',
  'languageFrench': '法语',

  'commonCancel': '取消',
  'commonSave': '保存',
  'commonDelete': '删除',
  'commonConfirm': '确认',
  'commonOk': '确定',
  'commonClose': '关闭',
  'commonLoading': '加载中…',
  'commonError': '错误',
  'commonRetry': '重试',
  'commonSearch': '搜索',
  'commonShare': '分享',
  'commonEdit': '编辑',
  'commonYes': '是',
  'commonNo': '否',

  'chatNewMessage': '消息...',
  'chatSend': '发送',
  'chatShareLocation': '分享位置',
  'chatTapToViewProfile': '点击查看资料',
  'chatNoConversations': '暂无对话',
  'chatStartConversation': '开始新对话',
  'chatSayHi': '打个招呼！',

  'mapSearchRadius': '搜索半径',
  'mapGlobalSearch': '全球搜索',
  'mapGlobalSearchSubtitle': '忽略半径。显示 60 公里内的所有内容。',
  'mapVerifiedOnly': '仅认证场地',
  'mapVerifiedOnlySubtitle': '只显示经过团队审核的场所。',
  'mapMyLocation': '我的位置',
  'mapWantToPlay': '我想打球',
  'mapWantToPlayHere': '我想在这里打球',
  'mapAddVenue': '添加场地',
  'mapCenter': '居中',
  'mapDetails': '详情',
  'mapNoGps': '没有 GPS 也没有固定地址。请在个人资料中设置地址。',

  'homeFeedGlobal': '全球',
  'homeFeedFollowing': '关注',
  'homeEmptyTitle': '还没有帖子',
  'homeEmptyHint': '成为第一个发布的人！',
  'homeFollowingEmptyTitle': '您还没有关注任何人',
  'homeFollowingEmptyHint': '关注球员以在此处查看他们的帖子。',
  'homeNewPost': '新帖子',
  'homeShortsMode': '短视频模式',
  'postLike': '点赞',
  'postComment': '评论',
  'postShare': '分享',
  'postSendMessage': '消息',
  'postDelete': '删除帖子',
  'postDeleteConfirm': '此操作无法撤销。评论和点赞将被删除。',
  'commentsNone': '暂无评论。',
  'commentReply': '回复',
  'commentReplyingTo': '回复',
  'commentWrite': '写评论...',

  'teamsHubTitle': '队伍',
  'teamsTabMine': '我的',
  'teamsTabExplore': '探索',
  'teamsTabChallenges': '挑战',
  'teamsCreate': '创建队伍',
  'teamsChallenge': '挑战其他队伍',
  'teamsInvite': '邀请成员',
  'teamsLeave': '离开队伍',
  'teamsPremiumRequired': '需要高级版',
  'teamsPremiumRequiredBody': '创建和管理队伍是高级版功能。升级以解锁。',

  'cardTitle': '球员卡',
  'cardCoins': 'Skills Arena 金币',
  'cardClaimInitial': '领取初始奖励（+5 金币）',
  'cardClaimMonthly': '领取月度奖励（+2 金币）',
  'cardPlaystyles': '风格',
  'cardStats': '属性',
  'cardSaveStats': '保存属性',
  'cardVotePlaystyles': '投票此球员的风格',
  'cardVoteSaved': '投票已保存！',
};

const _fr = <String, String>{
  'appTitle': 'Skills Arena',
  'tabHome': 'Accueil',
  'tabExplore': 'Explorer',
  'tabMessages': 'Messages',
  'tabProfile': 'Profil',

  'loginTitle': 'Connexion',
  'loginSubtitle': 'Bon retour sur Skills Arena',
  'loginEmail': 'E-mail',
  'loginPassword': 'Mot de passe',
  'loginButton': 'Se connecter',
  'loginCreateAccount': 'Créer un compte',
  'loginWithGoogle': 'Se connecter avec Google',
  'loginForgotPassword': 'Mot de passe oublié ?',
  'loginNoAccount': "Vous n'avez pas encore de compte ?",
  'loginInvalidCredentials': 'E-mail ou mot de passe invalide.',

  'registerTitle': 'Créer un compte',
  'registerName': 'Nom',
  'registerButton': 'Créer un compte',
  'registerHaveAccount': 'Déjà un compte ? Se connecter',

  'profileTitle': 'Profil',
  'profileAccountSection': 'COMPTE',
  'profileDeveloperSection': 'DÉVELOPPEUR',
  'profileEmail': 'E-mail',
  'profileMyAddress': 'Mon adresse',
  'profileMyAddressSubtitle': 'Définir une adresse fixe pour la carte',
  'profileRanking': 'Classement général',
  'profileRankingSubtitle': 'Meilleurs joueurs par abonnés',
  'profileTeams': 'Équipes',
  'profileTeamsSubtitle':
      'Créez une équipe, défiez les autres et programmez des matchs',
  'profileSignOut': 'Se déconnecter',
  'profileSignOutConfirm': 'Êtes-vous sûr de vouloir vous déconnecter ?',
  'profileLanguage': 'Langue',
  'profileLanguageSubtitle':
      'Portugais, Anglais, Espagnol, Chinois, Français',
  'profileSearchableByEmail': 'Recherche par e-mail',
  'profileSearchableByEmailSubtitle':
      'Les autres utilisateurs peuvent vous trouver par e-mail',
  'profilePremium': 'Premium',
  'profileFree': 'Gratuit',
  'profileFollowers': 'abonnés',
  'profileFollowing': 'abonnements',
  'profileUpgradeTitle': 'Passer à Premium',
  'profileUpgradeBody':
      'Accédez à des fonctionnalités exclusives, sans publicité et avec support prioritaire.',
  'profileUpgradeButton': 'Voir les plans',

  'languageSystem': 'Par défaut du système',
  'languagePortuguese': 'Portugais',
  'languageEnglish': 'Anglais',
  'languageSpanish': 'Espagnol',
  'languageChinese': 'Chinois',
  'languageFrench': 'Français',

  'commonCancel': 'Annuler',
  'commonSave': 'Enregistrer',
  'commonDelete': 'Supprimer',
  'commonConfirm': 'Confirmer',
  'commonOk': 'OK',
  'commonClose': 'Fermer',
  'commonLoading': 'Chargement…',
  'commonError': 'Erreur',
  'commonRetry': 'Réessayer',
  'commonSearch': 'Rechercher',
  'commonShare': 'Partager',
  'commonEdit': 'Modifier',
  'commonYes': 'Oui',
  'commonNo': 'Non',

  'chatNewMessage': 'Message...',
  'chatSend': 'Envoyer',
  'chatShareLocation': 'Partager la position',
  'chatTapToViewProfile': 'Touchez pour voir le profil',
  'chatNoConversations': 'Aucune conversation pour le moment',
  'chatStartConversation': 'Commencer une nouvelle conversation',
  'chatSayHi': 'Dites bonjour !',

  'mapSearchRadius': 'Rayon de recherche',
  'mapGlobalSearch': 'Recherche globale',
  'mapGlobalSearchSubtitle':
      'Ignore le rayon. Affiche tout dans un rayon de 60 km.',
  'mapVerifiedOnly': 'Terrains vérifiés uniquement',
  'mapVerifiedOnlySubtitle':
      'Affiche uniquement les lieux vérifiés par l\'équipe.',
  'mapMyLocation': 'Ma position',
  'mapWantToPlay': 'Je veux jouer',
  'mapWantToPlayHere': 'Je veux jouer ici',
  'mapAddVenue': 'Ajouter un terrain',
  'mapCenter': 'Centrer',
  'mapDetails': 'Détails',
  'mapNoGps':
      "Pas de GPS ni d'adresse fixe. Définissez votre adresse dans le profil.",

  'homeFeedGlobal': 'Global',
  'homeFeedFollowing': 'Abonnements',
  'homeEmptyTitle': 'Aucune publication pour le moment',
  'homeEmptyHint': 'Soyez le premier à publier !',
  'homeFollowingEmptyTitle': "Vous ne suivez personne pour l'instant",
  'homeFollowingEmptyHint':
      'Suivez des joueurs pour voir leurs publications ici.',
  'homeNewPost': 'Nouvelle publication',
  'homeShortsMode': 'Mode Shorts',
  'postLike': "J'aime",
  'postComment': 'Commenter',
  'postShare': 'Partager',
  'postSendMessage': 'Message',
  'postDelete': 'Supprimer la publication',
  'postDeleteConfirm':
      "Cette action est irréversible. Les commentaires et j'aime seront supprimés.",
  'commentsNone': 'Aucun commentaire pour le moment.',
  'commentReply': 'Répondre',
  'commentReplyingTo': 'En réponse à',
  'commentWrite': 'Écrire un commentaire...',

  'teamsHubTitle': 'Équipes',
  'teamsTabMine': 'Mes équipes',
  'teamsTabExplore': 'Explorer',
  'teamsTabChallenges': 'Défis',
  'teamsCreate': 'Créer une équipe',
  'teamsChallenge': 'Défier une autre équipe',
  'teamsInvite': 'Inviter un membre',
  'teamsLeave': "Quitter l'équipe",
  'teamsPremiumRequired': 'Premium requis',
  'teamsPremiumRequiredBody':
      'Créer et gérer des équipes est une fonctionnalité Premium. Passez à Premium pour débloquer.',

  'cardTitle': 'Carte Joueur',
  'cardCoins': 'Pièces Skills Arena',
  'cardClaimInitial': 'Réclamer le bonus initial (+5 pièces)',
  'cardClaimMonthly': 'Réclamer le bonus mensuel (+2 pièces)',
  'cardPlaystyles': 'STYLES',
  'cardStats': 'STATS',
  'cardSaveStats': 'Enregistrer les stats',
  'cardVotePlaystyles': 'Voter sur les styles de ce joueur',
  'cardVoteSaved': 'Vote enregistré !',
};
