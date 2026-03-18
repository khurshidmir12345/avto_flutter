import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String? _supportBotLink;

  void _onPasswordChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _passwordConfirmController.addListener(_onPasswordChanged);
    _loadSupportBot();
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

  Future<void> _loadSupportBot() async {
    final link = await _apiService.getSupportBotLink();
    if (mounted) setState(() => _supportBotLink = link);
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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

    if (result.statusCode == 409) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.login,
        arguments: {
          'info': 'Sizning raqamingizdan oldin hisob yaratilgan. '
              'Telefon raqam va parol kiritib kiring.',
          'phone': _phoneController.text,
        },
      );
      return;
    }

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

  Future<void> _openSupport() async {
    if (_supportBotLink == null) return;
    final uri = Uri.tryParse(_supportBotLink!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(PhosphorIconsRegular.car, size: 80, color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.appName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Yangi hisob yaratish",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

                  const SizedBox(height: 12),
                  _buildPolicyText(theme),
                  const SizedBox(height: 16),
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
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.login),
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
                  if (_supportBotLink != null) ...[
                    const SizedBox(height: 20),
                    _buildSupportLink(theme),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyText(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text.rich(
        TextSpan(
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: "Ro'yxatdan o'tish orqali siz "),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () => _openUrl(ApiConstants.termsUrl),
                child: Text(
                  'Foydalanish shartlari',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ),
            const TextSpan(text: ' va '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () => _openUrl(ApiConstants.privacyPolicyUrl),
                child: Text(
                  'Maxfiylik siyosati',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ),
            const TextSpan(text: 'ni qabul qilgan bo\'lasiz.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildSupportLink(ThemeData theme) {
    return GestureDetector(
      onTap: _openSupport,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.telegramLogo,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            'Yordam kerakmi?',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
