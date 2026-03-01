import 'package:flutter/material.dart';

class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String icon;
  final int sortOrder;
  final int elonlarCount;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    this.sortOrder = 0,
    this.elonlarCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawSlug = json['slug'] as String? ?? '';
    final rawIcon = json['icon'] as String? ?? '';
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: rawSlug,
      icon: rawIcon.trim().isEmpty ? _iconFromSlug(rawSlug) : rawIcon,
      sortOrder: json['sort_order'] as int? ?? 0,
      elonlarCount: json['elonlar_count'] as int? ?? 0,
    );
  }

  static String _iconFromSlug(String slug) {
    final s = slug.toLowerCase();
    if (s.contains('settings') || s.contains('sozlama')) return 'settings';
    if (s.contains('moto') || s.contains('bike') || s.contains('motorcycle')) return 'motorcycle';
    if (s.contains('yuk') || s.contains('truck')) return 'truck';
    if (s.contains('traktor') || s.contains('tractor')) return 'tractor';
    return 'car';
  }

  static IconData iconFromString(String icon) {
    final normalized = icon.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

    // Backenddan keladigan asosiy 5 ta icon nomi.
    switch (normalized) {
      case 'car':
        return Icons.directions_car;
      case 'truck':
        return Icons.local_shipping;
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'settings':
        return Icons.settings;
      case 'tractor':
        return Icons.agriculture;
    }

    // Yangi noma'lum nomlar kelsa, nomiga qarab eng yaqin icon tanlanadi.
    if (normalized.contains('truck') || normalized.contains('yuk')) return Icons.local_shipping;
    if (normalized.contains('tractor') || normalized.contains('traktor')) return Icons.agriculture;
    if (normalized.contains('motor') || normalized.contains('moto') || normalized.contains('bike')) {
      return Icons.two_wheeler;
    }
    if (normalized.contains('setting') || normalized.contains('sozlama')) return Icons.settings;
    if (normalized.contains('car') || normalized.contains('avto') || normalized.contains('auto')) {
      return Icons.directions_car;
    }

    return Icons.directions_car;
  }
}
