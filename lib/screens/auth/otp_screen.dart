import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import '../../config/routes.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isResending = false;
  bool _didInitArgs = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _phone = '';
  String _name = '';
  String _password = '';
  String _passwordConfirmation = '';
  int _secondsRemaining = 120;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _phone = (args['phone'] as String?) ?? '';
      _name = (args['name'] as String?) ?? '';
      _password = (args['password'] as String?) ?? '';
      _passwordConfirmation = (args['password_confirmation'] as String?) ?? '';
    }
    _didInitArgs = true;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _showSmsHelpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'SMS kod kelmayaptimi?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quyidagi sabablar ko\'pchilikda uchraydi:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              _buildReasonCard(
                icon: PhosphorIconsRegular.prohibit,
                title: '30% ehtimollik — Spam (keraksiz) papkasi',
                description:
                    'Telefonning SMS bo\'limida "Spam" yoki "Keraksiz" papkasi bo\'lishi mumkin. '
                    'Bizdan yuborilgan SMS 4546 raqamdan keladi va ko\'p hollarda shu papkaga tushib qoladi. '
                    'Ko\'pchilik bu joyni ko\'rmaydi. Telefon sozlamalarida SMS → Spam papkasini tekshiring va '
                    '4546 raqamdan kelgan xabarni chiqarib qo\'ying.',
              ),
              const SizedBox(height: 16),
              _buildReasonCard(
                icon: PhosphorIconsRegular.creditCard,
                title: '20% ehtimollik — Uzmobile balans',
                description:
                    'Agar Uzmobile operatoridan foydalanayotgan bo\'lsangiz va balansingizda mablag\' bo\'lmasa, '
                    'SIM karta SMS qabul qilmaydi. Balansingizni tekshiring va kamida bir oz mablag\' qo\'shing.',
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Tushundim',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(icon, color: const Color(0xFFE65100), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _otpCode => _controllers.map((c) => c.text).join();
  String get _countdownText {
    final m = (_secondsRemaining ~/ 60).toString();
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 120);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
        return;
      }
      setState(() => _secondsRemaining -= 1);
    });
  }

  void _clearOtpInputs() {
    for (final c in _controllers) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes.first.requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 4) {
      showSnackBar(context, '4 xonali kodni kiriting', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _apiService.verifyOtp(_phone, _otpCode);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      showSnackBar(context, result.message);
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } else {
      showSnackBar(context, result.message, isError: true);
    }
  }

  Future<void> _resendCode() async {
    if (_secondsRemaining > 0 || _isResending) return;

    if (_name.isEmpty || _phone.isEmpty || _password.isEmpty || _passwordConfirmation.isEmpty) {
      showSnackBar(context, "Qayta yuborish uchun ro'yxatdan o'tishni qayta boshlang", isError: true);
      return;
    }

    setState(() => _isResending = true);
    final result = await _apiService.register(_name, _phone, _password, _passwordConfirmation);
    if (!mounted) return;

    setState(() => _isResending = false);
    if (result.success) {
      _clearOtpInputs();
      _startTimer();
      showSnackBar(context, "Kod qayta yuborildi");
    } else {
      showSnackBar(context, result.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.otpVerify)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            children: [
              const SizedBox(height: 32),
              PhosphorIcon(PhosphorIconsRegular.chatCircleDots, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'SMS kod yuborildi',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                formatPhone(_phone),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    width: 60,
                    height: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _pulseAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showSmsHelpModal,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PhosphorIcon(
                            PhosphorIconsRegular.info,
                            size: 20,
                            color: const Color(0xFFE65100),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kod kelmayaptimi?',
                            style: TextStyle(
                              color: const Color(0xFFE65100),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Qayta yuborish: $_countdownText",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              if (_secondsRemaining == 0)
                TextButton(
                  onPressed: _isResending ? null : _resendCode,
                  child: _isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Kodni qayta yuborish"),
                ),
              const SizedBox(height: 32),
              CustomButton(
                text: AppStrings.verify,
                onPressed: _verifyOtp,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
