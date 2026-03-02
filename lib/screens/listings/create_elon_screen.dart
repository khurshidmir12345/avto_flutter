import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/routes.dart';
import '../../models/category_model.dart';
import '../../services/api_service.dart';
import '../../services/categories_service.dart';
import '../../services/elonlar_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/image_compress.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/phone_field.dart';

class CreateElonScreen extends StatefulWidget {
  const CreateElonScreen({super.key});

  @override
  State<CreateElonScreen> createState() => _CreateElonScreenState();
}

class _CreateElonScreenState extends State<CreateElonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _elonlarService = ElonlarService();
  final _apiService = ApiService();
  final _categoriesService = CategoriesService();

  final _markaController = TextEditingController();
  final _modelController = TextEditingController();
  final _yilController = TextEditingController();
  final _probegController = TextEditingController();
  final _narxController = TextEditingController();
  final _rangController = TextEditingController();
  final _shaharController = TextEditingController();
  final _telefonController = TextEditingController();
  final _tavsifController = TextEditingController();
  final _kraskaController = TextEditingController();

  int? _selectedCategoryId;
  List<CategoryModel> _categories = [];
  String _valyuta = 'USD';
  String _yoqilgiTuri = 'benzin';
  String _uzatishQutisi = 'mexanika';
  bool _bankKredit = false;
  bool _general = false;

  List<File> _images = [];
  List<int> _uploadedImageIds = [];
  bool _isLoading = false;
  bool _isUploadingImages = false;
  String _loadingStatus = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await _categoriesService.getCategories();
    if (mounted && list.isNotEmpty) {
      setState(() {
        _categories = list;
        _selectedCategoryId ??= list.first.id;
      });
    }
  }

  Future<void> _loadUser() async {
    final user = await _apiService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _telefonController.text = user.phone.replaceAll(RegExp(r'\D'), '').substring(3);
      });
    }
  }

  @override
  void dispose() {
    _markaController.dispose();
    _modelController.dispose();
    _yilController.dispose();
    _probegController.dispose();
    _narxController.dispose();
    _rangController.dispose();
    _shaharController.dispose();
    _telefonController.dispose();
    _tavsifController.dispose();
    _kraskaController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    final newFiles = picked.map((x) => File(x.path)).toList();
    if (_images.length + newFiles.length > 10) {
      newFiles.removeRange(10 - _images.length, newFiles.length);
    }
    if (newFiles.isEmpty) return;

    setState(() => _isUploadingImages = true);

    try {
      final compressed = await compressImages(newFiles);
      if (!mounted) return;

      final result = await _elonlarService.uploadImagesBeforeElon(
        compressed.map((f) => f.path).toList(),
      );

      if (!mounted) return;

      if (!result.success) {
        showSnackBar(context, result.message, isError: true);
        return;
      }

      setState(() {
        _images.addAll(compressed);
        _uploadedImageIds.addAll(result.imageIds);
      });
      showSnackBar(context, result.message);
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Xatolik: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImages = false);
      }
    }
  }

  Future<void> _removeImage(int index) async {
    if (index < _uploadedImageIds.length) {
      await _elonlarService.deleteUnlinkedImage(_uploadedImageIds[index]);
    }
    setState(() {
      _images.removeAt(index);
      if (index < _uploadedImageIds.length) {
        _uploadedImageIds.removeAt(index);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = '998${_telefonController.text.replaceAll(RegExp(r'\D'), '')}';
    if (phone.length != 12) {
      showSnackBar(context, 'Telefon raqam noto\'g\'ri', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingStatus = "E'lon yaratilmoqda...";
    });

    if (_selectedCategoryId == null) {
      showSnackBar(context, 'Kategoriyani tanlang', isError: true);
      return;
    }

    final body = <String, dynamic>{
      'category_id': _selectedCategoryId,
      'marka': _markaController.text.trim(),
      'yil': int.tryParse(_yilController.text) ?? DateTime.now().year,
      'probeg': int.tryParse(_probegController.text) ?? 0,
      'narx': double.tryParse(_narxController.text.replaceAll(' ', '')) ?? 0,
      'valyuta': _valyuta,
      'yoqilgi_turi': _yoqilgiTuri,
      'uzatish_qutisi': _uzatishQutisi,
      'shahar': _shaharController.text.trim(),
      'telefon': phone,
      'bank_kredit': _bankKredit,
      'general': _general,
    };
    final model = _modelController.text.trim();
    if (model.isNotEmpty) body['model'] = model;
    final rang = _rangController.text.trim();
    if (rang.isNotEmpty) body['rang'] = rang;
    final kraska = _kraskaController.text.trim();
    if (kraska.isNotEmpty) body['kraska_holati'] = kraska;
    final tavsif = _tavsifController.text.trim();
    if (tavsif.isNotEmpty) body['tavsif'] = tavsif;
    if (_uploadedImageIds.isNotEmpty) body['image_ids'] = _uploadedImageIds;

    final result = await _elonlarService.create(body);

    if (!mounted) return;

    if (!result.success) {
      setState(() => _isLoading = false);
      showSnackBar(context, result.message, isError: true);
      return;
    }

    setState(() => _isLoading = false);
    showSnackBar(context, result.message);
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("E'lon qo'shish")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Rasmlar'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isUploadingImages ? null : _pickImages,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: _images.isEmpty
                      ? Center(
                          child: _isUploadingImages
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 8),
                                    Text('Yuklanmoqda...'),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 36, color: AppColors.primary),
                                    const SizedBox(height: 4),
                                    Text('Rasm qo\'shish', style: TextStyle(color: AppColors.primary)),
                                  ],
                                ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(8),
                          itemCount: _images.length + (_images.length < 10 ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _images.length) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _addPhotoChip(
                                  onTap: _isUploadingImages ? () {} : _pickImages,
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(_images[i], width: 84, height: 84, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: _isUploadingImages ? null : () => _removeImage(i),
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Kategoriya'),
              DropdownButtonFormField<int>(
                value: _categories.isEmpty ? null : _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Kategoriya',
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
                ),
                hint: _categories.isEmpty
                    ? const Text('Kategoriyalar yuklanmoqda...')
                    : null,
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Icon(CategoryModel.iconFromString(c.icon), size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(c.name),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) => v == null ? 'Kategoriyani tanlang' : null,
              ),
              const SizedBox(height: 20),
              _sectionTitle('Asosiy ma\'lumotlar'),
              CustomTextField(
                label: 'Marka',
                controller: _markaController,
                prefixIcon: Icons.directions_car,
                validator: (v) => (v == null || v.isEmpty) ? 'Marka kiriting' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Model (ixtiyoriy)',
                controller: _modelController,
                prefixIcon: Icons.car_repair,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Yil',
                      controller: _yilController,
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.isEmpty) ? 'Yil kiriting' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Probeg (km)',
                      controller: _probegController,
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.isEmpty) ? 'Probeg kiriting' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Narx',
                      controller: _narxController,
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.isEmpty) ? 'Narx kiriting' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _valyuta,
                      decoration: InputDecoration(
                        labelText: 'Valyuta',
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
                      ),
                      items: ElonOptions.valyuta.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _valyuta = v ?? 'USD'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(label: 'Rang (ixtiyoriy)', controller: _rangController),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _yoqilgiTuri,
                decoration: InputDecoration(
                  labelText: 'Yoqilg\'i turi',
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
                ),
                items: ElonOptions.yoqilgiTuri.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _yoqilgiTuri = v ?? 'benzin'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _uzatishQutisi,
                decoration: InputDecoration(
                  labelText: 'Uzatish qutisi',
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
                ),
                items: ElonOptions.uzatishQutisi.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _uzatishQutisi = v ?? 'mexanika'),
              ),
              const SizedBox(height: 12),
              CustomTextField(label: 'Kraska holati (ixtiyoriy)', controller: _kraskaController),
              const SizedBox(height: 20),
              _sectionTitle('Aloqa'),
              CustomTextField(
                label: 'Shahar',
                controller: _shaharController,
                validator: (v) => (v == null || v.isEmpty) ? 'Shahar kiriting' : null,
              ),
              const SizedBox(height: 12),
              PhoneField(
                controller: _telefonController,
                validator: (v) {
                  final d = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                  if (d.length != 9) return '9 ta raqam kiriting';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _sectionTitle('Qo\'shimcha'),
              CustomTextField(
                label: 'Tavsif (ixtiyoriy)',
                controller: _tavsifController,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Bank kredit'),
                value: _bankKredit,
                onChanged: (v) => setState(() => _bankKredit = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('General'),
                value: _general,
                onChanged: (v) => setState(() => _general = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
                  CustomButton(
                    text: "E'lon joylash",
                    onPressed: _submit,
                    isLoading: _isLoading,
                    loadingText: _loadingStatus.isNotEmpty ? _loadingStatus : null,
                  ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
    );
  }

  Widget _addPhotoChip({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Icon(Icons.add, size: 32, color: AppColors.primary),
      ),
    );
  }
}
