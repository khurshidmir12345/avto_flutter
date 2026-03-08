import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class AppColorPreset {
  final String id;
  final String name;
  final Color primary;
  final Color primaryLight;
  final Color background;

  const AppColorPreset({
    required this.id,
    required this.name,
    required this.primary,
    required this.primaryLight,
    required this.background,
  });
}

class ThemeController extends ChangeNotifier {
  ThemeController._() {
    _applyCurrentPreset();
  }
  static final ThemeController instance = ThemeController._();

  /// Jiddiy, erkaklarga mos ranglar
  final List<AppColorPreset> presets = const [
    AppColorPreset(
      id: 'C01',
      name: 'Avto Vodiy',
      primary: Color(0xFF0F6E3B),
      primaryLight: Color(0xFF2E7D4A),
      background: Color(0xFFF2F7F4),
    ),
    AppColorPreset(
      id: 'C02',
      name: 'Forest',
      primary: Color(0xFF1B5E20),
      primaryLight: Color(0xFF388E3C),
      background: Color(0xFFF1F8E9),
    ),
    AppColorPreset(
      id: 'C03',
      name: 'Navy',
      primary: Color(0xFF0D47A1),
      primaryLight: Color(0xFF1976D2),
      background: Color(0xFFE3F2FD),
    ),
    AppColorPreset(
      id: 'C04',
      name: 'Teal',
      primary: Color(0xFF00695C),
      primaryLight: Color(0xFF00897B),
      background: Color(0xFFE0F2F1),
    ),
    AppColorPreset(
      id: 'C05',
      name: 'Slate',
      primary: Color(0xFF37474F),
      primaryLight: Color(0xFF546E7A),
      background: Color(0xFFECEFF1),
    ),
    AppColorPreset(
      id: 'C06',
      name: 'Indigo',
      primary: Color(0xFF283593),
      primaryLight: Color(0xFF3949AB),
      background: Color(0xFFE8EAF6),
    ),
    AppColorPreset(
      id: 'C07',
      name: 'Brown',
      primary: Color(0xFF5D4037),
      primaryLight: Color(0xFF795548),
      background: Color(0xFFEFEBE9),
    ),
    AppColorPreset(
      id: 'C08',
      name: 'Dark Teal',
      primary: Color(0xFF004D40),
      primaryLight: Color(0xFF00695C),
      background: Color(0xFFE0F2F1),
    ),
    AppColorPreset(
      id: 'C09',
      name: 'Steel',
      primary: Color(0xFF455A64),
      primaryLight: Color(0xFF607D8B),
      background: Color(0xFFCFD8DC),
    ),
    AppColorPreset(
      id: 'C10',
      name: 'Deep Blue',
      primary: Color(0xFF1565C0),
      primaryLight: Color(0xFF42A5F5),
      background: Color(0xFFE3F2FD),
    ),
  ];

  String _selectedId = 'C01';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  AppColorPreset get currentPreset =>
      presets.firstWhere((p) => p.id == _selectedId, orElse: () => presets.first);

  void _applyCurrentPreset() {
    final preset = currentPreset;
    final bg = _isDarkMode ? const Color(0xFF121212) : preset.background;
    AppColors.applyPreset(
      primaryColor: preset.primary,
      primaryLightColor: preset.primaryLight,
      backgroundColor: bg,
    );
  }

  Future<void> init() async {
    final savedId = await StorageService.getThemeId();
    if (savedId != null && presets.any((p) => p.id == savedId)) {
      _selectedId = savedId;
    }
    _isDarkMode = await StorageService.getDarkMode();
    _applyCurrentPreset();
    notifyListeners();
  }

  Future<void> selectPreset(String id) async {
    if (_selectedId == id || !presets.any((p) => p.id == id)) return;
    _selectedId = id;
    _applyCurrentPreset();
    await StorageService.saveThemeId(id);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    _applyCurrentPreset();
    await StorageService.saveDarkMode(_isDarkMode);
    notifyListeners();
  }
}
