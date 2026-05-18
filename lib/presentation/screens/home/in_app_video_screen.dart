import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../data/models/post_model.dart';

/// Reproduz vídeos dentro do app — sem abrir Chrome / YouTube / TikTok.
///   * YouTube → `youtube_player_flutter` (oficial, iframe player)
///   * TikTok / qualquer link de vídeo → `webview_flutter`
///
/// Para links que o webview não consegue tocar embutido (alguns TikToks
/// forçam "abrir no app"), oferecemos um botão de fallback que usa o
/// `url_launcher` antigo.
class InAppVideoScreen extends StatefulWidget {
  final PostModel post;
  const InAppVideoScreen({super.key, required this.post});

  @override
  State<InAppVideoScreen> createState() => _InAppVideoScreenState();
}

class _InAppVideoScreenState extends State<InAppVideoScreen> {
  YoutubePlayerController? _ytCtrl;
  WebViewController? _webCtrl;
  bool _isYouTube = false;

  @override
  void initState() {
    super.initState();
    _isYouTube = widget.post.type == PostType.youtube;
    if (_isYouTube) {
      final id = widget.post.youtubeVideoId;
      if (id != null) {
        _ytCtrl = YoutubePlayerController(
          initialVideoId: id,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            enableCaption: true,
          ),
        );
      }
    } else {
      // TikTok / link genérico → WebView
      _webCtrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..loadRequest(Uri.parse(widget.post.content));
    }
  }

  @override
  void dispose() {
    _ytCtrl?.dispose();
    super.dispose();
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(widget.post.content);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.post.userName;
    final caption = widget.post.caption ?? '';

    Widget player;
    if (_isYouTube && _ytCtrl != null) {
      player = YoutubePlayer(
        controller: _ytCtrl!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        bottomActions: const [
          CurrentPosition(),
          ProgressBar(isExpanded: true),
          RemainingDuration(),
          FullScreenButton(),
        ],
      );
    } else if (_webCtrl != null) {
      player = WebViewWidget(controller: _webCtrl!);
    } else {
      player = const Center(
        child: Text('Vídeo inválido', style: TextStyle(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Abrir no app externo',
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: _openExternal,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isYouTube)
            player
          else
            Expanded(child: player),
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(caption,
                  style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
