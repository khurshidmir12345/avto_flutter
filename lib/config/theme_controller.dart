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

  final List<AppColorPreset> presets = const [
    AppColorPreset(
      id: 'C01',
      name: 'Mint Gold',
      primary: Color(0xFFA7D98C),
      primaryLight: Color(0xFFD9BE8C),
      background: Color(0xFFF9F6EE),
    ),
    AppColorPreset(
      id: 'C02',
      name: 'Soft Lime',
      primary: Color(0xFFCDD98C),
      primaryLight: Color(0xFFA7D98C),
      background: Color(0xFFF8FAEE),
    ),
    AppColorPreset(
      id: 'C03',
      name: 'Sky Lavender',
      primary: Color(0xFF8CA7D9),
      primaryLight: Color(0xFFBE8CD9),
      background: Color(0xFFF4F6FB),
    ),
    AppColorPreset(
      id: 'C04',
      name: 'Rose Sand',
      primary: Color(0xFFD39292),
      primaryLight: Color(0xFFD3B392),
      background: Color(0xFFFCF5F2),
    ),
    AppColorPreset(
      id: 'C05',
      name: 'Sand Olive',
      primary: Color(0xFFD3B392),
      primaryLight: Color(0xFFD3D392),
      background: Color(0xFFFBF9EF),
    ),
    AppColorPreset(
      id: 'C06',
      name: 'Aqua Blue',
      primary: Color(0xFF3CA7FF),
      primaryLight: Color(0xFF74D0FF),
      background: Color(0xFFF2FAFF),
    ),
    AppColorPreset(
      id: 'C07',
      name: 'Coral Peach',
      primary: Color(0xFFFF6F91),
      primaryLight: Color(0xFFFF9F68),
      background: Color(0xFFFFF4F3),
    ),
    AppColorPreset(
      id: 'C08',
      name: 'Violet Ice',
      primary: Color(0xFF8B7CFF),
      primaryLight: Color(0xFF6FD6FF),
      background: Color(0xFFF4F7FF),
    ),
    AppColorPreset(
      id: 'C09',
      name: 'Neo Green',
      primary: Color(0xFF00C980),
      primaryLight: Color(0xFF42E695),
      background: Color(0xFFF0FFF7),
    ),
    AppColorPreset(
      id: 'C10',
      name: 'Graphite Cyan',
      primary: Color(0xFF3A4B61),
      primaryLight: Color(0xFF5FD3BC),
      background: Color(0xFFF2F6F7),
    ),
  ];

  String _selectedId = 'C03';

  AppColorPreset get currentPreset =>
      presets.firstWhere((p) => p.id == _selectedId, orElse: () => presets.first);

  void _applyCurrentPreset() {
    final preset = currentPreset;
    AppColors.applyPreset(
      primaryColor: preset.primary,
      primaryLightColor: preset.primaryLight,
      backgroundColor: preset.background,
    );
  }

  Future<void> init() async {
    final savedId = await StorageService.getThemeId();
    if (savedId != null && presets.any((p) => p.id == savedId)) {
      _selectedId = savedId;
    }
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
}
