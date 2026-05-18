import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

/// Tela de seleção de idioma. `null` na lista = "seguir idioma do
/// sistema" (default). Persistência fica a cargo de `LocaleNotifier`.
class LanguagePickerScreen extends ConsumerWidget {
  const LanguagePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.profileLanguage)),
      body: ListView(
        children: [
          _LangTile(
            label: t.languageSystem,
            flag: '🌐',
            selected: current == null,
            onTap: () => ref.read(localeProvider.notifier).setLocale(null),
          ),
          const Divider(height: 1),
          _LangTile(
            label: t.languagePortuguese,
            flag: '🇧🇷',
            selected: current?.languageCode == 'pt',
            onTap: () => ref
                .read(localeProvider.notifier)
                .setLocale(const Locale('pt')),
          ),
          _LangTile(
            label: t.languageEnglish,
            flag: '🇺🇸',
            selected: current?.languageCode == 'en',
            onTap: () => ref
                .read(localeProvider.notifier)
                .setLocale(const Locale('en')),
          ),
          _LangTile(
            label: t.languageSpanish,
            flag: '🇪🇸',
            selected: current?.languageCode == 'es',
            onTap: () => ref
                .read(localeProvider.notifier)
                .setLocale(const Locale('es')),
          ),
          _LangTile(
            label: t.languageChinese,
            flag: '🇨🇳',
            selected: current?.languageCode == 'zh',
            onTap: () => ref
                .read(localeProvider.notifier)
                .setLocale(const Locale('zh')),
          ),
          _LangTile(
            label: t.languageFrench,
            flag: '🇫🇷',
            selected: current?.languageCode == 'fr',
            onTap: () => ref
                .read(localeProvider.notifier)
                .setLocale(const Locale('fr')),
          ),
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;
  const _LangTile({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 26)),
      title: Text(label,
          style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? cs.primary : null)),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: cs.primary)
          : null,
      onTap: onTap,
    );
  }
}
