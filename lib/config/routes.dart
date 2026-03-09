import 'package:flutter/material.dart';
import '../screens/main_screen.dart';
import '../screens/auth/auth_check_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/listings/create_elon_screen.dart';
import '../screens/listings/my_elonlar_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/profile/balance_history_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/profile/telegram_link_screen.dart';

class AppRoutes {
  static const home = '/';
  static const authCheck = '/auth-check';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const createElon = '/create-elon';
  static const myElonlar = '/my-elonlar';
  static const chatList = '/chat-list';
  static const changePassword = '/change-password';
  static const balanceHistory = '/balance-history';
  static const telegramLink = '/telegram-link';

  static Map<String, WidgetBuilder> get routes {
    return {
      authCheck: (context) => const AuthCheckScreen(),
      home: (context) => const MainScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      otp: (context) => const OtpScreen(),
      createElon: (context) => const CreateElonScreen(),
      myElonlar: (context) => const MyElonlarScreen(),
      chatList: (context) => const ChatListScreen(),
      changePassword: (context) => const ChangePasswordScreen(),
      balanceHistory: (context) => const BalanceHistoryScreen(),
      telegramLink: (context) => const TelegramLinkScreen(),
    };
  }
}
