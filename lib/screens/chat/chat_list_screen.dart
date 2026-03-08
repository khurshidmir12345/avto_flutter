import 'package:flutter/material.dart';
import '../../models/conversation_model.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';
import 'chat_detail_screen.dart';
import 'new_chat_screen.dart';

/// Yozishmalar — Telegram/Messenger uslubida sodda chat ro'yxati.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key, this.onRefresh, this.embeddedInTab = false});

  final VoidCallback? onRefresh;
  /// Tab ichida bo'lsa AppBar ko'rsatilmaydi (MainScreen AppBar ishlatiladi).
  final bool embeddedInTab;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _chatService = ChatService();
  List<ConversationModel> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _chatService.getConversations();
    if (mounted) {
      setState(() {
        _list = list;
        _loading = false;
      });
      widget.onRefresh?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embeddedInTab
          ? null
          : AppBar(
              title: const Text('Yozishmalar'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add_rounded),
                  onPressed: () async {
                    final conv = await Navigator.push<ConversationModel>(
                      context,
                      MaterialPageRoute(builder: (_) => const NewChatScreen()),
                    );
                    if (conv != null && mounted) _load();
                  },
                  tooltip: 'Yangi chat',
                ),
              ],
            ),
      floatingActionButton: widget.embeddedInTab
          ? FloatingActionButton.small(
              onPressed: () async {
                final conv = await Navigator.push<ConversationModel>(
                  context,
                  MaterialPageRoute(builder: (_) => const NewChatScreen()),
                );
                if (conv != null && mounted) _load();
              },
              child: const Icon(Icons.person_add_rounded),
              tooltip: 'Yangi chat',
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? _emptyState(context)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _list.length,
                    itemBuilder: (_, i) => _chatTile(context, _list[i]),
                  ),
                ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 72, color: AppColors.primaryLight),
            const SizedBox(height: 24),
            Text(
              'Hozircha yozishmalar yo\'q',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yuqoridagi + tugmasini bosing va yangi chat boshlang',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatTile(BuildContext context, ConversationModel conv) {
    final user = conv.otherUser;
    final preview = conv.lastMessage?.previewText ?? 'Chat boshlandi';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
        backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
            ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(color: AppColors.primary, fontSize: 20),
              )
            : null,
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      trailing: conv.lastMessageAt != null
          ? Text(
              _formatTime(conv.lastMessageAt!),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            )
          : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: conv.id,
            otherUser: user,
          ),
        ),
      ).then((_) => _load()),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      if (dt.year == now.year) {
        return '${dt.day}.${dt.month}';
      }
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
