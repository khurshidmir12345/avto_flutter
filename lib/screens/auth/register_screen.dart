import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../config/routes.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/phone_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  void _onPasswordChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _passwordConfirmController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordConfirmController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final fullPhone = '998${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';

    final result = await _apiService.register(
      _nameController.text,
      fullPhone,
      _passwordController.text,
      _passwordConfirmController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    final messageLower = result.message.toLowerCase();
    final shouldOpenOtp = result.success ||
        messageLower.contains('otp') ||
        (messageLower.contains('kod') && messageLower.contains('yubor'));

    if (shouldOpenOtp) {
      showSnackBar(context, result.message);
      Navigator.pushNamed(
        context,
        AppRoutes.otp,
        arguments: {
          'phone': fullPhone,
          'name': _nameController.text.trim(),
          'password': _passwordController.text,
          'password_confirmation': _passwordConfirmController.text,
        },
      );
    } else {
      showSnackBar(context, result.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.register)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  PhosphorIcon(PhosphorIconsRegular.userPlus, size: 64, color: AppColors.primary),
                  const SizedBox(height: 24),
                  Text(
                    "Yangi hisob yaratish",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    label: AppStrings.fullName,
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    prefixIcon: PhosphorIconsRegular.user,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ism kiriting';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PhoneField(
                    controller: _phoneController,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Telefon raqam kiriting';
                      if (!isValidPhoneDigits(value)) return '9 ta raqam kiriting';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Parol',
                    controller: _passwordController,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    prefixIcon: PhosphorIconsRegular.lock,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Parol kiriting';
                      if (value.length < 8) return 'Kamida 8 ta belgi';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Parolni tasdiqlang',
                    controller: _passwordConfirmController,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    prefixIcon: PhosphorIconsRegular.lock,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Parolni tasdiqlang';
                      if (value != _passwordController.text) return 'Parollar mos kelmadi';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: AppStrings.register,
                    onPressed: _passwordController.text.length >= 8 &&
                            _passwordConfirmController.text.length >= 8
                        ? _register
                        : null,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Hisobingiz bormi? ",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          AppStrings.login,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
