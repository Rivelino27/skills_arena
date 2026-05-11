import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/sports_venue_model.dart';
import '../../../data/repositories/sports_repository.dart';
import '../../widgets/navigation/custom_back_button.dart';

/// Tela de adicionar quadra — bottom nav bar visível (pushWithNavBar).
class AddVenueScreen extends ConsumerStatefulWidget {
  final double? userLat;
  final double? userLng;
  /// Reverse-geocoded address from the pin. Pre-fills the address field
  /// so the user doesn't have to type it.
  final String? initialAddress;

  const AddVenueScreen({
    super.key,
    this.userLat,
    this.userLng,
    this.initialAddress,
  });

  @override
  ConsumerState<AddVenueScreen> createState() => _AddVenueScreenState();
}

class _AddVenueScreenState extends ConsumerState<AddVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();
  String _selectedSport = kSportsList.first;
  bool _isPublic = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _addressCtrl.text = widget.initialAddress!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _complementCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.userLat == null || widget.userLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Localização indisponível. Ative o GPS e tente novamente.')),
      );
      return;
    }
    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser!;
    final venue = SportsVenueModel(
      id: '',
      name: _nameCtrl.text.trim(),
      sport: _selectedSport,
      lat: widget.userLat!,
      lng: widget.userLng!,
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      complement: _complementCtrl.text.trim().isEmpty
          ? null
          : _complementCtrl.text.trim(),
      addedBy: user.uid,
      addedByName: user.displayName ?? 'Usuário',
      isPublic: _isPublic,
      createdAt: DateTime.now(),
    );

    final result = await ref.read(sportsRepositoryProvider).addVenue(venue);
    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(f.message),
            backgroundColor: Theme.of(context).colorScheme.error),
      ),
      (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: CustomBackButton(
            options: [
              BackMenuOption(
                icon: Icons.map_rounded,
                label: 'Voltar ao mapa',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          title: const Text('Adicionar Quadra'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Localização
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: cs.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Localização atual',
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(color: cs.onSurfaceVariant)),
                              Text(
                                widget.userLat != null
                                    ? '${widget.userLat!.toStringAsFixed(5)}, '
                                        '${widget.userLng!.toStringAsFixed(5)}'
                                    : 'GPS indisponível',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          widget.userLat != null
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          color: widget.userLat != null
                              ? Colors.green
                              : cs.error,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Nome
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome da quadra / local',
                    prefixIcon: Icon(Icons.place_rounded),
                    hintText: 'Ex: Quadra do Parque Central',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),

                // Esporte
                DropdownButtonFormField<String>(
                  initialValue: _selectedSport,
                  decoration: const InputDecoration(
                    labelText: 'Esporte',
                    prefixIcon: Icon(Icons.sports_rounded),
                  ),
                  items: kSportsList
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSport = v!),
                ),
                const SizedBox(height: 16),

                // Endereço (pré-preenchido pelo pin no mapa)
                TextFormField(
                  controller: _addressCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Endereço',
                    prefixIcon: Icon(Icons.home_outlined),
                    hintText: 'Rua, número, bairro…',
                    helperText: 'Detectado do pin — edite se necessário',
                  ),
                ),
                const SizedBox(height: 12),

                // Complemento (referência / portão / quadra X)
                TextFormField(
                  controller: _complementCtrl,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Complemento (opcional)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                    hintText: 'Ex: Portão azul, quadra 2, atrás do mercado…',
                  ),
                ),
                const SizedBox(height: 20),

                // Público / privado
                Text('Tipo de acesso',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.public_rounded),
                      label: Text('Público'),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.lock_outline_rounded),
                      label: Text('Privado'),
                    ),
                  ],
                  selected: {_isPublic},
                  onSelectionChanged: (s) =>
                      setState(() => _isPublic = s.first),
                ),
                const SizedBox(height: 32),

                FilledButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Salvar quadra'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
