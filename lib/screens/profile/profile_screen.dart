import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/routes.dart';
import '../../config/theme_controller.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final user = await _apiService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
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
    return Image.network(
      url,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildAvatarImage(urls, index + 1),
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
                    const SizedBox(height: 6),
                    Text(
                      "10 ta rangdan birini tanlang (ID bilan)",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.58,
                      child: GridView.builder(
                        shrinkWrap: true,
                        itemCount: _themeController.presets.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.35,
                        ),
                        itemBuilder: (context, index) {
                          final preset = _themeController.presets[index];
                          final isSelected = preset.id == selectedId;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _themeController.selectPreset(preset.id),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? preset.primary : Colors.black12,
                                  width: isSelected ? 2 : 1,
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [preset.primary, preset.primaryLight],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(Icons.check_circle, color: Colors.white),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    preset.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black38,
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "ID: ${preset.id}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
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
    // ignore: avoid_print
    print('[ProfileScreen] avatar candidates: $avatarUrls');
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
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _user != null ? formatPhone(_user!.phone) : '',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
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
                                '0 so\'m',
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
                    icon: Icons.directions_car,
                    title: "Mening e'lonlarim",
                    onTap: () => Navigator.pushNamed(context, AppRoutes.myElonlar),
                  ),
                  _buildMenuItem(context, icon: Icons.favorite_border, title: 'Sevimlilar'),
                  _buildMenuItem(context, icon: Icons.history, title: 'Tarix'),
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
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap ?? () {},
      ),
    );
  }
}
