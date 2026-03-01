import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF8B4513);
  static const primaryLight = Color(0xFFD2A679);
  static const secondary = Color(0xFFFFA000);
  static const background = Color(0xFFFFF8F0);
  static const surface = Colors.white;
  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF388E3C);
  static const textPrimary = Color(0xFF3E2723);
  static const textSecondary = Color(0xFF8D6E63);
  static const cardBg = Colors.white;
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
  /// Laravel storage link: '/storage'. API /uploads/... qaytarsa, /storage/uploads/... bo'ladi.
  /// 404 bo'lsa: '' qiling. 403 bo'lsa: backend permissions tekshiring.
  static const imagePathPrefix = '';
  static const registerUrl = '$baseUrl/auth/register';
  static const loginUrl = '$baseUrl/auth/login';
  static const verifyOtpUrl = '$baseUrl/auth/verify-otp';
  static const userUrl = '$baseUrl/auth/user';
  static const logoutUrl = '$baseUrl/auth/logout';

  static const categoriesUrl = '$baseUrl/categories';
  static const elonlarUrl = '$baseUrl/elonlar';
  static const imagesUploadUrl = '$baseUrl/elonlar/images/upload';
  static String imageDeleteUrl(int imageId) => '$baseUrl/elonlar/images/$imageId';
  static String elonlarDetail(int id) => '$baseUrl/elonlar/$id';
  static String elonlarImages(int id) => '$baseUrl/elonlar/$id/images';
  static String elonlarImageDelete(int elonId, int imageId) =>
      '$baseUrl/elonlar/$elonId/images/$imageId';
  static const myElonlarUrl = '$baseUrl/elonlar/my/list';
}

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
