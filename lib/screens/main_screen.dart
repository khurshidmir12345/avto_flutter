import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/chat_service.dart';
import 'home/home_screen.dart';
import 'listings/listings_screen.dart';
import 'profile/profile_screen.dart';
import 'chat/chat_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int? _selectedCategoryId;
  int _unreadCount = 0;
  final _chatService = ChatService();

  void _onCategoryTap(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _currentIndex = 1;
    });
  }

  Future<void> _loadUnreadCount() async {
    final list = await _chatService.getConversations();
    if (mounted) {
      final total = list.fold<int>(0, (sum, c) => sum + c.unreadCount);
      setState(() => _unreadCount = total);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  final _titles = const ['Asosiy', "E'lonlar", 'Yozishmalar', 'Profil'];

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
          ChatListScreen(onRefresh: _loadUnreadCount, embeddedInTab: true),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index != 1) _selectedCategoryId = null;
          });
          if (index == 2) _loadUnreadCount();
        },
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
          const BottomNavigationBarItem(
            icon: PhosphorIcon(PhosphorIconsRegular.user, size: 24),
            activeIcon: PhosphorIcon(PhosphorIconsFill.user, size: 24),
            label: 'Profil',
          ),
        ],
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
