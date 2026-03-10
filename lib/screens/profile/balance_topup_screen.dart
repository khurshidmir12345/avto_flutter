import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class BalanceTopupScreen extends StatelessWidget {
  const BalanceTopupScreen({super.key});

  static const _cards = [
    _CardInfo(
      number: '9860 1606 0212 0760',
      holder: 'Khurshidbek Mirzajonov',
      bank: 'Humo',
    ),
    _CardInfo(
      number: '9860 1901 0603 7780',
      holder: 'Khurshidbek Mirzajonov',
      bank: 'Humo',
    ),
  ];

  void _copyCardNumber(BuildContext context, String number) {
    final raw = number.replaceAll(' ', '');
    Clipboard.setData(ClipboardData(text: raw));
    showSnackBar(context, 'Karta raqami nusxalandi');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Balansni to'ldirish")),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(theme),
            const SizedBox(height: 20),
            Text(
              "To'lov kartalari",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final card in _cards) ...[
              _buildCardTile(context, theme, card),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            _buildSteps(theme),
            const SizedBox(height: 20),
            _buildTimingNote(theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.info,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Hozirda to'lov tizimlari ulanmoqda. Shu vaqtgacha balansni "
              "faqat kartaga pul o'tkazish orqali to'ldirish mumkin.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(
    BuildContext context,
    ThemeData theme,
    _CardInfo card,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  card.bank,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              PhosphorIcon(
                PhosphorIconsRegular.creditCard,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  card.number,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyCardNumber(context, card.number),
                icon: PhosphorIcon(
                  PhosphorIconsRegular.copy,
                  size: 20,
                  color: AppColors.primary,
                ),
                tooltip: 'Nusxalash',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            card.holder,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteps(ThemeData theme) {
    const steps = [
      'Yuqoridagi kartalardan biriga kerakli miqdordagi pulni o\'tkazing.',
      'To\'lov chekini (skrinshot) saqlang.',
      'Ilovadagi Chat bo\'limiga o\'ting va Admin profiliga yozing.',
      'Chek rasmini adminga yuboring.',
      'Balansingiz 10 daqiqadan 3 soatgacha bo\'lgan vaqt ichida to\'ldiriladi.',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
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
              PhosphorIcon(
                PhosphorIconsRegular.listNumbers,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Qanday to\'ldiriladi?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < steps.length; i++) ...[
            _buildStepRow(theme, i + 1, steps[i]),
            if (i < steps.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildStepRow(ThemeData theme, int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimingNote(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.clock,
            size: 20,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Xavotir olmang! Pul o'tkazgandan so'ng balansingiz 10 daqiqadan "
              "3 soatgacha bo'lgan vaqt ichida to'ldiriladi.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardInfo {
  final String number;
  final String holder;
  final String bank;

  const _CardInfo({
    required this.number,
    required this.holder,
    required this.bank,
  });
}
