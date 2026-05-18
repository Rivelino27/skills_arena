import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../providers/chat_provider.dart';
import '../explore/map_screen.dart';
import '../profile/user_profile_screen.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).markAsRead(widget.chatId);
    });
  }

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

  Future<void> _shareLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      if (!serviceEnabled) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Ative o GPS para compartilhar localização.')));
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Permissão de localização negada.')));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      ).timeout(const Duration(seconds: 10),
          onTimeout: () => throw 'GPS demorou para responder');
      await ref.read(chatRepositoryProvider).sendLocationMessage(
            chatId: widget.chatId,
            lat: pos.latitude,
            lng: pos.longitude,
          );
      _scrollToBottom();
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Erro ao obter localização: $e')));
    }
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
    // Em chat 1-1, tocar no header abre o perfil do outro. Grupos
    // (chat de quadra/dia/slot) não têm um "outro user" único.
    final isOneToOne = !widget.conv.isGroup;
    final otherUid = widget.conv.otherUid(widget.myUid);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: isOneToOne
              ? () => AppNavigator.pushWithNavBar(
                  context, UserProfileScreen(userId: otherUid))
              : null,
          child: Row(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, overflow: TextOverflow.ellipsis),
                    if (isOneToOne)
                      Text(
                        'Toque para ver perfil',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.65),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
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
                // Keep marking as read while screen is open and new
                // messages arrive.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref
                      .read(chatRepositoryProvider)
                      .markAsRead(widget.chatId);
                });
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _Bubble(
                    msg: msgs[i],
                    isMe: msgs[i].senderId == widget.myUid,
                    myUid: widget.myUid,
                    chatId: widget.chatId,
                    onReact: (emoji) => ref
                        .read(chatRepositoryProvider)
                        .toggleReaction(
                          chatId: widget.chatId,
                          messageId: msgs[i].id,
                          emoji: emoji,
                        ),
                    showName: msgs.length > 1 &&
                        i > 0 &&
                        msgs[i].senderId != msgs[i - 1].senderId,
                  ),
                );
              },
            ),
          ),
          _MessageInput(
            controller: _msgCtrl,
            onSend: _send,
            onShareLocation: _shareLocation,
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final String myUid;
  final String chatId;
  final ValueChanged<String> onReact;
  final bool showName;

  const _Bubble({
    required this.msg,
    required this.isMe,
    required this.myUid,
    required this.chatId,
    required this.onReact,
    this.showName = false,
  });

  Future<void> _showReactionPicker(BuildContext context) async {
    final myReaction = msg.reactionFor(myUid);
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: kReactionEmojis.map((e) {
                  final selected = e == myReaction;
                  return InkResponse(
                    onTap: () => Navigator.of(ctx).pop(e),
                    radius: 28,
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(ctx)
                                .colorScheme
                                .primaryContainer
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) onReact(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final time =
        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    final isLocation =
        msg.type == MessageType.location && msg.lat != null && msg.lng != null;
    final hasReactions = msg.reactions.isNotEmpty;
    final myReaction = msg.reactionFor(myUid);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _showReactionPicker(context),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 9),
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
                  if (isLocation) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: isMe ? cs.onPrimary : cs.primary,
                            size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Localização',
                          style: TextStyle(
                            color: isMe ? cs.onPrimary : cs.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FilledButton.tonalIcon(
                      onPressed: () => AppNavigator.pushWithNavBar(
                        context,
                        MapScreen(
                          initialLat: msg.lat,
                          initialLng: msg.lng,
                          initialZoom: 16.0,
                        ),
                      ),
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('Ver no mapa'),
                    ),
                  ] else
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
          ),
          if (hasReactions)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Wrap(
                spacing: 4,
                children: msg.reactions.entries.map((e) {
                  final isMine = e.key == myReaction;
                  return InkWell(
                    onTap: () => onReact(e.key),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMine
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isMine
                              ? cs.primary.withValues(alpha: 0.5)
                              : cs.outlineVariant,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.key,
                              style: const TextStyle(fontSize: 14)),
                          if (e.value.length > 1) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${e.value.length}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onShareLocation;

  const _MessageInput({
    required this.controller,
    required this.onSend,
    required this.onShareLocation,
  });

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
            IconButton(
              tooltip: 'Compartilhar localização',
              onPressed: onShareLocation,
              icon: Icon(Icons.location_on_outlined, color: cs.primary),
            ),
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
