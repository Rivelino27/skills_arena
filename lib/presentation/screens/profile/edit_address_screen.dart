import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/social_repository.dart';
import '../../providers/user_provider.dart';

/// Lets the user manage their address book: up to 20 saved addresses
/// (Casa, Trabalho, Faculdade…), pick one as active for map searches,
/// or remove. The active address mirrors into the legacy `address`
/// fields on the user doc.
class EditAddressScreen extends ConsumerWidget {
  const EditAddressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meus endereços')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (user) {
          final addresses = user?.addresses ?? const <SavedAddress>[];
          final activeId = user?.activeAddressId;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Seus endereços de busca no mapa. ${addresses.length}/$kMaxSavedAddresses cadastrados.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: addresses.isEmpty
                    ? _Empty(
                        onAdd: () => _openAdd(context),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: addresses.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 64),
                        itemBuilder: (_, i) {
                          final a = addresses[i];
                          final isActive = a.id == activeId;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isActive
                                  ? cs.primary
                                  : cs.surfaceContainerHighest,
                              child: Icon(
                                isActive
                                    ? Icons.check_rounded
                                    : Icons.location_on_outlined,
                                color: isActive
                                    ? cs.onPrimary
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                            title: Text(
                              a.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isActive ? cs.primary : null,
                              ),
                            ),
                            subtitle: Text(
                              a.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: PopupMenuButton<String>(
                              tooltip: 'Opções',
                              icon: Icon(Icons.more_vert_rounded,
                                  color: cs.onSurfaceVariant),
                              onSelected: (v) {
                                if (v == 'activate') {
                                  ref
                                      .read(socialRepositoryProvider)
                                      .setActiveAddress(a.id);
                                } else if (v == 'delete') {
                                  _confirmDelete(context, ref, a);
                                }
                              },
                              itemBuilder: (_) => [
                                if (!isActive)
                                  const PopupMenuItem(
                                    value: 'activate',
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading:
                                          Icon(Icons.radio_button_checked),
                                      title: Text('Tornar ativo'),
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red),
                                    title: Text('Remover'),
                                  ),
                                ),
                              ],
                            ),
                            onTap: isActive
                                ? null
                                : () => ref
                                    .read(socialRepositoryProvider)
                                    .setActiveAddress(a.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: userAsync.maybeWhen(
        data: (u) {
          final canAdd =
              (u?.addresses.length ?? 0) < kMaxSavedAddresses;
          return FloatingActionButton.extended(
            onPressed: canAdd ? () => _openAdd(context) : null,
            icon: const Icon(Icons.add_location_alt_rounded),
            label: const Text('Adicionar endereço'),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _AddAddressScreen()),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedAddress a,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover endereço?'),
        content: Text(
            'Tem certeza que deseja remover "${a.label}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(socialRepositoryProvider).removeSavedAddress(a.id);
    messenger.showSnackBar(
      const SnackBar(content: Text('Endereço removido.')),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onAdd;
  const _Empty({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined,
                size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Nenhum endereço cadastrado',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione endereços (Casa, Trabalho…) para alternar entre eles na busca do mapa.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Adicionar primeiro endereço'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAddressScreen extends ConsumerStatefulWidget {
  const _AddAddressScreen();

  @override
  ConsumerState<_AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<_AddAddressScreen> {
  final _labelCtrl = TextEditingController(text: 'Casa');
  final _ctrl = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  bool _saving = false;
  List<_GeoResult> _suggestions = [];
  _GeoResult? _selected;

  @override
  void dispose() {
    _debounce?.cancel();
    _labelCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _fetch(q));
  }

  Future<void> _fetch(String query) async {
    setState(() => _searching = true);
    try {
      final client = HttpClient();
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query.trim(),
        'format': 'json',
        'limit': '6',
        'countrycodes': 'br',
        'addressdetails': '1',
      });
      final req = await client.getUrl(uri);
      req.headers
        ..set(HttpHeaders.userAgentHeader, 'SkillsArena/1.0')
        ..set(HttpHeaders.acceptHeader, 'application/json');
      final res = await req.close();
      final body = await res.transform(const Utf8Decoder()).join();
      client.close();
      if (!mounted) return;
      final list = jsonDecode(body) as List<dynamic>;
      setState(() {
        _suggestions = list.map((e) {
          final m = e as Map<String, dynamic>;
          return _GeoResult(
            displayName: m['display_name'] as String,
            lat: double.parse(m['lat'] as String),
            lon: double.parse(m['lon'] as String),
          );
        }).toList();
        _searching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _save() async {
    if (_selected == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(socialRepositoryProvider).addSavedAddress(
            label: _labelCtrl.text,
            address: _selected!.displayName,
            lat: _selected!.lat,
            lng: _selected!.lon,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Endereço salvo.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Novo endereço')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _labelCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome do endereço',
                hintText: 'Casa, Trabalho, Faculdade…',
                prefixIcon: Icon(Icons.bookmark_outline_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              decoration: InputDecoration(
                labelText: 'Buscar endereço',
                hintText: 'Rua, bairro, cidade…',
                prefixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            if (_suggestions.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = _suggestions[i];
                    final selected = _selected == r;
                    return ListTile(
                      leading: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.location_on_outlined,
                        color: selected ? cs.primary : null,
                      ),
                      title: Text(
                        r.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () => setState(() => _selected = r),
                    );
                  },
                ),
              )
            else if (_selected != null) ...[
              Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: cs.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Endereço selecionado',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: cs.onPrimaryContainer),
                            ),
                            Text(
                              _selected!.displayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onPrimaryContainer),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ] else
              const Spacer(),
            FilledButton.icon(
              onPressed: (_selected == null || _saving) ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: const Text('Salvar endereço'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeoResult {
  final String displayName;
  final double lat;
  final double lon;

  const _GeoResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  @override
  bool operator ==(Object other) =>
      other is _GeoResult && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);
}
