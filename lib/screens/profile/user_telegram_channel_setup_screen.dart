import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/user_telegram_channel_model.dart';
import '../../services/telegram_channel_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class UserTelegramChannelSetupScreen extends StatefulWidget {
  const UserTelegramChannelSetupScreen({super.key});

  @override
  State<UserTelegramChannelSetupScreen> createState() =>
      _UserTelegramChannelSetupScreenState();
}

class _UserTelegramChannelSetupScreenState
    extends State<UserTelegramChannelSetupScreen> {
  final _service = TelegramChannelApiService();
  final _formKey = GlobalKey<FormState>();
  final _botTokenController = TextEditingController();
  final _chatIdController = TextEditingController();
  final _channelNameController = TextEditingController();
  final _footerController = TextEditingController();

  bool _isSaving = false;
  bool _isEditing = false;
  int? _editingId;

  int _currentStep = 0;
  static const _totalSteps = 2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserTelegramChannelModel && !_isEditing) {
      _isEditing = true;
      _editingId = args.id;
      _chatIdController.text = args.chatId;
      _channelNameController.text = args.channelName ?? '';
      _footerController.text = args.footerText ?? '';
    }
  }

  @override
  void dispose() {
    _botTokenController.dispose();
    _chatIdController.dispose();
    _channelNameController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    if (_isEditing && _editingId != null) {
      final result = await _service.updateUserChannel(
        id: _editingId!,
        botToken: _botTokenController.text.trim().isNotEmpty
            ? _botTokenController.text.trim()
            : null,
        chatId: _chatIdController.text.trim(),
        channelName: _channelNameController.text.trim().isNotEmpty
            ? _channelNameController.text.trim()
            : null,
        footerText: _footerController.text.trim().isNotEmpty
            ? _footerController.text.trim()
            : null,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      showSnackBar(context, result.message, isError: !result.success);
      if (result.success) Navigator.pop(context, true);
    } else {
      final result = await _service.createUserChannel(
        botToken: _botTokenController.text.trim(),
        chatId: _chatIdController.text.trim(),
        channelName: _channelNameController.text.trim().isNotEmpty
            ? _channelNameController.text.trim()
            : null,
        footerText: _footerController.text.trim().isNotEmpty
            ? _footerController.text.trim()
            : null,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      showSnackBar(context, result.message, isError: !result.success);
      if (result.success) Navigator.pop(context, true);
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_botTokenController.text.trim().isEmpty && !_isEditing) {
        showSnackBar(context, 'Bot token kiriting', isError: true);
        return;
      }
      if (_chatIdController.text.trim().isEmpty) {
        showSnackBar(context, 'Chat ID kiriting', isError: true);
        return;
      }
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  String _buildPreview() {
    final footer = _footerController.text.trim();
    return UserTelegramChannelModel.defaultTemplate
        .replaceAll('{hashtag}', '#chevrolet_cobalt')
        .replaceAll('{marka}', 'Chevrolet')
        .replaceAll('{model}', 'Cobalt')
        .replaceAll('{yil}', '2020')
        .replaceAll('{probeg}', '45 000 km')
        .replaceAll('{narx}', '12 500 USD')
        .replaceAll('{valyuta}', 'USD')
        .replaceAll('{telefon}', '998901234567')
        .replaceAll('{shahar}', 'Toshkent')
        .replaceAll('{rang}', 'Oq')
        .replaceAll('{yoqilgi}', 'Benzin+Metan')
        .replaceAll('{uzatish}', 'Avtomat')
        .replaceAll('{link}', 'https://avtovodiy.uz/elon/123')
        .replaceAll('{footer}', footer.isNotEmpty ? footer : '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Kanalni tahrirlash' : "Kanal qo'shish"),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepIndicator(theme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _currentStep == 0
                      ? _buildStep1BotSetup(theme)
                      : _buildStep2FooterAndPreview(theme),
                ),
              ),
            ),
            _buildBottomBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone
                          ? AppColors.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDone || isActive)
                        ? AppColors.primary
                        : theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: isDone
                        ? const PhosphorIcon(PhosphorIconsRegular.check,
                            size: 14, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
                if (i < _totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone
                          ? AppColors.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1BotSetup(ThemeData theme) {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bot va Kanal sozlash',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Telegram bot yarating va kanalga admin sifatida qo'shing",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        _buildGuideCard(theme,
            step: 1,
            title: '@BotFather da bot yarating',
            description:
                'Telegram da @BotFather ni oching, /newbot yuboring va ko\'rsatmalarga amal qiling.',
            icon: PhosphorIconsRegular.robot),
        const SizedBox(height: 10),
        _buildGuideCard(theme,
            step: 2,
            title: 'Bot tokenni nusxalang',
            description:
                'BotFather sizga bot tokenni beradi. Uni nusxalab pastga kiriting.',
            icon: PhosphorIconsRegular.key),
        const SizedBox(height: 10),
        _buildGuideCard(theme,
            step: 3,
            title: 'Botni kanalga admin qiling',
            description:
                'Kanalingiz → Sozlamalar → Administratorlar → Botni qo\'shing.',
            icon: PhosphorIconsRegular.shieldCheck),
        const SizedBox(height: 10),
        _buildGuideCard(theme,
            step: 4,
            title: 'Chat ID ni toping',
            description:
                'Kanal username (@kanal) yoki @userinfobot orqali raqamli ID oling.',
            icon: PhosphorIconsRegular.identificationCard),
        const SizedBox(height: 24),
        if (!_isEditing) ...[
          Text('Bot Token *',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _botTokenController,
            decoration: InputDecoration(
              hintText: '1234567890:ABCdefGHIjklMNOpqrSTUvwxYZ',
              prefixIcon: const PhosphorIcon(PhosphorIconsRegular.key),
              helperText: 'BotFather dan olingan token',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (!_isEditing && (v == null || v.trim().isEmpty)) {
                return 'Bot token kiritish shart';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                PhosphorIcon(PhosphorIconsRegular.info,
                    size: 18, color: Colors.orange.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Token o'zgartirish uchun yangi kiriting (ixtiyoriy)",
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _botTokenController,
            decoration: InputDecoration(
              hintText: "Yangi token (bo'sh qoldirsa eski saqlanadi)",
              prefixIcon: const PhosphorIcon(PhosphorIconsRegular.key),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text('Kanal Chat ID *',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _chatIdController,
          decoration: InputDecoration(
            hintText: '@kanal_nomi yoki -1001234567890',
            prefixIcon: const PhosphorIcon(PhosphorIconsRegular.hash),
            helperText: 'Kanal username yoki raqamli ID',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Chat ID kiritish shart';
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text('Kanal nomi (ixtiyoriy)',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _channelNameController,
          decoration: InputDecoration(
            hintText: 'Masalan: Avto Toshkent',
            prefixIcon: const PhosphorIcon(PhosphorIconsRegular.textT),
            helperText: "Ko'rsatilmasa, avtomatik aniqlanadi",
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2FooterAndPreview(ThemeData theme) {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Footer va ko\'rinish',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "E'lon matni standart shaklda yuboriladi. "
          "Ixtiyoriy ravishda taglavha (footer) qo'shishingiz mumkin.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        Text('Footer matni (ixtiyoriy)',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _footerController,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: "Masalan: @kanal_nomi | Reklama: @admin",
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            helperText: "E'lon tagiga qo'shiladi (bo'sh qoldirsa bo'ladi)",
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 24),
        Text("E'lon ko'rinishi (namuna)",
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2836),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _buildPreview(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhosphorIcon(PhosphorIconsRegular.info,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Saqlangandan so'ng, bot token va chat ID tekshiriladi. "
                  "Bot kanalda admin bo'lishi shart.",
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

  Widget _buildGuideCard(ThemeData theme,
      {required int step,
      required String title,
      required String description,
      required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('$step',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary, height: 1.3)),
              ],
            ),
          ),
          PhosphorIcon(icon,
              size: 20, color: AppColors.primary.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Orqaga'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep > 0 ? 2 : 1,
              child: _currentStep < _totalSteps - 1
                  ? FilledButton(
                      onPressed: _nextStep,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Keyingisi'),
                    )
                  : FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_isEditing ? 'Saqlash' : "Qo'shish"),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
