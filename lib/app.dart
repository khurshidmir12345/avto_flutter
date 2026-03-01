import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'utils/constants.dart';

class AvtoVodiyApp extends StatelessWidget {
  const AvtoVodiyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
