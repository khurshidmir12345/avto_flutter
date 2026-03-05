import 'package:flutter/material.dart';
import '../../models/conversation_model.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'chat_detail_screen.dart';

/// Yangi chat — foydalanuvchini qidirish va chat boshlash.
class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _chatService = ChatService();
  final _searchController = TextEditingController();

  List<ChatUserModel> _users = [];
  bool _loading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _users = []);
      return;
    }

    setState(() => _loading = true);
    final list = await _chatService.searchUsers(q.trim());
    if (mounted) {
      setState(() {
        _users = list;
        _loading = false;
      });
    }
  }

  Future<void> _startChat(ChatUserModel user) async {
    final result = await _chatService.createConversation(user.id);
    if (!mounted) return;

    if (result.success && result.conversation != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: result.conversation!.id,
            otherUser: user,
          ),
        ),
      );
    } else {
      showSnackBar(context, 'Chat ochilmadi', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi chat'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ism yoki telefon raqam',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              autofocus: true,
              onChanged: (v) => _search(v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.trim().length < 2
                              ? 'Qidirish uchun kamida 2 ta belgi yozing'
                              : 'Foydalanuvchi topilmadi',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (_, i) {
                          final u = _users[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                              backgroundImage: u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                                  ? NetworkImage(u.avatarUrl!)
                                  : null,
                              child: u.avatarUrl == null || u.avatarUrl!.isEmpty
                                  ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                                      style: TextStyle(color: AppColors.primary))
                                  : null,
                            ),
                            title: Text(u.name),
                            subtitle: Text(formatPhone(u.phone)),
                            onTap: () => _startChat(u),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
