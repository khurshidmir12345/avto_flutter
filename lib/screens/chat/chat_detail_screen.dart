import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../models/conversation_model.dart';
import '../../models/conversation_message_model.dart';
import '../../services/api_service.dart';
import '../../services/chat_service.dart';
import '../../services/media_cache_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/auth_network_image.dart';
import '../../widgets/full_screen_image_viewer.dart';

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
    _textController.addListener(_onTextChanged);
    _loadCurrentUser();
    _load();
  }

  void _onTextChanged() => setState(() {});

  Future<void> _loadCurrentUser() async {
    final user = await _apiService.getCurrentUser();
    if (mounted) setState(() => _currentUserId = user?.id);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
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
                  ? CachedNetworkImageProvider(widget.otherUser.avatarUrl!)
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
                  Text(
                    widget.otherUser.name,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    formatPhone(widget.otherUser.phone),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otherBubbleColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : otherBubbleColor,
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
          GestureDetector(
            onTap: () => FullScreenImageViewer.show(
              context,
              urls: [msg.mediaUrl!],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AuthNetworkImage(
                url: msg.mediaUrl!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorWidget: PhosphorIcon(PhosphorIconsRegular.imageBroken, size: 48),
              ),
            ),
          ),
          if (msg.body != null && msg.body!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              msg.body!,
              style: TextStyle(
                color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ],
      );
    }

    if (msg.isVoice && msg.mediaUrl != null) {
      final fg = isMe ? Colors.white : Theme.of(context).colorScheme.onSurface;
      return _VoiceMessagePlayer(
        url: msg.mediaUrl!,
        isMe: isMe,
        foregroundColor: fg,
        createdAt: msg.createdAt,
      );
    }

    return Text(
      msg.body ?? '',
      style: TextStyle(
        color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
      ),
    );
  }

  Widget _buildInputBar() {
    final hasText = _textController.text.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fieldColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: barColor,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildCircleButton(
            icon: PhosphorIconsRegular.paperclip,
            onPressed: _sending ? null : _pickAndSendImage,
            tooltip: 'Rasm',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Xabar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: fieldColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendText(),
            ),
          ),
          const SizedBox(width: 8),
          if (hasText)
            _buildCircleButton(
              icon: PhosphorIconsRegular.paperPlaneRight,
              onPressed: _sending ? null : _sendText,
              tooltip: 'Yuborish',
              isPrimary: true,
              loading: _sending,
            )
          else
            _buildCircleButton(
              icon: _recording ? PhosphorIconsRegular.stop : PhosphorIconsRegular.microphone,
              onPressed: _sending ? null : _toggleRecording,
              tooltip: _recording ? 'To\'xtatish' : 'Ovozli xabar',
              isRecording: _recording,
            ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    VoidCallback? onPressed,
    required String tooltip,
    bool isPrimary = false,
    bool loading = false,
    bool isRecording = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isRecording
                ? AppColors.error.withValues(alpha: 0.15)
                : isPrimary
                    ? AppColors.primary
                    : defaultBg,
            shape: BoxShape.circle,
          ),
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                )
              : PhosphorIcon(
                  icon,
                  size: 22,
                  color: isPrimary || isRecording
                      ? (isRecording ? AppColors.error : Colors.white)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }
}

class _VoiceMessagePlayer extends StatefulWidget {
  const _VoiceMessagePlayer({
    required this.url,
    required this.isMe,
    required this.foregroundColor,
    this.createdAt,
  });

  final String url;
  final bool isMe;
  final Color foregroundColor;
  final String? createdAt;

  @override
  State<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  final _player = AudioPlayer();
  bool _playing = false;
  String? _cachedPath;
  bool _loading = false;
  bool _error = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  String get _formatTime => '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}';

  String _formatCreatedAt(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final min = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$min $ampm';
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCached();
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    });
    _player.onPlayerStateChanged.listen((state) {
      if (mounted && state == PlayerState.stopped) setState(() => _playing = false);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  Future<void> _loadCached() async {
    setState(() => _loading = true);
    final path = await MediaCacheService.instance.getCachedPath(
      widget.url,
      forceExtension: 'm4a',
    );
    if (mounted) {
      setState(() {
        _cachedPath = path;
        _loading = false;
        _error = path == null;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_loading) return;

    if (_error) {
      await _loadCached();
      if (_error) return;
    }

    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }

    try {
      if (_cachedPath != null) {
        final file = File(_cachedPath!);
        if (await file.exists() && await file.length() > 0) {
          await _player.play(DeviceFileSource(_cachedPath!));
          if (mounted) setState(() => _playing = true);
        } else {
          if (mounted) setState(() => _error = true);
        }
      } else if (!widget.url.contains('/api/chat/media/')) {
        await _player.play(UrlSource(widget.url));
        if (mounted) setState(() => _playing = true);
      } else {
        if (mounted) setState(() => _error = true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.foregroundColor;
    final fgSecondary = fg.withValues(alpha: 0.8);

    return InkWell(
      onTap: _loading ? null : _togglePlay,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: _loading
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                      ),
                    )
                  : PhosphorIcon(
                      _playing ? PhosphorIconsRegular.pause : PhosphorIconsRegular.play,
                      color: fg,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWaveform(fg),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _playing ? _formatTime : (_duration.inSeconds > 0 ? '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}' : '0:00'),
                      style: TextStyle(fontSize: 12, color: fgSecondary),
                    ),
                    if (widget.createdAt != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        _formatCreatedAt(widget.createdAt),
                        style: TextStyle(fontSize: 11, color: fgSecondary),
                      ),
                      const SizedBox(width: 4),
                      PhosphorIcon(PhosphorIconsRegular.checks, size: 14, color: fgSecondary),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform(Color color) {
    const barCount = 24;
    final baseHeights = List.generate(barCount, (i) {
      final r = (i * 13) % 5 + 2;
      return 6.0 + r * 2.5;
    });

    return SizedBox(
      height: 28,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (i) {
          final offset = _playing ? ((_position.inMilliseconds ~/ 80) + i) % 5 : 0;
          final h = baseHeights[(i + offset) % barCount];
          return Container(
            width: 2.5,
            height: h.clamp(4.0, 22.0),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
}
