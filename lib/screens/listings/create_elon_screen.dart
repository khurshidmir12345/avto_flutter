import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/routes.dart';
import '../../models/category_model.dart';
import '../../services/api_service.dart';
import '../../services/categories_service.dart';
import '../../services/elonlar_service.dart';
import '../../services/image_upload_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/image_compress.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/phone_field.dart';

/// Bitta rasm yuklash holati
class _ImageUploadItem {
  final File file;
  String status; // pending, uploading, success, error
  double progress;
  int? imageId;
  String? errorMessage;

  _ImageUploadItem({
    required this.file,
    this.status = 'pending',
    this.progress = 0.0,
    this.imageId,
    this.errorMessage,
  });
}

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
  final _imageUploadService = ImageUploadService();

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

  List<_ImageUploadItem> _imageItems = [];
  bool _isUploading = false;
  bool _isSubmitting = false;
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
        _telefonController.text =
            user.phone.replaceAll(RegExp(r'\D'), '').substring(3);
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

  bool get _hasAnyUploading =>
      _imageItems.any((i) => i.status == 'uploading' || i.status == 'pending');
  bool get _allUploadsSuccess =>
      _imageItems.isNotEmpty &&
      _imageItems.every((i) => i.status == 'success');
  List<int> get _uploadedImageIds =>
      _imageItems.where((i) => i.imageId != null).map((i) => i.imageId!).toList();

  Future<void> _pickImages() async {
    if (_imageItems.length >= maxImages) {
      showSnackBar(context, 'Maksimal $maxImages ta rasm yuklash mumkin',
          isError: true);
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    final remainingSlots = maxImages - _imageItems.length;
    var newFiles = picked.map((x) => File(x.path)).toList();
    if (newFiles.length > remainingSlots) {
      showSnackBar(
          context,
          'Faqat $remainingSlots ta qo\'shish mumkin. Maksimal $maxImages ta rasm.',
          isError: true);
      newFiles = newFiles.take(remainingSlots).toList();
    }
    if (newFiles.isEmpty) return;

    setState(() => _isUploading = true);

    List<File> compressed;
    try {
      compressed = await compressImages(newFiles);
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        showSnackBar(context, 'Rasm siqishda xatolik: $e', isError: true);
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isUploading = false;
      for (final f in compressed) {
        _imageItems.add(_ImageUploadItem(file: f, status: 'pending'));
      }
    });

    _startUpload();
  }

  Future<void> _startUpload() async {
    final pending = _imageItems.where((i) => i.status == 'pending').toList();
    if (pending.isEmpty) return;

    setState(() => _isUploading = true);

    final files = pending.map((i) => i.file).toList();
    final pendingIndices =
        pending.map((i) => _imageItems.indexOf(i)).toList();

    double _lastProgress = -1;
    final result = await _imageUploadService.uploadImagesBeforeElon(
      files,
      onImageProgress: (index, sent, total) {
        if (!mounted) return;
        final idx = pendingIndices[index];
        if (idx < 0 || idx >= _imageItems.length) return;
        final p = total > 0 ? sent / total : 0.0;
        if ((p - _lastProgress).abs() > 0.02 || p >= 1) {
          _lastProgress = p;
          setState(() {
            _imageItems[idx].progress = p;
          });
        }
      },
      onImageStatus: (index, status) {
        if (!mounted) return;
        final idx = pendingIndices[index];
        if (idx >= 0 && idx < _imageItems.length) {
          setState(() {
            _imageItems[idx].status = status;
            if (status == 'success') _imageItems[idx].progress = 1.0;
          });
        }
      },
    );

    if (!mounted) return;

    for (var i = 0; i < pendingIndices.length && i < result.imageIds.length; i++) {
      final idx = pendingIndices[i];
      setState(() => _imageItems[idx].imageId = result.imageIds[i]);
    }

    if (result.success) {
      showSnackBar(context, result.message);
    } else {
      final failedIdx =
          _imageItems.indexWhere((i) => i.status == 'uploading' || i.status == 'error');
      if (failedIdx >= 0) {
        setState(() {
          _imageItems[failedIdx].status = 'error';
          _imageItems[failedIdx].errorMessage = result.message;
        });
      }
      showSnackBar(context, result.message, isError: true);
    }

    setState(() => _isUploading = false);
  }

  Future<void> _retryUpload(int index) async {
    if (index < 0 || index >= _imageItems.length) return;
    final item = _imageItems[index];
    if (item.status != 'error') return;

    setState(() {
      item.status = 'pending';
      item.progress = 0;
      item.errorMessage = null;
    });
    _startUpload();
  }

  Future<void> _removeImage(int index) async {
    if (index < 0 || index >= _imageItems.length) return;
    final item = _imageItems[index];
    if (item.imageId != null) {
      await _elonlarService.deleteUnlinkedImage(item.imageId!);
    }
    setState(() => _imageItems.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final phone =
        '998${_telefonController.text.replaceAll(RegExp(r'\D'), '')}';
    if (phone.length != 12) {
      showSnackBar(context, 'Telefon raqam noto\'g\'ri', isError: true);
      return;
    }

    if (_selectedCategoryId == null) {
      showSnackBar(context, 'Kategoriyani tanlang', isError: true);
      return;
    }

    if (_hasAnyUploading) {
      showSnackBar(context, 'Rasmlar yuklanmoqda, kuting', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _loadingStatus = "E'lon yaratilmoqda...";
    });

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

    setState(() => _isSubmitting = false);

    if (!result.success) {
      showSnackBar(context, result.message, isError: true);
      return;
    }

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
              Text(
                '${_imageItems.length}/$maxImages rasm yuklandi',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              if (_imageItems.length >= maxImages)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Maksimal $maxImages ta rasm yuklash mumkin',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              _buildImageSection(),
              const SizedBox(height: 20),
              _sectionTitle('Kategoriya'),
              DropdownButtonFormField<int>(
                value: _categories.isEmpty ? null : _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Kategoriya',
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadius)),
                ),
                hint: _categories.isEmpty
                    ? const Text('Kategoriyalar yuklanmoqda...')
                    : null,
                items: _categories
                    .map(
                        (c) => DropdownMenuItem(
                              value: c.id,
                              child: Row(
                                children: [
                                  Icon(CategoryModel.iconFromString(c.icon),
                                      size: 20, color: AppColors.primary),
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
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Marka kiriting' : null,
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
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Yil kiriting' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Probeg (km)',
                      controller: _probegController,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Probeg kiriting' : null,
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
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Narx kiriting' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _valyuta,
                      decoration: InputDecoration(
                        labelText: 'Valyuta',
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppSizes.borderRadius)),
                      ),
                      items: ElonOptions.valyuta
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _valyuta = v ?? 'USD'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                  label: 'Rang (ixtiyoriy)', controller: _rangController),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _yoqilgiTuri,
                decoration: InputDecoration(
                  labelText: 'Yoqilg\'i turi',
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadius)),
                ),
                items: ElonOptions.yoqilgiTuri
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _yoqilgiTuri = v ?? 'benzin'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _uzatishQutisi,
                decoration: InputDecoration(
                  labelText: 'Uzatish qutisi',
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadius)),
                ),
                items: ElonOptions.uzatishQutisi
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _uzatishQutisi = v ?? 'mexanika'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                  label: 'Kraska holati (ixtiyoriy)',
                  controller: _kraskaController),
              const SizedBox(height: 20),
              _sectionTitle('Aloqa'),
              CustomTextField(
                label: 'Shahar',
                controller: _shaharController,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Shahar kiriting' : null,
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
              if (_hasAnyUploading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rasmlar yuklanmoqda...',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              CustomButton(
                text: "E'lon joylash",
                onPressed: (_hasAnyUploading || _isSubmitting) ? null : () => _submit(),
                isLoading: _isSubmitting,
                loadingText:
                    _loadingStatus.isNotEmpty ? _loadingStatus : null,
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

  Widget _buildImageSection() {
    final canAddMore =
        _imageItems.length < maxImages && !_isUploading;
    const crossAxisCount = 4;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: AppColors.primaryLight),
      ),
      padding: const EdgeInsets.all(8),
      child: _imageItems.isEmpty && !_isUploading
          ? _buildEmptyState()
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _imageItems.length + (canAddMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _imageItems.length) {
                  return _buildAddButton();
                }
                return _buildImagePreview(i);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _pickImages,
      child: SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 36, color: AppColors.primary),
              const SizedBox(height: 4),
              Text('Rasm qo\'shish',
                  style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Icon(Icons.add, size: 32, color: AppColors.primary),
      ),
    );
  }

  Widget _buildImagePreview(int index) {
    final item = _imageItems[index];
    final isUploading = item.status == 'uploading' || item.status == 'pending';
    final isError = item.status == 'error';

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            item.file,
            fit: BoxFit.cover,
          ),
        ),
        if (isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        value: item.progress > 0 ? item.progress : null,
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(item.progress * 100).round()}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (isError)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    'Xatolik',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () => _retryUpload(index),
                    icon: Icon(Icons.refresh, size: 16, color: Colors.white),
                    label: Text('Qayta urinish',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: _isUploading ? null : () => _removeImage(index),
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
