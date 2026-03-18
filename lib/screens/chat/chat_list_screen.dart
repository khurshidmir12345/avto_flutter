import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/conversation_model.dart';
import '../../services/chat_service.dart';
import '../../services/moderation_service.dart';
import '../../utils/constants.dart';
import '../../widgets/report_bottom_sheet.dart';
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
                  icon: PhosphorIcon(PhosphorIconsRegular.userPlus),
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
              heroTag: 'chat_fab',
              onPressed: () async {
                final conv = await Navigator.push<ConversationModel>(
                  context,
                  MaterialPageRoute(builder: (_) => const NewChatScreen()),
                );
                if (conv != null && mounted) _load();
              },
              child: PhosphorIcon(PhosphorIconsRegular.userPlus),
              tooltip: 'Yangi chat',
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? RefreshIndicator(
                  onRefresh: _load,
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: _emptyState(context),
                      ),
                    ),
                  ),
                )
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
            PhosphorIcon(PhosphorIconsRegular.chatCircle, size: 72, color: AppColors.primaryLight),
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
    final hasUnread = conv.unreadCount > 0;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: conv.id,
            otherUser: user,
          ),
        ),
      ).then((_) => _load()),
      onLongPress: () => _showChatActions(conv),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
              backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(color: AppColors.primary, fontSize: 20),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (conv.lastMessageAt != null)
                        Text(
                          _formatTime(conv.lastMessageAt!),
                          style: TextStyle(
                            color: hasUnread ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(minWidth: 22),
                          child: Text(
                            conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatActions(ConversationModel conv) {
    final user = conv.otherUser;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                title: const Text('Shikoyat qilish'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  ReportBottomSheet.show(
                    context,
                    reportableType: 'user',
                    reportableId: user.id,
                    title: 'Foydalanuvchiga shikoyat',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Foydalanuvchini bloklash'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _blockUserFromList(user);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _blockUserFromList(ChatUserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Foydalanuvchini bloklash'),
        content: Text(
          '"${user.name}" ni bloklaysizmi?\n\nBloklangan foydalanuvchi chatlar ro\'yxatidan yo\'qoladi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Bloklash'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await ModerationService().blockUser(user.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
      ),
    );

    if (result.success) _load();
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
