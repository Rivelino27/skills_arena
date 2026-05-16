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
  final _numberCtrl = TextEditingController();
  Timer? _debounce;
  Timer? _numberDebounce;
  bool _searching = false;
  bool _saving = false;
  List<_GeoResult> _suggestions = [];
  _GeoResult? _selected;
  _CepData? _cepData;

  @override
  void dispose() {
    _debounce?.cancel();
    _numberDebounce?.cancel();
    _labelCtrl.dispose();
    _ctrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    final digits = q.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) {
      _debounce =
          Timer(const Duration(milliseconds: 300), () => _fetchCep(digits));
      return;
    }
    // Sair do modo CEP se o usuário começar a digitar livremente
    if (_cepData != null) {
      setState(() {
        _cepData = null;
        _numberCtrl.clear();
        _selected = null;
      });
    }
    if (q.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _fetch(q));
  }

  void _onNumberChanged(String v) {
    _numberDebounce?.cancel();
    _numberDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _cepData == null) return;
      _resolveAddressForCep(v.trim());
    });
  }

  Future<void> _fetchCep(String cep) async {
    setState(() => _searching = true);
    try {
      final client = HttpClient();
      final uri = Uri.https('viacep.com.br', '/ws/$cep/json/');
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'SkillsArena/1.0');
      final res = await req.close();
      final body = await res.transform(const Utf8Decoder()).join();
      client.close();
      if (!mounted) return;
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data.containsKey('erro')) {
        setState(() => _searching = false);
        return;
      }
      final info = _CepData(
        street: data['logradouro'] as String? ?? '',
        neighborhood: data['bairro'] as String? ?? '',
        city: data['localidade'] as String? ?? '',
        state: data['uf'] as String? ?? '',
      );
      setState(() {
        _cepData = info;
        _suggestions = [];
      });
      await _resolveAddressForCep('');
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  /// Resolve coords for the current CEP info + optional number.
  /// Tries progressively less specific Nominatim queries so the save
  /// button is always enabled when a valid CEP was found — even if the
  /// precise street isn't in OSM yet, we fall back to city center.
  Future<void> _resolveAddressForCep(String number) async {
    final info = _cepData;
    if (info == null) return;
    final fullAddr = info.assemble(number: number);
    _ctrl.text = fullAddr;
    setState(() {
      _searching = true;
      _suggestions = [];
    });
    final queries = <String>[
      if (number.isNotEmpty && info.street.isNotEmpty)
        '${info.street}, $number, ${info.city}, ${info.state}',
      if (info.street.isNotEmpty)
        '${info.street}, ${info.city}, ${info.state}',
      if (info.neighborhood.isNotEmpty)
        '${info.neighborhood}, ${info.city}, ${info.state}',
      '${info.city}, ${info.state}',
    ];
    _GeoResult? hit;
    for (final q in queries) {
      final r = await _runNominatim(q);
      if (r.isNotEmpty) {
        hit = r.first;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _searching = false;
      if (hit != null) {
        _selected = _GeoResult(
          displayName: fullAddr,
          lat: hit.lat,
          lon: hit.lon,
        );
      }
    });
  }

  Future<List<_GeoResult>> _runNominatim(String query) async {
    try {
      final client = HttpClient();
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query.trim(),
        'format': 'json',
        'limit': '3',
        'countrycodes': 'br',
      });
      final req = await client.getUrl(uri);
      req.headers
        ..set(HttpHeaders.userAgentHeader, 'SkillsArena/1.0')
        ..set(HttpHeaders.acceptHeader, 'application/json');
      final res = await req.close();
      final body = await res.transform(const Utf8Decoder()).join();
      client.close();
      final list = jsonDecode(body) as List<dynamic>;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return _GeoResult(
          displayName: m['display_name'] as String,
          lat: double.parse(m['lat'] as String),
          lon: double.parse(m['lon'] as String),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _fetch(String query, {bool autoSelect = false}) async {
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
      final results = list.map((e) {
        final m = e as Map<String, dynamic>;
        return _GeoResult(
          displayName: m['display_name'] as String,
          lat: double.parse(m['lat'] as String),
          lon: double.parse(m['lon'] as String),
        );
      }).toList();
      setState(() {
        _suggestions = results;
        if (autoSelect && results.isNotEmpty) _selected = results.first;
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
                hintText: 'Rua, bairro, cidade ou CEP…',
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
            if (_cepData != null) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _numberCtrl,
                keyboardType: TextInputType.number,
                onChanged: _onNumberChanged,
                decoration: const InputDecoration(
                  labelText: 'Número (opcional)',
                  hintText: 'Ex: 123',
                  prefixIcon: Icon(Icons.numbers_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (_cepData != null) ...[
              // Modo CEP: mostra o endereço resolvido direto, sem lista.
              if (_selected != null)
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
                                'Endereço resolvido',
                                style: theme.textTheme.labelMedium?.copyWith(
                                    color: cs.onPrimaryContainer),
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
                )
              else if (_searching)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const Spacer(),
            ] else if (_suggestions.isNotEmpty)
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

/// Address parts as returned by ViaCEP (`logradouro`, `bairro`, etc.).
/// Kept around while the user is in "CEP mode" so we can rebuild the
/// search string when they type a number, and so the save button can
/// stay enabled even before Nominatim finds a precise match.
class _CepData {
  final String street;
  final String neighborhood;
  final String city;
  final String state;

  const _CepData({
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  String assemble({String? number}) {
    final parts = <String>[];
    if (street.isNotEmpty) {
      parts.add((number?.isNotEmpty ?? false)
          ? '$street, $number'
          : street);
    }
    if (neighborhood.isNotEmpty) parts.add(neighborhood);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    return parts.join(', ');
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
