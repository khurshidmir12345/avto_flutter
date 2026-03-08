import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

    switch (normalized) {
      case 'car':
        return PhosphorIconsRegular.car;
      case 'truck':
        return PhosphorIconsRegular.truck;
      case 'motorcycle':
        return PhosphorIconsRegular.motorcycle;
      case 'settings':
        return PhosphorIconsRegular.gear;
      case 'tractor':
        return PhosphorIconsRegular.tractor;
    }

    if (normalized.contains('truck') || normalized.contains('yuk')) return PhosphorIconsRegular.truck;
    if (normalized.contains('tractor') || normalized.contains('traktor')) return PhosphorIconsRegular.tractor;
    if (normalized.contains('motor') || normalized.contains('moto') || normalized.contains('bike')) {
      return PhosphorIconsRegular.motorcycle;
    }
    if (normalized.contains('setting') || normalized.contains('sozlama')) return PhosphorIconsRegular.gear;
    if (normalized.contains('car') || normalized.contains('avto') || normalized.contains('auto')) {
      return PhosphorIconsRegular.car;
    }

    return PhosphorIconsRegular.car;
  }
}
