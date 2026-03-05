import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../models/conversation_model.dart';
import '../../models/conversation_message_model.dart';
import '../../services/api_service.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/auth_network_image.dart';

/// Chat oynasi — matn, rasm, ovozli xabar. Telegram uslubi.
class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  final int conversationId;
  final ChatUserModel otherUser;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _chatService = ChatService();
  final _apiService = ApiService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  List<ConversationMessageModel> _messages = [];
  int? _currentUserId;
  bool _loading = true;
  bool _sending = false;
  bool _recording = false;
  final _recorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _load();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _apiService.getCurrentUser();
    if (mounted) setState(() => _currentUserId = user?.id);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _chatService.getMessages(widget.conversationId);
    if (mounted) {
      setState(() {
        _messages = list.reversed.toList();
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;

    _textController.clear();
    setState(() => _sending = true);

    final result = await _chatService.sendText(widget.conversationId, text);

    if (mounted) {
      setState(() => _sending = false);
      if (result.success && result.message != null) {
        setState(() => _messages.add(result.message!));
        _scrollToBottom();
      } else {
        showSnackBar(context, 'Xabar yuborilmadi', isError: true);
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_sending) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _sending = true);
    final result = await _chatService.sendImage(widget.conversationId, picked.path);

    if (mounted) {
      setState(() => _sending = false);
      if (result.success && result.message != null) {
        setState(() => _messages.add(result.message!));
        _scrollToBottom();
      } else {
        showSnackBar(context, 'Rasm yuborilmadi', isError: true);
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_sending) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) showSnackBar(context, 'Mikrofon ruxsati kerak', isError: true);
      return;
    }

    if (_recording) {
      final path = await _recorder.stop();
      if (path != null && mounted) {
        setState(() => _sending = true);
        final result = await _chatService.sendVoice(widget.conversationId, path);
        if (mounted) {
          setState(() => _sending = false);
          if (result.success && result.message != null) {
            setState(() => _messages.add(result.message!));
            _scrollToBottom();
          }
        }
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      setState(() => _recording = false);
    } else {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100), path: path);
      if (mounted) setState(() => _recording = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
              backgroundImage: widget.otherUser.avatarUrl != null && widget.otherUser.avatarUrl!.isNotEmpty
                  ? NetworkImage(widget.otherUser.avatarUrl!)
                  : null,
              child: widget.otherUser.avatarUrl == null || widget.otherUser.avatarUrl!.isEmpty
                  ? Text(
                      widget.otherUser.name.isNotEmpty ? widget.otherUser.name[0].toUpperCase() : '?',
                      style: TextStyle(color: AppColors.primary, fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUser.name, style: const TextStyle(fontSize: 16)),
                  Text(
                    formatPhone(widget.otherUser.phone),
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Xabar yuborishni boshlang',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _messageBubble(_messages[i], _currentUserId ?? 0),
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _messageBubble(ConversationMessageModel msg, int currentUserId) {
    final isMe = msg.senderId == currentUserId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: _buildMessageContent(msg, isMe),
      ),
    );
  }

  Widget _buildMessageContent(ConversationMessageModel msg, bool isMe) {
    if (msg.isImage && msg.mediaUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AuthNetworkImage(
              url: msg.mediaUrl!,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorWidget: const Icon(Icons.broken_image, size: 48),
            ),
          ),
          if (msg.body != null && msg.body!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(msg.body!, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
          ],
        ],
      );
    }

    if (msg.isVoice && msg.mediaUrl != null) {
      return _VoiceMessagePlayer(url: msg.mediaUrl!, isMe: isMe);
    }

    return Text(
      msg.body ?? '',
      style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image, color: AppColors.primary),
            onPressed: _sending ? null : _pickAndSendImage,
            tooltip: 'Rasm',
          ),
          IconButton(
            icon: Icon(
              _recording ? Icons.stop : Icons.mic,
              color: _recording ? AppColors.error : AppColors.primary,
            ),
            onPressed: _sending ? null : _toggleRecording,
            tooltip: _recording ? 'To\'xtatish' : 'Ovozli xabar',
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Xabar yozing...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendText(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _sending
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.send, color: AppColors.primary),
            onPressed: _sending ? null : _sendText,
            tooltip: 'Yuborish',
          ),
        ],
      ),
    );
  }
}

class _VoiceMessagePlayer extends StatefulWidget {
  const _VoiceMessagePlayer({required this.url, required this.isMe});

  final String url;
  final bool isMe;

  @override
  State<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.stop();
    } else {
      await _player.play(UrlSource(widget.url));
    }
    setState(() => _playing = !_playing);
  }

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
    _player.onPlayerStateChanged.listen((state) {
      if (mounted && state == PlayerState.stopped) setState(() => _playing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _togglePlay,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _playing ? Icons.stop : Icons.play_arrow,
            color: widget.isMe ? Colors.white : Colors.black54,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            _playing ? 'To\'xtatish' : 'Ovozli xabar',
            style: TextStyle(
              color: widget.isMe ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
