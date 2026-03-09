import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isLinked = false;
  String? _telegramUsername;
  String? _botLink;
  String? _botUsername;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final user = await _apiService.getCurrentUser();
    final info = await _apiService.getTelegramLinkInfo();

    if (mounted) {
      setState(() {
        _isLinked = user?.hasTelegramLinked ?? false;
        _telegramUsername = user?.telegramUsername;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram hisobini ulash'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: PhosphorIcon(
                        PhosphorIconsRegular.telegramLogo,
                        size: 72,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isLinked ? 'Telegram ulangan' : 'Telegram hisobini ulash',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLinked) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PhosphorIcon(
                              PhosphorIconsRegular.checkCircle,
                              color: AppColors.success,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _telegramUsername != null
                                  ? '@$_telegramUsername'
                                  : 'Ulangan',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_botLink != null && _botLink!.isNotEmpty) ...[
                      Text(
                        'Telegram hisobingizni Avto Vodiy ilovasiga ulash uchun quyidagi qadamlarni bajaring:',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 24),
                      _buildStep(1, 'Pastdagi tugmani bosing va botga o\'ting'),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _openBot,
                          icon: PhosphorIcon(PhosphorIconsRegular.paperPlaneTilt, size: 20, color: Colors.white),
                          label: Text(_botUsername != null ? '@$_botUsername ga o\'tish' : 'Botga o\'tish'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildStep(2, 'Botda /start yozing — sizga maxsus link beriladi'),
                      const SizedBox(height: 8),
                      _buildStep(3, 'Linkni bosing — profilingiz avtomatik ulanadi'),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        child: Row(
                          children: [
                            PhosphorIcon(
                              PhosphorIconsRegular.info,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Link 10 daqiqa amal qiladi. Muddati o\'tsa, botda qayta /start bosing.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Bot hozircha sozlanmagan. Admin bilan bog\'laning.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
