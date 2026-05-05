import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/chat_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../providers/chat_provider.dart';

// ─── PADRÃO DE NAVEGAÇÃO ──────────────────────────────────────────────────────
// Aberta via AppNavigator.pushWithNavBar() → bottom nav bar VISÍVEL.
// Usa Navigator.of(context).push() dentro do navigator da aba do Chat,
// então o PersistentTabView permanece na árvore de widgets.
//
// AppBar  : VISÍVEL  (Scaffold normal com AppBar)
// Nav bar : VISÍVEL  (pushWithNavBar — navigator da aba)
//
// Compare com NewConversationScreen que usa pushWithoutNavBar → nav bar OCULTA.
// ─────────────────────────────────────────────────────────────────────────────

class ConversationScreen extends ConsumerStatefulWidget {
  final String chatId;
  final ConversationModel conv;
  final String myUid;

  const ConversationScreen({
    super.key,
    required this.chatId,
    required this.conv,
    required this.myUid,
  });

  @override
  ConsumerState<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await ref
        .read(chatRepositoryProvider)
        .sendMessage(widget.chatId, text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final msgsAsync = ref.watch(messagesStreamProvider(widget.chatId));
    final name = widget.conv.otherName(widget.myUid);
    final photo = widget.conv.otherPhoto(widget.myUid);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  photo != null ? NetworkImage(photo) : null,
              backgroundColor: cs.primaryContainer,
              child: photo == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                          color: cs.onPrimaryContainer, fontSize: 13),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: msgsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (msgs) {
                if (msgs.isEmpty) {
                  return Center(
                    child: Text(
                      'Diga olá para $name! 👋',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  );
                }
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _Bubble(
                    msg: msgs[i],
                    isMe: msgs[i].senderId == widget.myUid,
                    showName: msgs.length > 1 &&
                        i > 0 &&
                        msgs[i].senderId != msgs[i - 1].senderId,
                  ),
                );
              },
            ),
          ),
          _MessageInput(controller: _msgCtrl, onSend: _send),
        ],
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final bool showName;

  const _Bubble(
      {required this.msg, required this.isMe, this.showName = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final time =
        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                  color: isMe ? cs.onPrimary : cs.onSurface,
                  fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(
                color: (isMe ? cs.onPrimary : cs.onSurfaceVariant)
                    .withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInput(
      {required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
              top: BorderSide(color: cs.outlineVariant, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Mensagem...',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
