import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class TelegramLinkScreen extends StatefulWidget {
  const TelegramLinkScreen({super.key});

  @override
  State<TelegramLinkScreen> createState() => _TelegramLinkScreenState();
}

class _TelegramLinkScreenState extends State<TelegramLinkScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  bool _isUnlinking = false;
  UserModel? _user;
  String? _botLink;
  String? _botUsername;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _apiService.getCurrentUser(),
      _apiService.getTelegramLinkInfo(),
    ]);

    final user = results[0] as UserModel?;
    final info = results[1] as ({String? botUsername, String? botLink, String? message})?;

    if (mounted) {
      setState(() {
        _user = user;
        _botLink = info?.botLink;
        _botUsername = info?.botUsername;
        _isLoading = false;
      });
    }
  }

  Future<void> _openBot() async {
    if (_botLink == null || _botLink!.isEmpty) return;

    final uri = Uri.tryParse(_botLink!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      showSnackBar(context, 'Linkni ochib bo\'lmadi', isError: true);
    }
  }

  Future<void> _unlinkTelegram() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Telegram hisobni uzish'),
        content: const Text(
          'Telegram hisobingiz ilovadan uziladi. Keyin boshqa hisob ulashingiz mumkin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Uzish', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUnlinking = true);
    final result = await _apiService.unlinkTelegram();
    if (!mounted) return;
    setState(() => _isUnlinking = false);

    showSnackBar(context, result.message, isError: !result.success);

    if (result.success) {
      setState(() {
        _user = result.user ?? _user;
      });
    }
  }

  bool get _isLinked => _user?.hasTelegramLinked ?? false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Telegram')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildTelegramIcon(theme),
                    const SizedBox(height: 24),
                    if (_isLinked) _buildLinkedSection(theme) else _buildUnlinkedSection(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTelegramIcon(ThemeData theme) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLinked
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.7)]
              : [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (_isLinked ? AppColors.success : AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.send_rounded, size: 40, color: Colors.white),
    );
  }

  Widget _buildLinkedSection(ThemeData theme) {
    final tgName = [
      _user?.telegramFirstName,
      _user?.telegramLastName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    return Column(
      children: [
        Text(
          'Telegram ulangan',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (_user?.telegramFirstName?.isNotEmpty == true)
                        ? _user!.telegramFirstName![0].toUpperCase()
                        : 'T',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (tgName.isNotEmpty)
                Text(
                  tgName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              if (_user?.telegramUsername != null) ...[
                const SizedBox(height: 4),
                Text(
                  '@${_user!.telegramUsername}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(PhosphorIconsRegular.checkCircle, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'Muvaffaqiyatli ulangan',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_user?.telegramUsername != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => launchTelegram(_user!.telegramUsername!),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Telegram profilni ochish'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _isUnlinking ? null : _unlinkTelegram,
            icon: _isUnlinking
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : PhosphorIcon(PhosphorIconsRegular.linkBreak, size: 18, color: AppColors.error),
            label: Text(
              'Telegram hisobni uzish',
              style: TextStyle(color: _isUnlinking ? AppColors.textSecondary : AppColors.error),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              PhosphorIcon(PhosphorIconsRegular.info, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Boshqa Telegram hisobni ulash uchun avval joriy hisobni uzing.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnlinkedSection(ThemeData theme) {
    final hasBotLink = _botLink != null && _botLink!.isNotEmpty;

    return Column(
      children: [
        Text(
          'Telegram hisobini ulash',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Telegram orqali sizga to\'g\'ridan-to\'g\'ri xabar yozishlari mumkin bo\'ladi.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),

        if (hasBotLink) ...[
          _buildStepCard(theme, 1, 'Botga o\'ting', 'Pastdagi tugmani bosing va Telegram botga o\'ting.',
              PhosphorIconsRegular.paperPlaneTilt),
          const SizedBox(height: 10),
          _buildStepCard(theme, 2, '/start bosing', 'Botda /start yozing — sizga maxsus link beriladi.',
              PhosphorIconsRegular.play),
          const SizedBox(height: 10),
          _buildStepCard(
              theme,
              3,
              'Linkni bosing',
              'Berilgan linkni bosing — profilingiz avtomatik ulanadi.',
              PhosphorIconsRegular.link),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openBot,
              icon: const Icon(Icons.send_rounded, size: 20, color: Colors.white),
              label: Text(_botUsername != null ? '@$_botUsername ga o\'tish' : 'Botga o\'tish'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                PhosphorIcon(PhosphorIconsRegular.clock, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Link 10 daqiqa amal qiladi. Muddati o\'tsa, botda qayta /start bosing.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                PhosphorIcon(PhosphorIconsRegular.warning, size: 40, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  'Bot hozircha sozlanmagan',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Admin bilan bog\'laning.',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepCard(ThemeData theme, int step, String title, String desc, IconData icon) {
    return Container(
      width: double.infinity,
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$step',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          PhosphorIcon(icon, size: 22, color: AppColors.primary.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}
