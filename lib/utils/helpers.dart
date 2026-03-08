import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

Future<void> launchPhone(String phone) async {
  final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\D'), '')}');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
