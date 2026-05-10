import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skills_arena/presentation/screens/home/home_screen.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../providers/main_tab_provider.dart';
import '../../widgets/navigation/custom_back_button.dart';

// ─── Hub de demonstração de navegação ────────────────────────────────────────
// Aberta via AppNavigator.pushWithNavBar() da tela de Perfil.
// Mostra 3 botões que demonstram os 3 padrões de navegação do app.
// ─────────────────────────────────────────────────────────────────────────────

class NavDemoScreen extends StatelessWidget {
  const NavDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Exemplos de Navegação')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Padrões disponíveis',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque em cada botão para ver o comportamento de navegação.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // ── Padrão 1: COM nav bar ────────────────────────────────────────
          _DemoCard(
            icon: Icons.tab_rounded,
            color: cs.primary,
            title: 'COM bottom nav bar',
            subtitle:
                'AppNavigator.pushWithNavBar()\nA barra de navegação continua visível.',
            onTap: () => AppNavigator.pushWithNavBar(
                context, const _TestWithNavBar()),
          ),
          const SizedBox(height: 12),

          // ── Padrão 2: SEM nav bar ────────────────────────────────────────
          _DemoCard(
            icon: Icons.fullscreen_rounded,
            color: cs.tertiary,
            title: 'SEM bottom nav bar',
            subtitle:
                'AppNavigator.pushWithoutNavBar()\nTela em tela cheia, barra oculta.',
            onTap: () => AppNavigator.pushWithoutNavBar(
                context, const _TestWithoutNavBar()),
          ),
          const SizedBox(height: 12),

          // ── Padrão 3: SEM nav bar + voltar personalizado ─────────────────
          _DemoCard(
            icon: Icons.arrow_back_ios_new_rounded,
            color: Colors.orange,
            title: 'Voltar personalizado',
            subtitle:
                'SEM nav bar + CustomBackButton.\nAo tocar em voltar, aparece um popup com opções.',
            onTap: () => AppNavigator.pushWithoutNavBar(
                context, const _TestCustomBack()),
          ),
          const SizedBox(height: 32),

          // ── Guia de referência rápida ────────────────────────────────────
          Card(
            color: cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Referência rápida',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const _CodeLine(
                      code:
                          'AppNavigator.pushWithNavBar(context, Tela())'),
                  const SizedBox(height: 6),
                  const _CodeLine(
                      code:
                          'AppNavigator.pushWithoutNavBar(context, Tela())'),
                  const SizedBox(height: 6),
                  const _CodeLine(code: 'Scaffold(appBar: null, ...)  // sem AppBar'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DemoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeLine extends StatelessWidget {
  final String code;
  const _CodeLine({required this.code});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        code,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      ),
    );
  }
}

// ─── Tela 1: COM nav bar ──────────────────────────────────────────────────────
// AppBar: VISÍVEL   Nav bar: VISÍVEL (pushWithNavBar)

class _TestWithNavBar extends StatelessWidget {
  const _TestWithNavBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('COM nav bar'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tab_rounded,
                size: 80, color: cs.primary),
            const SizedBox(height: 16),
            Text('Nav bar visível abaixo!',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Aberta com pushWithNavBar()\nNavigator.of(context).push()',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tela 2: SEM nav bar ─────────────────────────────────────────────────────
// AppBar: VISÍVEL   Nav bar: OCULTA (pushWithoutNavBar)

class _TestWithoutNavBar extends StatelessWidget {
  const _TestWithoutNavBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEM nav bar'),
        backgroundColor: cs.tertiary,
        foregroundColor: cs.onTertiary,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fullscreen_rounded, size: 80, color: cs.tertiary),
            const SizedBox(height: 16),
            Text('Nav bar oculta!',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Aberta com pushWithoutNavBar()\nNavigator.of(context, rootNavigator: true).push()',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tela 3: Voltar personalizado ────────────────────────────────────────────
// AppBar: VISÍVEL com CustomBackButton   Nav bar: OCULTA (pushWithoutNavBar)
// PopScope intercepta gesto de voltar do sistema e mostra o mesmo popup.

class _TestCustomBack extends ConsumerWidget {
  const _TestCustomBack();

  /// Switch the shell to [tabIndex] AND clear all routes pushed above the
  /// shell on the root navigator. Without the popUntil the new tab is
  /// active but invisible behind whatever was pushed via pushWithoutNavBar.
  void _goToTab(BuildContext context, WidgetRef ref, int tabIndex) {
    ref.read(mainTabProvider.notifier).state = tabIndex;
    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitSheet(context, ref);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Voltar personalizado'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          leading: CustomBackButton(
            options: [
              BackMenuOption(
                icon: Icons.home_rounded,
                label: 'Ir para Home',
                subtitle: 'Fechar e voltar ao início',
                onTap: () => _goToTab(context, ref, 0),
              ),
              BackMenuOption(
                icon: Icons.explore_outlined,
                label: 'Ir para Explorar',
                subtitle: 'Fechar e abrir o mapa',
                onTap: () => _goToTab(context, ref, 1),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 80, color: Colors.orange),
              const SizedBox(height: 16),
              Text('Voltar personalizado!',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Pressione o botão ← na AppBar\nou o botão de voltar do sistema.\nUm popup com opções vai aparecer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitSheet(BuildContext context, WidgetRef ref) {
    final screenNavigator = Navigator.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                  child:
                      Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
              title: const Text('Voltar'),
              subtitle: const Text('Retornar à tela anterior'),
              onTap: () {
                Navigator.of(ctx).pop();
                if (screenNavigator.canPop()) screenNavigator.pop();
              },
            ),
            ListTile(
              leading:
                  const CircleAvatar(child: Icon(Icons.home_rounded, size: 18)),
              title: const Text('Ir para Home'),
              onTap: () => AppNavigator.pushWithNavBar(
                      context, const HomeScreen())
            ),
            ListTile(
              leading: const CircleAvatar(
                  child: Icon(Icons.explore_outlined, size: 18)),
              title: const Text('Ir para Explorar'),
              onTap: () {
                Navigator.of(ctx).pop();
                _goToTab(context, ref, 1);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
