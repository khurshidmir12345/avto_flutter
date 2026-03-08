import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final user = await _apiService.getCurrentUser();
    final hasNew = await _checkNewBalanceHistory();
    if (mounted) {
      setState(() {
        _user = user;
        _hasNewBalanceHistory = hasNew;
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
      if (fallback != raw) {
        urls.add(fallback);
      }
    }
    return urls;
  }

  Widget _buildAvatarImage(List<String> urls, int index) {
    if (index >= urls.length) {
      return Icon(Icons.person, size: 32, color: AppColors.primary);
    }

    final url = urls[index];
    return CachedNetworkImage(
      imageUrl: url,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      placeholder: (_, __) => Icon(Icons.person, size: 32, color: AppColors.primary),
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
      builder: (context) => AlertDialog(
        title: const Text('Chiqish'),
        content: const Text('Haqiqatan ham chiqmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Yo'q")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ha')),
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

  Future<void> _editName() async {
    final controller = TextEditingController(text: _user?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ismni tahrirlash'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Ism Familiya',
              prefixIcon: Icon(Icons.person),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );

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

  void _openThemeSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: AnimatedBuilder(
              animation: _themeController,
              builder: (context, _) {
                final selectedId = _themeController.currentPreset.id;
                final isDark = _themeController.isDarkMode;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ilova rangi",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rangni tanlang",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ..._themeController.presets.map((preset) {
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
                                  ? const Icon(Icons.check, color: Colors.white, size: 22)
                                  : null,
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Qorongʻu rejim',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
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
    final avatarUrls = _resolveAvatarUrls();
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadUser(showLoading: false),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: _pickAndUploadAvatar,
                        borderRadius: BorderRadius.circular(36),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                              child: _isUploadingAvatar
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : ClipOval(
                                      child: _buildAvatarImage(avatarUrls, 0),
                                    ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _user != null ? formatPhone(_user!.phone) : '',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _user != null ? _editName : null,
                        icon: Icon(Icons.edit, color: AppColors.primary, size: 20),
                        tooltip: 'Ismni tahrirlash',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Balans karta
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatBalance(_user?.balance ?? 0),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text("To'ldirish"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildMenuItem(
                    context,
                    icon: Icons.account_balance_wallet,
                    title: 'Hisob tarixi',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.balanceHistory)
                        .then((_) => _loadUser(showLoading: false)),
                    showBadge: _hasNewBalanceHistory,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.directions_car,
                    title: "Mening e'lonlarim",
                    onTap: () => Navigator.pushNamed(context, AppRoutes.myElonlar),
                  ),
                  _buildMenuItem(context, icon: Icons.favorite_border, title: 'Sevimlilar'),
                  _buildMenuItem(
                    context,
                    icon: Icons.lock_reset,
                    title: "Parolni o'zgartirish",
                    onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    title: 'Sozlamalar',
                    onTap: _openThemeSettings,
                  ),
                  _buildMenuItem(context, icon: Icons.info_outline, title: 'Ilova haqida'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: Text(
                        AppStrings.logout,
                        style: const TextStyle(color: AppColors.error, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool showBadge = false,
  }) {
    return Card(
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: AppColors.primary),
            if (showBadge)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(title),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap ?? () {},
      ),
    );
  }
}
