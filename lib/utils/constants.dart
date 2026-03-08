import 'package:flutter/material.dart';

class AppColors {
  static Color primary = const Color(0xFFA7D98C);
  static Color primaryLight = const Color(0xFFD9BE8C);
  static Color secondary = const Color(0xFFCDD98C);
  static Color background = const Color(0xFFF9F6EE);
  static const surface = Colors.white;
  static const error = Color(0xFFD32F2F);
  static Color success = const Color(0xFF2E9F58);
  static Color textPrimary = const Color(0xFF2A2A2A);
  static Color textSecondary = const Color(0xFF6B6B6B);
  static const cardBg = Colors.white;

  static void applyPreset({
    required Color primaryColor,
    required Color primaryLightColor,
    required Color backgroundColor,
  }) {
    primary = primaryColor;
    primaryLight = primaryLightColor;
    secondary = Color.lerp(primaryColor, primaryLightColor, 0.5) ?? primaryColor;
    background = backgroundColor;
  }
}

class AppStrings {
  static const appName = 'Avto Vodiy';
  static const login = 'Kirish';
  static const register = "Ro'yxatdan o'tish";
  static const phone = 'Telefon raqam';
  static const password = 'Parol';
  static const fullName = 'Ism Familiya';
  static const home = 'Bosh sahifa';
  static const profile = 'Profil';
  static const otpVerify = 'OTP tasdiqlash';
  static const sendCode = 'Kod yuborish';
  static const verify = 'Tasdiqlash';
  static const logout = 'Chiqish';
  static const phonePlaceholder = '998XXXXXXXXX';
}

class AppSizes {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
}

class ApiConstants {
  static const baseUrl = 'http://localhost:8080/api';
  /// Rasm URL'lari uchun server manzili (relativ URL bo'lsa)
  static const imageBaseUrl = 'http://localhost:8080';
  /// CDN URL — R2 rasmlari uchun (backend .env IMAGE_CDN_URL)
  static const imageCdnUrl = 'https://img.avtovodiy.uz';
  /// Laravel storage link: '/storage'. API /uploads/... qaytarsa, /storage/uploads/... bo'ladi.
  /// 404 bo'lsa: '' qiling. 403 bo'lsa: backend permissions tekshiring.
  static const imagePathPrefix = '';
  static const registerUrl = '$baseUrl/auth/register';
  static const loginUrl = '$baseUrl/auth/login';
  static const verifyOtpUrl = '$baseUrl/auth/verify-otp';
  static const userUrl = '$baseUrl/auth/user';
  static const logoutUrl = '$baseUrl/auth/logout';
  static const changePasswordUrl = '$baseUrl/auth/password';
  static const updateProfileUrl = '$baseUrl/auth/profile';
  static const avatarUploadUrl = '$baseUrl/auth/avatar';

  static const categoriesUrl = '$baseUrl/categories';
  static const elonlarUrl = '$baseUrl/elonlar';
  /// Yangi flow: presigned URL → R2 ga yuklash → save
  static const imagesPresignedUrl = '$baseUrl/images/presigned-url';
  static const imagesSaveUrl = '$baseUrl/images/save';
  static String imageDeleteUrl(int imageId) => '$baseUrl/images/$imageId';
  static String elonlarDetail(int id) => '$baseUrl/elonlar/$id';
  static String elonlarImages(int id) => '$baseUrl/elonlar/$id/images';
  static String elonlarImageDelete(int elonId, int imageId) =>
      '$baseUrl/elonlar/$elonId/images/$imageId';
  static String elonlarImagesReorder(int id) => '$baseUrl/elonlar/$id/images/reorder';
  static const myElonlarUrl = '$baseUrl/elonlar/my/list';

  static const chatConversationsUrl = '$baseUrl/chat/conversations';
  static String chatConversationMessages(int id) => '$baseUrl/chat/conversations/$id/messages';
  static const chatUsersUrl = '$baseUrl/chat/users';
}

/// Bir e'lon uchun maksimal rasm soni
const int maxImages = 7;

class ElonOptions {
  static const valyuta = ['USD', 'UZS'];
  static const yoqilgiTuri = [
    'benzin',
    'metan',
    'benzin+metan',
    'dizel',
    'elektr',
    'gibrid',
  ];
  static const uzatishQutisi = ['mexanika', 'avtomat'];
  /// E'lon holati (yangilash uchun): active, sold, inactive
  static const holati = ['active', 'sold', 'inactive'];
}
