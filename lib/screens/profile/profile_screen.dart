import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/routes.dart';
import '../../config/theme_controller.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  final _themeController = ThemeController.instance;
  UserModel? _user;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  bool _hasNewBalanceHistory = false;
  bool _balanceTopupEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final user = await _apiService.getCurrentUser();
    final hasNew = await _checkNewBalanceHistory();
    final topupEnabled = await StorageService.getBalanceTopupEnabled();
    if (mounted) {
      setState(() {
        _user = user;
        _hasNewBalanceHistory = hasNew;
        _balanceTopupEnabled = topupEnabled;
        _isLoading = false;
      });
    }
  }

  Future<bool> _checkNewBalanceHistory() async {
    final latestAt = await _apiService.getLatestBalanceHistoryCreatedAt();
    if (latestAt == null) return false;
    final viewedAt = await StorageService.getBalanceHistoryViewedAt();
    if (viewedAt == null) return true;
    return latestAt.compareTo(viewedAt) > 0;
  }

  List<String> _resolveAvatarUrls() {
    final avatarPath = (_user?.avatarIcon?.trim().isNotEmpty == true)
        ? _user!.avatarIcon
        : _user?.avatarUrl;
    if (avatarPath == null || avatarPath.trim().isEmpty) return [];
    final raw = avatarPath.trim();
    final urls = <String>[raw];
    if (raw.contains('/media/')) {
      final fallback = raw.replaceFirst('/media/', '/storage/media/');
      if (fallback != raw) urls.add(fallback);
    }
    return urls;
  }

  Widget _buildAvatarImage(List<String> urls, int index) {
    if (index >= urls.length) {
      return PhosphorIcon(PhosphorIconsRegular.user, size: 36, color: AppColors.primary);
    }
    return CachedNetworkImage(
      imageUrl: urls[index],
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      placeholder: (_, __) => PhosphorIcon(PhosphorIconsRegular.user, size: 36, color: AppColors.primary),
      errorWidget: (_, __, ___) => _buildAvatarImage(urls, index + 1),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null) return;

    final ext = picked.path.split('.').last.toLowerCase();
    const allowed = {'jpeg', 'jpg', 'png', 'webp'};
    if (!allowed.contains(ext)) {
      if (!mounted) return;
      showSnackBar(context, 'Faqat jpeg, jpg, png, webp ruxsat etiladi', isError: true);
      return;
    }

    final fileSize = await picked.length();
    if (fileSize > 10 * 1024 * 1024) {
      if (!mounted) return;
      showSnackBar(context, 'Rasm hajmi 10MB dan oshmasligi kerak', isError: true);
      return;
    }

    setState(() => _isUploadingAvatar = true);
    final result = await _apiService.uploadAvatar(picked.path);
    if (!mounted) return;
    setState(() => _isUploadingAvatar = false);
    showSnackBar(context, result.message, isError: !result.success);
    if (result.success && result.user != null) {
      setState(() => _user = result.user);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Chiqish'),
        content: const Text('Haqiqatan ham chiqmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Yo'q")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ha, chiqish')),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await _apiService.logout();
    if (!mounted) return;
    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } else {
      showSnackBar(context, 'Chiqishda xatolik', isError: true);
    }
  }

  Future<void> _deleteAccount() async {
    final firstConfirm = await showDialog<bool>(
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
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const PhosphorIcon(PhosphorIconsRegular.warning, size: 32, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              Text(
                "Hisobni o'chirish",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Barcha ma'lumotlaringiz — e'lonlar, xabarlar, sevimlilar "
                "butunlay o'chiriladi. Bu amalni ortga qaytarib bo'lmaydi.",
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Bekor qilish'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Davom etish"),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (firstConfirm != true || !mounted) return;

    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Ishonchingiz komilmi?"),
        content: const Text(
          "Hisobingiz butunlay o'chiriladi va bu amalni ortga qaytarib bo'lmaydi!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Yo'q, bekor qilish"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("Ha, o'chirish"),
          ),
        ],
      ),
    );

    if (secondConfirm != true || !mounted) return;
    setState(() => _isLoading = true);
    final result = await _apiService.deleteAccount();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      await StorageService.clearAll();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.register, (_) => false);
      showSnackBar(context, result.message);
    } else {
      showSnackBar(context, result.message, isError: true);
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _user?.name ?? '');
    final formKey = GlobalKey<FormState>();

    String? newName;
    try {
      newName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Ismni tahrirlash'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Ism Familiya',
                prefixIcon: PhosphorIcon(PhosphorIconsRegular.user),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Ism kiriting';
                if (value.trim().length < 2) return 'Kamida 2 ta belgi';
                if (value.trim().length > 100) return 'Maksimum 100 ta belgi';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, controller.text.trim());
                }
              },
              child: const Text('Saqlash'),
            ),
          ],
        ),
      );
    } finally {
      await Future.delayed(const Duration(milliseconds: 100));
      controller.dispose();
    }
    if (newName == null || newName == _user?.name) return;

    setState(() => _isLoading = true);
    final result = await _apiService.updateProfile(newName);
    if (!mounted) return;
    setState(() => _isLoading = false);
    showSnackBar(context, result.message, isError: !result.success);
    if (result.success && result.user != null) {
      setState(() => _user = result.user);
    }
  }

  void _openProfileSettings() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Profil sozlamalari",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildBottomSheetItem(
                  theme: theme,
                  icon: PhosphorIconsRegular.pencilSimple,
                  label: "Ismni o'zgartirish",
                  onTap: () {
                    Navigator.pop(ctx);
                    _editName();
                  },
                ),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
                _buildBottomSheetItem(
                  theme: theme,
                  icon: PhosphorIconsRegular.trash,
                  label: "Hisobni o'chirish",
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteAccount();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetItem({
    required ThemeData theme,
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PhosphorIcon(icon, size: 22, color: c),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: c,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              size: 18,
              color: c.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _openThemeSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: AnimatedBuilder(
              animation: _themeController,
              builder: (context, _) {
                final selectedId = _themeController.currentPreset.id;
                final isDark = _themeController.isDarkMode;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Ilova rangi",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rangni tanlang",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _themeController.presets.map((preset) {
                        final isSelected = preset.id == selectedId;
                        return GestureDetector(
                          onTap: () => _themeController.selectPreset(preset.id),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [preset.primary, preset.primaryLight],
                              ),
                              border: Border.all(
                                color: isSelected ? Colors.black87 : Colors.black12,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: preset.primary.withValues(alpha: 0.4),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? PhosphorIcon(PhosphorIconsRegular.check, color: Colors.white, size: 22)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Qorongʻu rejim',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Switch(
                          value: isDark,
                          onChanged: (_) => _themeController.toggleDarkMode(),
                          activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrls = _resolveAvatarUrls();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadUser(showLoading: false),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ─── Profil ma'lumotlari ───
              _buildSection(
                theme: theme,
                title: "Profil ma'lumotlari",
                child: Row(
                  children: [
                    InkWell(
                      onTap: _pickAndUploadAvatar,
                      borderRadius: BorderRadius.circular(40),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                            child: _isUploadingAvatar
                                ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : ClipOval(child: _buildAvatarImage(avatarUrls, 0)),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.surface, width: 2),
                              ),
                              child: const PhosphorIcon(PhosphorIconsRegular.camera, size: 13, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user?.name ?? 'Foydalanuvchi',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _user != null ? formatPhone(_user!.phone) : '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (_user?.hasTelegramLinked == true && _user?.telegramUsername != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                PhosphorIcon(PhosphorIconsRegular.telegramLogo, size: 13, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  '@${_user!.telegramUsername}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openProfileSettings,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: PhosphorIcon(
                            PhosphorIconsRegular.gearSix,
                            size: 22,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── Balans karta ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asosiy Hisob',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatBalance(_user?.balance ?? 0),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_balanceTopupEnabled)
                      OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.balanceTopup),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text("To'ldirish"),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Telegram ───
              _buildTelegramCard(theme),

              const SizedBox(height: 20),

              // ─── Xizmatlar ───
              _buildSection(
                theme: theme,
                title: 'Xizmatlar',
                child: Column(
                  children: [
                    _buildSectionItem(
                      theme: theme,
                      icon: PhosphorIconsRegular.megaphoneSimple,
                      title: 'Telegram Kanal',
                      subtitle: "Shaxsiy kanalga e'lon yuborish",
                      onTap: () => Navigator.pushNamed(context, AppRoutes.userTelegramChannels),
                    ),
                    _buildDivider(theme),
                    _buildSectionItem(
                      theme: theme,
                      icon: PhosphorIconsRegular.wallet,
                      title: 'Hisob tarixi',
                      showBadge: _hasNewBalanceHistory,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.balanceHistory)
                          .then((_) => _loadUser(showLoading: false)),
                    ),
                    _buildDivider(theme),
                    _buildSectionItem(
                      theme: theme,
                      icon: PhosphorIconsRegular.car,
                      title: "Mening e'lonlarim",
                      onTap: () => Navigator.pushNamed(context, AppRoutes.myElonlar),
                    ),
                    _buildDivider(theme),
                    _buildSectionItem(
                      theme: theme,
                      icon: PhosphorIconsRegular.megaphone,
                      title: 'Reklamalar',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.myAdvertisements),
                    ),
                    _buildDivider(theme),
                    _buildSectionItem(
                      theme: theme,
                      icon: PhosphorIconsRegular.heart,
                      title: 'Sevimlilar',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.favorites),
                    ),
                    _buildDivider(theme),
                    _buildSectionItem(
                      theme: theme,
                      icon: PhosphorIconsRegular.prohibit,
                      title: 'Bloklangan foydalanuvchilar',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.blockedUsers),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── Sozlamalar ───
              _buildSection(
                theme: theme,
                title: 'Sozlamalar',
                child: Column(
                  children: [
                    _buildSectionItem(
                      theme: theme,
                      icon: PhosphorIconsRegular.key,
                      title: "Parolni o'zgartirish",
                      onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                    ),
                    _buildDivider(theme),
                    _buildSectionItem(
                      theme: theme,
                      icon: PhosphorIconsRegular.palette,
                      title: 'Ilova ko\'rinishi',
                      subtitle: 'Rang va qorongʻu rejim',
                      onTap: _openThemeSettings,
                    ),
                    _buildDivider(theme),
                    _buildSectionItem(
                      theme: theme,
                      icon: PhosphorIconsRegular.info,
                      title: 'Ilova haqida',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Chiqish ───
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const PhosphorIcon(PhosphorIconsRegular.signOut, size: 20, color: AppColors.error),
                  label: const Text(
                    'Chiqish',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Seksiya wrapper ───
  Widget _buildSection({
    required ThemeData theme,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: child,
        ),
      ],
    );
  }

  // ─── Seksiya ichidagi element ───
  Widget _buildSectionItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    String? subtitle,
    bool showBadge = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: PhosphorIcon(icon, size: 20, color: AppColors.primary),
                ),
                if (showBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3));
  }

  Widget _buildTelegramCard(ThemeData theme) {
    final isLinked = _user?.hasTelegramLinked == true;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.telegramLink)
          .then((_) => _loadUser(showLoading: false)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLinked
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLinked
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.send_rounded,
                size: 22,
                color: isLinked ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Telegram', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  if (isLinked && _user?.telegramUsername != null)
                    Text('@${_user!.telegramUsername}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.success))
                  else
                    Text('Hisobni ulash', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isLinked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Ulangan',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              )
            else
              PhosphorIcon(PhosphorIconsRegular.caretRight, color: theme.colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}
