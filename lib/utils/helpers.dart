import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/routes.dart';
import '../services/storage_service.dart';
import 'constants.dart';

void showSnackBar(BuildContext context, String message,
    {bool isError = false, Duration duration = const Duration(seconds: 2)}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

bool isValidPhoneDigits(String digits) {
  return RegExp(r'^\d{9}$').hasMatch(digits);
}

String formatPhone(String phone) {
  if (phone.length == 12) {
    return '+${phone.substring(0, 3)} (${phone.substring(3, 5)}) ${phone.substring(5, 8)}-${phone.substring(8, 10)}-${phone.substring(10)}';
  }
  return phone;
}

String _formatAmountWithSpaces(int amount) {
  final str = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(str[i]);
  }
  return buffer.toString();
}

/// Balansni UZS formatida ko'rsatadi (masalan: 50 000 so'm)
String formatBalance(int amount) {
  return '${_formatAmountWithSpaces(amount)} so\'m';
}

/// Faqat raqamni bo'shliq bilan formatlash (so'm siz)
String formatBalanceAmount(int amount) => _formatAmountWithSpaces(amount);

/// ISO 8601 sanani qisqa formatda ko'rsatadi
String formatBalanceHistoryDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return 'Bugun ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  } catch (_) {
    return iso;
  }
}

Future<bool> isLoggedIn() async {
  final token = await StorageService.getToken();
  return token != null && token.isNotEmpty;
}

Future<bool> requireAuth(BuildContext context, {String? message}) async {
  if (await isLoggedIn()) return true;
  if (!context.mounted) return false;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(
                PhosphorIconsRegular.userPlus,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Ro'yxatdan o'ting",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? "Bu funksiyadan foydalanish uchun ro'yxatdan o'ting.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Keyinroq'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Ro'yxatdan o'tish"),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  if (result == true && context.mounted) {
    Navigator.pushNamed(context, AppRoutes.register);
  }
  return false;
}

Future<void> launchPhone(String phone) async {
  final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\D'), '')}');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

/// Telegram profilga ochish (t.me/username)
Future<void> launchTelegram(String username) async {
  final clean = username.replaceAll('@', '').trim();
  if (clean.isEmpty) return;
  final uri = Uri.parse('https://t.me/$clean');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
