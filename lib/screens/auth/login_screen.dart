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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _didInitArgs = false;
  String? _infoBanner;
  String? _errorBanner;
  String? _supportBotLink;

  void _onPasswordChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _loadSupportBot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;
    _didInitArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _infoBanner = args['info'] as String?;
      final phone = args['phone'] as String?;
      if (phone != null) _phoneController.text = phone;
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSupportBot() async {
    final link = await _apiService.getSupportBotLink();
    if (mounted) setState(() => _supportBotLink = link);
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorBanner = null;
    });

    final fullPhone = '998${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';

    final result = await _apiService.login(fullPhone, _passwordController.text);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } else if (result.statusCode == 401) {
      setState(() {
        _errorBanner = 'Telefon raqam yoki parol noto\'g\'ri.';
        _infoBanner = null;
      });
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
                    'Avtomobil bozori',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_infoBanner != null)
                    _buildInfoCard(theme, _infoBanner!, isInfo: true),
                  if (_errorBanner != null)
                    _buildInfoCard(theme, _errorBanner!, isInfo: false),

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
                    label: AppStrings.password,
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
                  const SizedBox(height: 24),
                  CustomButton(
                    text: AppStrings.login,
                    onPressed: _passwordController.text.length >= 8 ? _login : null,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Hisobingiz yo'qmi? ",
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.register),
                        child: Text(
                          AppStrings.register,
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

  Widget _buildInfoCard(ThemeData theme, String text, {required bool isInfo}) {
    final bgColor = isInfo
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFFFEBEE);
    final borderColor = isInfo
        ? const Color(0xFFFFB74D)
        : const Color(0xFFEF5350);
    final iconColor = isInfo
        ? const Color(0xFFE65100)
        : const Color(0xFFD32F2F);
    final icon = isInfo
        ? PhosphorIconsRegular.info
        : PhosphorIconsRegular.warningCircle;

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? borderColor.withValues(alpha: 0.15) : bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: isDark ? 0.4 : 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
                if (_supportBotLink != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _openSupport,
                    child: Text(
                      'Parol eslamaysizmi? Supportga yozing',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
