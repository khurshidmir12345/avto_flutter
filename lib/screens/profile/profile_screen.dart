import 'package:flutter/material.dart';
import '../../config/routes.dart';
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
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _apiService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Profil rasmi + ism + telefon
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                        child: Icon(Icons.person, size: 32, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Column(
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
                  _buildMenuItem(context, icon: Icons.directions_car, title: "Mening e'lonlarim"),
                  _buildMenuItem(context, icon: Icons.favorite_border, title: 'Sevimlilar'),
                  _buildMenuItem(context, icon: Icons.history, title: 'Tarix'),
                  _buildMenuItem(context, icon: Icons.settings, title: 'Sozlamalar'),
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
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () {},
      ),
    );
  }
}
