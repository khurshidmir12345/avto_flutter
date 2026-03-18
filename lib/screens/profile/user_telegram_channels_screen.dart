import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../config/routes.dart';
import '../../models/user_telegram_channel_model.dart';
import '../../services/telegram_channel_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class UserTelegramChannelsScreen extends StatefulWidget {
  const UserTelegramChannelsScreen({super.key});

  @override
  State<UserTelegramChannelsScreen> createState() =>
      _UserTelegramChannelsScreenState();
}

class _UserTelegramChannelsScreenState
    extends State<UserTelegramChannelsScreen> {
  final _service = TelegramChannelApiService();
  List<UserTelegramChannelModel> _channels = [];
  int _maxChannels = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getUserChannels();
    if (mounted) {
      setState(() {
        _channels = result.channels;
        _maxChannels = result.maxChannels;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteChannel(UserTelegramChannelModel channel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Kanalni o'chirish"),
        content: Text(
          "'${channel.channelName ?? channel.chatId}' kanali o'chiriladi. Davom etasizmi?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("O'chirish", style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final result = await _service.deleteUserChannel(channel.id);
    if (!mounted) return;
    showSnackBar(context, result.message, isError: !result.success);
    if (result.success) _load();
  }

  Future<void> _testChannel(UserTelegramChannelModel channel) async {
    showSnackBar(context, 'Test xabar yuborilmoqda...');
    final result = await _service.testUserChannel(channel.id);
    if (!mounted) return;
    showSnackBar(context, result.message, isError: !result.success);
    if (result.success) _load();
  }

  Future<void> _toggleActive(UserTelegramChannelModel channel) async {
    final result = await _service.updateUserChannel(
      id: channel.id,
      isActive: !channel.isActive,
    );
    if (!mounted) return;
    showSnackBar(context, result.message, isError: !result.success);
    if (result.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddMore = _channels.length < _maxChannels;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Kanallar'),
        actions: [
          if (canAddMore)
            IconButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.userTelegramChannelSetup,
              ).then((_) => _load()),
              icon: const PhosphorIcon(PhosphorIconsRegular.plus),
              tooltip: 'Kanal qo\'shish',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _channels.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildChannelsList(theme, canAddMore),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              "Telegram kanalingizni ulang",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "E'lonlaringiz avtomatik ravishda Telegram kanalingizga joylanadi. "
              "Kanal yurituvchilar uchun juda qulay!",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildFeatureItem(
              theme,
              PhosphorIconsRegular.robot,
              "Avtomatik joylanadi",
              "E'lon yaratganingizda kanalingizga yuboriladi",
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              theme,
              PhosphorIconsRegular.textT,
              "Xabar shablonini sozlang",
              "E'lon matni qanday ko'rinishini o'zingiz belgilaysiz",
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              theme,
              PhosphorIconsRegular.stack,
              "5 tagacha kanal",
              "Bir nechta kanalga bir vaqtda yuborish mumkin",
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.userTelegramChannelSetup,
                ).then((_) => _load()),
                icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 20),
                label: const Text("Kanal qo'shish"),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: PhosphorIcon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsList(ThemeData theme, bool canAddMore) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                PhosphorIcon(PhosphorIconsRegular.info, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "E'lon yaratganingizda avtomatik ravishda kanallaringizga yuboriladi",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Kanallar (${_channels.length}/$_maxChannels)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._channels.map((ch) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildChannelCard(theme, ch),
              )),
          if (canAddMore) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.userTelegramChannelSetup,
                ).then((_) => _load()),
                icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 18),
                label: const Text("Kanal qo'shish"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelCard(ThemeData theme, UserTelegramChannelModel channel) {
    final hasError = channel.hasError;
    final borderColor = hasError
        ? AppColors.error.withValues(alpha: 0.3)
        : channel.isActive
            ? AppColors.success.withValues(alpha: 0.2)
            : theme.colorScheme.outlineVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0088CC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.send_rounded, size: 18, color: Color(0xFF0088CC)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.channelName ?? 'Kanal',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (channel.channelUsername != null)
                      Text(
                        '@${channel.channelUsername}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF0088CC),
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: channel.isActive,
                onChanged: (_) => _toggleActive(channel),
                activeColor: AppColors.success,
              ),
            ],
          ),
          if (hasError) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.warning,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      channel.lastErrorMessage ?? 'Xatolik yuz berdi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _buildActionButton(
                theme,
                icon: PhosphorIconsRegular.paperPlaneTilt,
                label: 'Test',
                onTap: () => _testChannel(channel),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                theme,
                icon: PhosphorIconsRegular.pencil,
                label: 'Tahrirlash',
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.userTelegramChannelSetup,
                  arguments: channel,
                ).then((_) => _load()),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                theme,
                icon: PhosphorIconsRegular.trash,
                label: "O'chirish",
                color: AppColors.error,
                onTap: () => _deleteChannel(channel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? AppColors.primary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(icon, size: 14, color: c),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: c,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
