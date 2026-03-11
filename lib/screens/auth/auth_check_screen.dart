import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

/// Ilova ochilganda token mavjudligini tekshiradi.
/// Token saqlangan va haqiqiy bo'lsa — Home, aks holda — Register.
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      _navigateToRegister();
      return;
    }

    final user = await ApiService().getCurrentUser();
    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      await StorageService.deleteToken();
      _navigateToRegister();
    }
  }

  void _navigateToRegister() {
    Navigator.pushReplacementNamed(context, AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Yuklanmoqda...'),
          ],
        ),
      ),
    );
  }
}
