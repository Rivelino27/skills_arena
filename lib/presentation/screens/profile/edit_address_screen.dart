import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/social_repository.dart';
import '../../providers/user_provider.dart';

/// Lets the user pick a fixed home/work address. Searched via Nominatim.
/// Saved coords are then used as the public pin location for the user.
class EditAddressScreen extends ConsumerStatefulWidget {
  const EditAddressScreen({super.key});

  @override
  ConsumerState<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends ConsumerState<EditAddressScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  bool _saving = false;
  List<_GeoResult> _suggestions = [];
  _GeoResult? _selected;

  @override
  void initState() {
    super.initState();
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me?.address != null) {
      _ctrl.text = me!.address!;
      if (me.addressLat != null && me.addressLng != null) {
        _selected = _GeoResult(
          displayName: me.address!,
          lat: me.addressLat!,
          lon: me.addressLng!,
        );
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
    setState(() => _saving = true);
    await ref.read(socialRepositoryProvider).setFixedAddress(
          address: _selected!.displayName,
          lat: _selected!.lat,
          lng: _selected!.lon,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Endereço salvo.')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    await ref.read(socialRepositoryProvider).setFixedAddress();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _selected = null;
      _ctrl.clear();
      _suggestions = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Endereço removido.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final me = ref.watch(currentUserProvider).valueOrNull;
    final hasSaved = me?.address != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu endereço'),
        actions: [
          if (hasSaved)
            IconButton(
              tooltip: 'Remover endereço',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _saving ? null : _clear,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Outros usuários verão sua localização aproximada com base '
              'neste endereço fixo. A localização real do GPS só é '
              'compartilhada dentro de uma conversa, e somente se você '
              'autorizar.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
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
                              hasSaved
                                  ? 'Endereço salvo'
                                  : 'Endereço selecionado',
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
                            const SizedBox(height: 4),
                            Text(
                              '${_selected!.lat.toStringAsFixed(5)}, '
                              '${_selected!.lon.toStringAsFixed(5)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onPrimaryContainer),
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
              onPressed:
                  (_selected == null || _saving) ? null : _save,
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
