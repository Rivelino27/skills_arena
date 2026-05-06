import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/post_model.dart';
import '../../../data/repositories/post_repository.dart';

// ─── PADRÃO DE NAVEGAÇÃO ──────────────────────────────────────────────────────
// Aberta via AppNavigator.pushWithoutNavBar() — bottom nav bar OCULTA.
// AppBar: visível com botão de voltar padrão (sem customização necessária aqui).
// Para ocultar a AppBar: use Scaffold(appBar: null, body: ...).
// ─────────────────────────────────────────────────────────────────────────────

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  PostType _type = PostType.text;
  final _contentCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await ref.read(postRepositoryProvider).addPost(
          type: _type,
          content: _contentCtrl.text,
          caption: _captionCtrl.text.isEmpty ? null : _captionCtrl.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(f.message),
            backgroundColor: Theme.of(context).colorScheme.error),
      ),
      (_) => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Publicação')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tipo de publicação', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<PostType>(
                segments: const [
                  ButtonSegment(
                    value: PostType.text,
                    icon: Icon(Icons.text_fields_rounded),
                    label: Text('Texto'),
                  ),
                  ButtonSegment(
                    value: PostType.youtube,
                    icon: Icon(Icons.smart_display_rounded),
                    label: Text('YouTube'),
                  ),
                  ButtonSegment(
                    value: PostType.tiktok,
                    icon: Icon(Icons.music_video_rounded),
                    label: Text('TikTok'),
                  ),
                  ButtonSegment(
                    value: PostType.link,
                    icon: Icon(Icons.link_rounded),
                    label: Text('Link'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) =>
                    setState(() => _type = s.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _contentCtrl,
                maxLines: _type == PostType.text ? 6 : 1,
                keyboardType: _type == PostType.text
                    ? TextInputType.multiline
                    : TextInputType.url,
                decoration: InputDecoration(
                  labelText: _label,
                  hintText: _hint,
                  prefixIcon: Icon(_icon),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              if (_type != PostType.text)
                TextFormField(
                  controller: _captionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Legenda (opcional)',
                    hintText: 'Adicione uma descrição...',
                    prefixIcon: Icon(Icons.comment_rounded),
                  ),
                ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text('Publicar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _label {
    switch (_type) {
      case PostType.text:
        return 'Texto';
      case PostType.youtube:
        return 'URL do YouTube';
      case PostType.tiktok:
        return 'URL do TikTok';
      case PostType.link:
        return 'URL do link';
    }
  }

  String get _hint {
    switch (_type) {
      case PostType.text:
        return 'O que você quer compartilhar?';
      case PostType.youtube:
        return 'https://youtube.com/watch?v=...';
      case PostType.tiktok:
        return 'https://www.tiktok.com/@usuario/video/...';
      case PostType.link:
        return 'https://...';
    }
  }

  IconData get _icon {
    switch (_type) {
      case PostType.text:
        return Icons.text_fields_rounded;
      case PostType.youtube:
        return Icons.smart_display_rounded;
      case PostType.tiktok:
        return Icons.music_video_rounded;
      case PostType.link:
        return Icons.link_rounded;
    }
  }
}
