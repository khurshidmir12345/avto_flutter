import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length && i < 9; i++) {
      // Format: XX XXX XX XX
      if (i == 2 || i == 5 || i == 7) buffer.write(' ');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const PhoneField({
    super.key,
    required this.controller,
    this.validator,
  });

  String get digitsOnly => controller.text.replaceAll(RegExp(r'\D'), '');
  String get fullPhone => '998$digitsOnly';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: TextStyle(color: theme.colorScheme.onSurface),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
        _PhoneFormatter(),
      ],
      validator: (value) {
        final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
        if (validator != null) return validator!(digits);
        return null;
      },
      decoration: InputDecoration(
        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
        labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        labelText: AppStrings.phone,
        prefixIcon: Container(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Builder(
            builder: (ctx) {
              final theme = Theme.of(ctx);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(PhosphorIconsRegular.phone, size: 20, color: theme.colorScheme.onSurface),
                  const SizedBox(width: 8),
                  Text(
                    '+998',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    height: 24,
                    width: 1,
                    margin: const EdgeInsets.only(left: 8),
                    color: theme.colorScheme.outlineVariant,
                  ),
                ],
              );
            },
          ),
        ),
        hintText: 'XX XXX XX XX',
      ),
    );
  }
}
