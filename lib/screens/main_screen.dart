import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/analytics_service.dart';
import '../services/chat_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../config/routes.dart';
import 'home/home_screen.dart';
import 'listings/listings_screen.dart';
import 'profile/profile_screen.dart';
import 'chat/chat_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialTab});

  final int? initialTab;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  int? _selectedCategoryId;
  int _unreadCount = 0;
  final _chatService = ChatService();
  final _analytics = AnalyticsService();
  bool _isGuest = true;

  void _onCategoryTap(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _currentIndex = 1;
    });
  }

  Future<void> _loadUnreadCount() async {
    if (_isGuest) return;
    final list = await _chatService.getConversations();
    if (mounted) {
      final total = list.fold<int>(0, (sum, c) => sum + c.unreadCount);
      setState(() => _unreadCount = total);
    }
  }

  Future<void> _checkAuthStatus() async {
    final loggedIn = await isLoggedIn();
    if (mounted) {
      setState(() => _isGuest = !loggedIn);
    }
  }

  static const _tabPages = ['home', 'listings', 'chat', 'profile'];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab ?? 0;
    _checkAuthStatus().then((_) {
      if (!_isGuest) _loadUnreadCount();
    });
    _analytics.trackPageView(_tabPages[_currentIndex]);
  }

  final _titles = const ['Asosiy', "E'lonlar", 'Yozishmalar', 'Profil'];

  Future<void> _onTabTap(int index) async {
    if ((index == 2 || index == 3) && _isGuest) {
      final tabName = index == 2 ? 'Yozishmalar' : 'Profil';
      await requireAuth(context, message: '$tabName uchun avval ro\'yxatdan o\'ting.');
      await _checkAuthStatus();
      if (_isGuest) return;
    }

    setState(() {
      _currentIndex = index;
      if (index != 1) _selectedCategoryId = null;
    });
    _analytics.trackPageView(_tabPages[index]);
    if (index == 2) _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onCategoryTap: _onCategoryTap),
          ListingsScreen(categoryId: _selectedCategoryId),
          _isGuest
              ? _buildGuestPlaceholder(
                  icon: PhosphorIconsRegular.chatCircle,
                  title: 'Yozishmalar',
                  description: "Xabar yozish uchun avval ro'yxatdan o'ting",
                )
              : ChatListScreen(onRefresh: _loadUnreadCount, embeddedInTab: true),
          _isGuest
              ? _buildGuestPlaceholder(
                  icon: PhosphorIconsRegular.userCircle,
                  title: 'Profil',
                  description: "Profildan foydalanish uchun ro'yxatdan o'ting",
                )
              : const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
        items: [
          const BottomNavigationBarItem(
            icon: PhosphorIcon(PhosphorIconsRegular.house, size: 24),
            activeIcon: PhosphorIcon(PhosphorIconsFill.house, size: 24),
            label: 'Asosiy',
          ),
          const BottomNavigationBarItem(
            icon: PhosphorIcon(PhosphorIconsRegular.car, size: 24),
            activeIcon: PhosphorIcon(PhosphorIconsFill.car, size: 24),
            label: "E'lonlar",
          ),
          BottomNavigationBarItem(
            icon: _buildChatIcon(active: false),
            activeIcon: _buildChatIcon(active: true),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: _isGuest
                ? PhosphorIcon(PhosphorIconsRegular.userPlus, size: 24)
                : const PhosphorIcon(PhosphorIconsRegular.user, size: 24),
            activeIcon: _isGuest
                ? PhosphorIcon(PhosphorIconsFill.userPlus, size: 24)
                : const PhosphorIcon(PhosphorIconsFill.user, size: 24),
            label: _isGuest ? "Ro'yxatdan o'tish" : 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildGuestPlaceholder({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Ro'yxatdan o'tish",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Hisobim bor, kirish',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatIcon({required bool active}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PhosphorIcon(
          active ? PhosphorIconsFill.chatCircle : PhosphorIconsRegular.chatCircle,
          size: 24,
        ),
        if (_unreadCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
