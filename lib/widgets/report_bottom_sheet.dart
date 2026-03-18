import 'package:flutter/material.dart';
import '../services/moderation_service.dart';
import '../utils/constants.dart';

class ReportBottomSheet extends StatefulWidget {
  final String reportableType;
  final int reportableId;
  final String title;

  const ReportBottomSheet({
    super.key,
    required this.reportableType,
    required this.reportableId,
    this.title = 'Shikoyat qilish',
  });

  static Future<bool?> show(
    BuildContext context, {
    required String reportableType,
    required int reportableId,
    String title = 'Shikoyat qilish',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReportBottomSheet(
        reportableType: reportableType,
        reportableId: reportableId,
        title: title,
      ),
    );
  }

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  String? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  static const _reasons = [
    ('spam', 'Spam', Icons.block),
    ('inappropriate', "Noto'g'ri kontent", Icons.warning_amber_rounded),
    ('fraud', 'Firibgarlik', Icons.gpp_bad_outlined),
    ('offensive', 'Haqoratli', Icons.sentiment_very_dissatisfied),
    ('other', 'Boshqa', Icons.more_horiz),
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;

    setState(() => _isLoading = true);

    final service = ModerationService();
    final result = await service.reportContent(
      reportableType: widget.reportableType,
      reportableId: widget.reportableId,
      reason: _selectedReason!,
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
      ),
    );

    if (result.success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Quyidagi sabablardan birini tanlang',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ..._reasons.map((r) => _ReasonTile(
                    value: r.$1,
                    label: r.$2,
                    icon: r.$3,
                    selected: _selectedReason == r.$1,
                    onTap: () => setState(() => _selectedReason = r.$1),
                  )),
              if (_selectedReason == 'other') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Batafsil yozing...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedReason != null && !_isLoading
                      ? _submit
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Shikoyat yuborish',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.error.withValues(alpha: 0.08)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.error : Colors.grey[200]!,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.error : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: AppColors.error, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
