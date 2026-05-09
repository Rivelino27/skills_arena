import 'package:flutter/material.dart';

class BackMenuOption {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const BackMenuOption({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });
}

/// Botão de voltar personalizado que exibe um bottom sheet de opções.
///
/// Uso no AppBar:
/// ```dart
/// AppBar(
///   leading: CustomBackButton(
///     options: [
///       BackMenuOption(
///         icon: Icons.home,
///         label: 'Ir para Home',
///         onTap: () => context.go('/home'),
///       ),
///     ],
///   ),
/// )
/// ```
class CustomBackButton extends StatelessWidget {
  final List<BackMenuOption> options;

  const CustomBackButton({super.key, this.options = const []});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: () => _showMenu(context),
    );
  }

  void _showMenu(BuildContext context) {
    // Capture the navigator that owns this screen BEFORE pushing the modal.
    // The modal is on the root navigator overlay; trying to pop using
    // `context` after the modal closes can resolve to the wrong navigator
    // (or be raced by the modal's own dismissal animation). Capturing here
    // ensures the back action targets the screen, not the modal.
    final screenNavigator = Navigator.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
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
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(ctx).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              title: const Text('Voltar'),
              subtitle: const Text('Retornar à tela anterior'),
              onTap: () {
                Navigator.of(ctx).pop();
                if (screenNavigator.canPop()) {
                  screenNavigator.pop();
                }
              },
            ),
            for (final option in options)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  child: Icon(option.icon, size: 18),
                ),
                title: Text(option.label),
                subtitle:
                    option.subtitle != null ? Text(option.subtitle!) : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  option.onTap();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
