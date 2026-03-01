import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../utils/constants.dart';

class CategoriesService {
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.categoriesUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List? ?? [];
        return list
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
    } catch (_) {}
    return [];
  }
}
