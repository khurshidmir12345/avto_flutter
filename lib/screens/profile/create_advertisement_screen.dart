import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../services/advertisement_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class CreateAdvertisementScreen extends StatefulWidget {
  const CreateAdvertisementScreen({super.key});

  @override
  State<CreateAdvertisementScreen> createState() => _CreateAdvertisementScreenState();
}

class _CreateAdvertisementScreenState extends State<CreateAdvertisementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _service = AdvertisementService();

  int _days = 1;
  int _dailyPrice = 400000;
  int _slotsRemaining = 10;
  File? _imageFile;
  String? _uploadedImageKey;
  bool _isUploading = false;
  bool _isSubmitting = false;
  bool _showPreview = false;
  bool _priceLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _loadPrice() async {
    final result = await _service.getPrice();
    if (mounted && result != null) {
      setState(() {
        _dailyPrice = result.dailyPrice;
        _slotsRemaining = result.slotsRemaining;
        _priceLoading = false;
      });
    } else if (mounted) {
      setState(() => _priceLoading = false);
    }
  }

  int get _totalPrice => _dailyPrice * _days;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;

    final ext = picked.path.split('.').last.toLowerCase();
    if (!{'jpeg', 'jpg', 'png', 'webp'}.contains(ext)) {
      if (mounted) showSnackBar(context, 'Faqat jpeg, jpg, png, webp ruxsat etiladi', isError: true);
      return;
    }

    final fileSize = await picked.length();
    if (fileSize > 5 * 1024 * 1024) {
      if (mounted) showSnackBar(context, 'Rasm 5MB dan oshmasligi kerak', isError: true);
      return;
    }

    setState(() {
      _imageFile = File(picked.path);
      _uploadedImageKey = null;
    });

    await _uploadImage();
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    final ext = _imageFile!.path.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');

    final presigned = await _service.getPresignedUrl(contentType);
    if (presigned.error != null || presigned.uploadUrl == null) {
      if (mounted) {
        setState(() => _isUploading = false);
        showSnackBar(context, presigned.error ?? 'Xatolik', isError: true);
      }
      return;
    }

    final uploaded = await _service.uploadImageToR2(_imageFile!, presigned.uploadUrl!, contentType);
    if (mounted) {
      setState(() {
        _isUploading = false;
        if (uploaded) {
          _uploadedImageKey = presigned.imageKey;
        }
      });
      if (!uploaded) showSnackBar(context, 'Rasm yuklanmadi', isError: true);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_slotsRemaining <= 0) {
      showSnackBar(context, 'Bugun uchun reklama limiti tugagan', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _service.create(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      imageKey: _uploadedImageKey,
      link: _linkController.text.trim().isNotEmpty ? _linkController.text.trim() : null,
      days: _days,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showSnackBar(context, result.message, isError: !result.success);
    if (result.success) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reklama yaratish'),
        centerTitle: true,
        actions: [
          if (_titleController.text.isNotEmpty)
            IconButton(
              onPressed: () => setState(() => _showPreview = !_showPreview),
              icon: PhosphorIcon(_showPreview ? PhosphorIconsRegular.pencil : PhosphorIconsRegular.eye),
              tooltip: _showPreview ? 'Tahrirlash' : 'Ko\'rish',
            ),
        ],
      ),
      body: _showPreview ? _buildPreview(theme) : _buildForm(theme),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reklama ko\'rinishi:',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  if (_imageFile != null)
                    Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover)
                  else
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: PhosphorIcon(PhosphorIconsRegular.megaphone, size: 64, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: theme.colorScheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleController.text.isNotEmpty ? _titleController.text : 'Sarlavha',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_descriptionController.text.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _descriptionController.text,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Yuborish — ${formatBalance(_totalPrice)}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Narx va limit info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: _priceLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kunlik narx', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                                const SizedBox(height: 4),
                                Text(
                                  formatBalance(_dailyPrice),
                                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Bugun: $_slotsRemaining ta joy',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // Rasm
            Text('Rasm', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  border: Border.all(
                    color: _uploadedImageKey != null
                        ? AppColors.success.withValues(alpha: 0.5)
                        : theme.colorScheme.outlineVariant,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                clipBehavior: Clip.antiAlias,
                child: _isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : _imageFile != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_imageFile!, fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _uploadedImageKey != null ? AppColors.success : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: PhosphorIcon(
                                    _uploadedImageKey != null ? PhosphorIconsRegular.check : PhosphorIconsRegular.arrowsClockwise,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PhosphorIcon(PhosphorIconsRegular.image, size: 40, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(height: 8),
                              Text(
                                'Rasm tanlang',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'jpeg, png, webp • max 5MB',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 20),

            // Sarlavha
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Sarlavha *',
                hintText: 'Masalan: Premium Avto Salon',
                prefixIcon: PhosphorIcon(PhosphorIconsRegular.textT),
              ),
              maxLength: 150,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Sarlavha kiriting';
                if (v.trim().length < 3) return 'Kamida 3 ta belgi';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Tavsif
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Tavsif',
                hintText: 'Reklama haqida qisqacha...',
                prefixIcon: PhosphorIcon(PhosphorIconsRegular.article),
              ),
              maxLines: 3,
              maxLength: 1000,
            ),
            const SizedBox(height: 12),

            // Havola
            TextFormField(
              controller: _linkController,
              decoration: InputDecoration(
                labelText: 'Havola (link)',
                hintText: 'https://t.me/... yoki boshqa havola',
                prefixIcon: PhosphorIcon(PhosphorIconsRegular.link),
              ),
              keyboardType: TextInputType.url,
              maxLength: 500,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final uri = Uri.tryParse(v.trim());
                  if (uri == null || !uri.hasScheme) return 'To\'g\'ri havola kiriting (https://...)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Kunlar soni
            Text('Muddat', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_days kun', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        formatBalance(_totalPrice),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      thumbColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                      overlayColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: Slider(
                      value: _days.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '$_days kun',
                      onChanged: (v) => setState(() => _days = v.round()),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 kun', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      Text('30 kun', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [1, 3, 7, 14, 30].map((d) {
                final isSelected = _days == d;
                return ChoiceChip(
                  label: Text('$d kun'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _days = d),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Jami
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Kunlik narx', formatBalance(_dailyPrice)),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Muddat', '$_days kun'),
                  const Divider(height: 20),
                  _buildSummaryRow(
                    'Jami',
                    formatBalance(_totalPrice),
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Preview va Submit
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _titleController.text.isNotEmpty ? () => setState(() => _showPreview = true) : null,
                    icon: PhosphorIcon(PhosphorIconsRegular.eye),
                    label: const Text('Ko\'rish'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _isSubmitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Yuborish — ${formatBalance(_totalPrice)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Admin tasdiqlashidan keyin reklama faollashadi',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
              : Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: isBold
              ? Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)
              : Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
