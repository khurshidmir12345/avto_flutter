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

Future<void> launchPhone(String phone) async {
  final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\D'), '')}');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
