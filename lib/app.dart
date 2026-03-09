import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'config/theme_controller.dart';
import 'services/api_service.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';

class AvtoVodiyApp extends StatefulWidget {
  const AvtoVodiyApp({super.key});

  @override
  State<AvtoVodiyApp> createState() => _AvtoVodiyAppState();
}

class _AvtoVodiyAppState extends State<AvtoVodiyApp> {
  final _themeController = ThemeController.instance;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _themeController.init();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) _handleTelegramLink(uri);

    _appLinks.uriLinkStream.listen((uri) {
      _handleTelegramLink(uri);
    });
  }

  void _handleTelegramLink(Uri uri) {
    final isTelegramLink = uri.host == 'telegram-link' ||
        uri.path.replaceAll('/', '') == 'telegram-link';
    if (!isTelegramLink) return;

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    final context = _navigatorKey.currentContext;
    if (context == null) return;

    _linkTelegram(context, token);
  }

  Future<void> _linkTelegram(BuildContext context, String token) async {
    final result = await ApiService().linkTelegram(token);

    if (!context.mounted) return;

    final msg = result.success
        ? '${result.message} Profilni yangilash uchun yuqoriga torting.'
        : result.message;
    showSnackBar(context, msg, isError: !result.success);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) => MaterialApp(
        navigatorKey: _navigatorKey,
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
