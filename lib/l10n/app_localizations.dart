import 'package:flutter/material.dart';

/// Hand-rolled localizations to avoid the codegen pipeline (synthetic
/// flutter_gen package). The matching `.arb` files in this folder are
/// kept as the source-of-truth reference and will be used when we
/// eventually migrate to `flutter gen-l10n`.
///
/// Lookup:
///   `AppLocalizations.of(context).profileTitle`
///
/// Strings live as plain getters so the analyzer flags any typo
/// immediately, instead of failing silently at runtime like a Map.
class AppLocalizations {
  final Locale locale;
  final Map<String, String> _strings;

  AppLocalizations._(this.locale, this._strings);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String _s(String key) => _strings[key] ?? key;

  // ── Top-level ────────────────────────────────────────────────────
  String get appTitle => _s('appTitle');
  String get tabHome => _s('tabHome');
  String get tabExplore => _s('tabExplore');
  String get tabMessages => _s('tabMessages');
  String get tabProfile => _s('tabProfile');

  // ── Login ────────────────────────────────────────────────────────
  String get loginTitle => _s('loginTitle');
  String get loginEmail => _s('loginEmail');
  String get loginPassword => _s('loginPassword');
  String get loginButton => _s('loginButton');
  String get loginCreateAccount => _s('loginCreateAccount');
  String get loginWithGoogle => _s('loginWithGoogle');
  String get loginForgotPassword => _s('loginForgotPassword');

  // ── Profile ──────────────────────────────────────────────────────
  String get profileTitle => _s('profileTitle');
  String get profileAccountSection => _s('profileAccountSection');
  String get profileEmail => _s('profileEmail');
  String get profileMyAddress => _s('profileMyAddress');
  String get profileRanking => _s('profileRanking');
  String get profileTeams => _s('profileTeams');
  String get profileSignOut => _s('profileSignOut');
  String get profileLanguage => _s('profileLanguage');
  String get profileSearchableByEmail => _s('profileSearchableByEmail');

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
  String get commonLoading => _s('commonLoading');
  String get commonError => _s('commonError');

  // ── Chat ─────────────────────────────────────────────────────────
  String get chatNewMessage => _s('chatNewMessage');
  String get chatSend => _s('chatSend');
  String get chatShareLocation => _s('chatShareLocation');
  String get chatTapToViewProfile => _s('chatTapToViewProfile');

  // ── Map ──────────────────────────────────────────────────────────
  String get mapSearchRadius => _s('mapSearchRadius');
  String get mapGlobalSearch => _s('mapGlobalSearch');
  String get mapVerifiedOnly => _s('mapVerifiedOnly');
  String get mapMyLocation => _s('mapMyLocation');
  String get mapWantToPlay => _s('mapWantToPlay');
  String get mapAddVenue => _s('mapAddVenue');
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
//
// Mirror of the .arb files in this folder. Keep both in sync — the .arb
// files are the reference for translators; the maps below are what the
// app actually serves at runtime.

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
  'loginEmail': 'E-mail',
  'loginPassword': 'Senha',
  'loginButton': 'Entrar',
  'loginCreateAccount': 'Criar conta',
  'loginWithGoogle': 'Entrar com Google',
  'loginForgotPassword': 'Esqueceu a senha?',
  'profileTitle': 'Perfil',
  'profileAccountSection': 'CONTA',
  'profileEmail': 'E-mail',
  'profileMyAddress': 'Meu endereço',
  'profileRanking': 'Ranking geral',
  'profileTeams': 'Times',
  'profileSignOut': 'Sair da conta',
  'profileLanguage': 'Idioma',
  'profileSearchableByEmail': 'Buscável por e-mail',
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
  'commonLoading': 'Carregando…',
  'commonError': 'Erro',
  'chatNewMessage': 'Mensagem...',
  'chatSend': 'Enviar',
  'chatShareLocation': 'Compartilhar localização',
  'chatTapToViewProfile': 'Toque para ver perfil',
  'mapSearchRadius': 'Raio de busca',
  'mapGlobalSearch': 'Busca global',
  'mapVerifiedOnly': 'Somente quadras verificadas',
  'mapMyLocation': 'Minha localização',
  'mapWantToPlay': 'Quero jogar',
  'mapAddVenue': 'Adicionar quadra',
};

const _en = <String, String>{
  'appTitle': 'Skills Arena',
  'tabHome': 'Home',
  'tabExplore': 'Explore',
  'tabMessages': 'Messages',
  'tabProfile': 'Profile',
  'loginTitle': 'Sign in',
  'loginEmail': 'Email',
  'loginPassword': 'Password',
  'loginButton': 'Sign in',
  'loginCreateAccount': 'Create account',
  'loginWithGoogle': 'Sign in with Google',
  'loginForgotPassword': 'Forgot password?',
  'profileTitle': 'Profile',
  'profileAccountSection': 'ACCOUNT',
  'profileEmail': 'Email',
  'profileMyAddress': 'My address',
  'profileRanking': 'Global ranking',
  'profileTeams': 'Teams',
  'profileSignOut': 'Sign out',
  'profileLanguage': 'Language',
  'profileSearchableByEmail': 'Searchable by email',
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
  'commonLoading': 'Loading…',
  'commonError': 'Error',
  'chatNewMessage': 'Message...',
  'chatSend': 'Send',
  'chatShareLocation': 'Share location',
  'chatTapToViewProfile': 'Tap to view profile',
  'mapSearchRadius': 'Search radius',
  'mapGlobalSearch': 'Global search',
  'mapVerifiedOnly': 'Verified venues only',
  'mapMyLocation': 'My location',
  'mapWantToPlay': 'I want to play',
  'mapAddVenue': 'Add venue',
};

const _es = <String, String>{
  'appTitle': 'Skills Arena',
  'tabHome': 'Inicio',
  'tabExplore': 'Explorar',
  'tabMessages': 'Mensajes',
  'tabProfile': 'Perfil',
  'loginTitle': 'Iniciar sesión',
  'loginEmail': 'Correo electrónico',
  'loginPassword': 'Contraseña',
  'loginButton': 'Iniciar sesión',
  'loginCreateAccount': 'Crear cuenta',
  'loginWithGoogle': 'Entrar con Google',
  'loginForgotPassword': '¿Olvidaste la contraseña?',
  'profileTitle': 'Perfil',
  'profileAccountSection': 'CUENTA',
  'profileEmail': 'Correo electrónico',
  'profileMyAddress': 'Mi dirección',
  'profileRanking': 'Ranking general',
  'profileTeams': 'Equipos',
  'profileSignOut': 'Cerrar sesión',
  'profileLanguage': 'Idioma',
  'profileSearchableByEmail': 'Buscable por correo',
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
  'commonLoading': 'Cargando…',
  'commonError': 'Error',
  'chatNewMessage': 'Mensaje...',
  'chatSend': 'Enviar',
  'chatShareLocation': 'Compartir ubicación',
  'chatTapToViewProfile': 'Toca para ver perfil',
  'mapSearchRadius': 'Radio de búsqueda',
  'mapGlobalSearch': 'Búsqueda global',
  'mapVerifiedOnly': 'Solo canchas verificadas',
  'mapMyLocation': 'Mi ubicación',
  'mapWantToPlay': 'Quiero jugar',
  'mapAddVenue': 'Añadir cancha',
};

const _zh = <String, String>{
  'appTitle': 'Skills Arena',
  'tabHome': '首页',
  'tabExplore': '探索',
  'tabMessages': '消息',
  'tabProfile': '个人资料',
  'loginTitle': '登录',
  'loginEmail': '电子邮件',
  'loginPassword': '密码',
  'loginButton': '登录',
  'loginCreateAccount': '创建账户',
  'loginWithGoogle': '使用 Google 登录',
  'loginForgotPassword': '忘记密码？',
  'profileTitle': '个人资料',
  'profileAccountSection': '账户',
  'profileEmail': '电子邮件',
  'profileMyAddress': '我的地址',
  'profileRanking': '全球排行榜',
  'profileTeams': '队伍',
  'profileSignOut': '退出登录',
  'profileLanguage': '语言',
  'profileSearchableByEmail': '可通过电子邮件搜索',
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
  'commonLoading': '加载中…',
  'commonError': '错误',
  'chatNewMessage': '消息...',
  'chatSend': '发送',
  'chatShareLocation': '分享位置',
  'chatTapToViewProfile': '点击查看资料',
  'mapSearchRadius': '搜索半径',
  'mapGlobalSearch': '全球搜索',
  'mapVerifiedOnly': '仅认证场地',
  'mapMyLocation': '我的位置',
  'mapWantToPlay': '我想打球',
  'mapAddVenue': '添加场地',
};

const _fr = <String, String>{
  'appTitle': 'Skills Arena',
  'tabHome': 'Accueil',
  'tabExplore': 'Explorer',
  'tabMessages': 'Messages',
  'tabProfile': 'Profil',
  'loginTitle': 'Connexion',
  'loginEmail': 'E-mail',
  'loginPassword': 'Mot de passe',
  'loginButton': 'Se connecter',
  'loginCreateAccount': 'Créer un compte',
  'loginWithGoogle': 'Se connecter avec Google',
  'loginForgotPassword': 'Mot de passe oublié ?',
  'profileTitle': 'Profil',
  'profileAccountSection': 'COMPTE',
  'profileEmail': 'E-mail',
  'profileMyAddress': 'Mon adresse',
  'profileRanking': 'Classement général',
  'profileTeams': 'Équipes',
  'profileSignOut': 'Se déconnecter',
  'profileLanguage': 'Langue',
  'profileSearchableByEmail': 'Recherche par e-mail',
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
  'commonLoading': 'Chargement…',
  'commonError': 'Erreur',
  'chatNewMessage': 'Message...',
  'chatSend': 'Envoyer',
  'chatShareLocation': 'Partager la position',
  'chatTapToViewProfile': 'Touchez pour voir le profil',
  'mapSearchRadius': 'Rayon de recherche',
  'mapGlobalSearch': 'Recherche globale',
  'mapVerifiedOnly': 'Terrains vérifiés uniquement',
  'mapMyLocation': 'Ma position',
  'mapWantToPlay': 'Je veux jouer',
  'mapAddVenue': 'Ajouter un terrain',
};
