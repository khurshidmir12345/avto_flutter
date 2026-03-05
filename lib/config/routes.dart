import 'package:flutter/material.dart';
import '../screens/main_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/listings/create_elon_screen.dart';
import '../screens/listings/my_elonlar_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/profile/change_password_screen.dart';

class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const createElon = '/create-elon';
  static const myElonlar = '/my-elonlar';
  static const chatList = '/chat-list';
  static const changePassword = '/change-password';

  static Map<String, WidgetBuilder> get routes {
    return {
      home: (context) => const MainScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      otp: (context) => const OtpScreen(),
      createElon: (context) => const CreateElonScreen(),
      myElonlar: (context) => const MyElonlarScreen(),
      chatList: (context) => const ChatListScreen(),
      changePassword: (context) => const ChangePasswordScreen(),
    };
  }
}
