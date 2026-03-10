import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _appVersion = '1.0.2';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ilova haqida')),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildLogo(theme),
            const SizedBox(height: 28),
            _buildSection(
              theme,
              icon: PhosphorIconsRegular.car,
              title: 'Avto Vodiy nima?',
              body: "Avto Vodiy — O'zbekiston viloyatlari bo'ylab avtomobil sotish va sotib olish uchun "
                  "yaratilgan qulay ilova. Bu yerda siz o'z mashinangizni e'lon qilib sotishingiz "
                  "yoki o'zingizga mos mashinani topishingiz mumkin.",
            ),
            const SizedBox(height: 14),
            _buildSection(
              theme,
              icon: PhosphorIconsRegular.listChecks,
              title: "Ilova qanday ishlaydi?",
              body: null,
              bullets: const [
                "Ro'yxatdan o'ting va hisobingizga kiring.",
                "E'lonlar bo'limida barcha mashinalarni ko'ring.",
                "O'zingizga yoqqan mashinani tanlang va egasi bilan bog'laning.",
                "O'z mashinangizni sotmoqchi bo'lsangiz, e'lon yarating — rasmlar, narx, tavsif qo'shing.",
                "Chat orqali sotuvchi yoki xaridor bilan to'g'ridan-to'g'ri yozishing.",
              ],
            ),
            const SizedBox(height: 14),
            _buildSection(
              theme,
              icon: PhosphorIconsRegular.star,
              title: "Nima uchun Avto Vodiy?",
              body: null,
              bullets: const [
                "Sodda va tushunarli — hech qanday murakkablik yo'q.",
                "Tezkor — bir necha daqiqada e'lon yarating.",
                "Xavfsiz — shaxsiy chat, to'g'ridan-to'g'ri aloqa.",
                "Bepul ro'yxatdan o'tish — bonus balans sovg'a.",
                "Uzbekiston bo'ylab — Toshkent, Farg'ona, Andijon, Namangan...",
              ],
            ),
            const SizedBox(height: 14),
            _buildSection(
              theme,
              icon: PhosphorIconsRegular.wallet,
              title: "Balans tizimi",
              body: "E'lon yaratish uchun hisobingizda balans bo'lishi kerak. "
                  "Ro'yxatdan o'tganingizda bonus balans beriladi. "
                  "Balansni to'ldirish uchun Profil sahifasidagi \"To'ldirish\" tugmasini bosing.",
            ),
            const SizedBox(height: 14),
            _buildSection(
              theme,
              icon: PhosphorIconsRegular.chatCircle,
              title: "Yordam kerakmi?",
              body: "Biror savol yoki muammo bo'lsa, ilovadagi Chat bo'limidan Admin bilan "
                  "bog'laning. Biz sizga yordam berishdan xursandmiz!",
            ),
            const SizedBox(height: 14),
            _buildContactCard(context, theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: PhosphorIcon(PhosphorIconsRegular.car, size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.appName,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Versiya $_appVersion',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          "O'zbekiston uchun avtomobil savdo ilovasi",
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required IconData icon,
    required String title,
    String? body,
    List<String>? bullets,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
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
              PhosphorIcon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (body != null)
            Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
          if (bullets != null)
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(b, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          PhosphorIcon(PhosphorIconsRegular.heart, size: 28, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            'Avto Vodiy jamoasi',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Ilovamizdan foydalanganingiz uchun rahmat!\n"
            "Takliflar va fikrlaringizni kutib qolamiz.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openTelegram(context),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Telegram orqali yozing'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTelegram(BuildContext context) async {
    final uri = Uri.parse('https://t.me/avto_vodiyuz');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
