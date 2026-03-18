import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../services/moderation_service.dart';
import '../../utils/constants.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _moderationService = ModerationService();
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _moderationService.getBlockedUsers();
    if (mounted) {
      setState(() {
        _blockedUsers = list;
        _loading = false;
      });
    }
  }

  Future<void> _unblock(int userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Blokdan chiqarish'),
        content: Text('"$userName" ni blokdan chiqarasizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Blokdan chiqarish'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await _moderationService.unblockUser(userId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
      ),
    );

    if (result.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bloklangan foydalanuvchilar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.shieldCheck,
                        size: 64,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bloklangan foydalanuvchilar yo\'q',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _blockedUsers.length,
                    itemBuilder: (_, i) => _buildTile(_blockedUsers[i]),
                  ),
                ),
    );
  }

  Widget _buildTile(Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final name = user['name'] as String? ?? 'Noma\'lum';
    final phone = user['phone'] as String? ?? '';
    final userId = user['id'] as int;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.error.withValues(alpha: 0.1),
        child: Icon(Icons.block, color: AppColors.error, size: 22),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: phone.isNotEmpty
          ? Text(phone, style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
          : null,
      trailing: TextButton(
        onPressed: () => _unblock(userId, name),
        child: Text(
          'Blokdan chiqarish',
          style: TextStyle(color: AppColors.primary, fontSize: 13),
        ),
      ),
    );
  }
}
