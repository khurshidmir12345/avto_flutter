import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'config/theme_controller.dart';
import 'utils/constants.dart';

class AvtoVodiyApp extends StatefulWidget {
  const AvtoVodiyApp({super.key});

  @override
  State<AvtoVodiyApp> createState() => _AvtoVodiyAppState();
}

class _AvtoVodiyAppState extends State<AvtoVodiyApp> {
  final _themeController = ThemeController.instance;

  @override
  void initState() {
    super.initState();
    _themeController.init();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) => MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme(_themeController.currentPreset),
        darkTheme: AppTheme.darkTheme(_themeController.currentPreset),
        themeMode: _themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.authCheck,
        routes: AppRoutes.routes,
      ),
    );
  }
}
