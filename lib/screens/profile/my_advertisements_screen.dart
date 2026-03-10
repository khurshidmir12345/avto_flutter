import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/routes.dart';
import '../../models/advertisement_model.dart';
import '../../services/advertisement_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class MyAdvertisementsScreen extends StatefulWidget {
  const MyAdvertisementsScreen({super.key});

  @override
  State<MyAdvertisementsScreen> createState() => _MyAdvertisementsScreenState();
}

class _MyAdvertisementsScreenState extends State<MyAdvertisementsScreen> {
  final _service = AdvertisementService();
  List<AdvertisementModel> _ads = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _service.getMyAds();
    if (mounted) {
      setState(() {
        _ads = result.items;
        _error = result.error;
        _loading = false;
      });
    }
  }

  Future<void> _reactivate(AdvertisementModel ad) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Qayta faollashtirish'),
        content: Text(
          'Bu reklama qayta yuboriladi va balansdan ${formatBalance(ad.totalPrice)} yechiladi. Davom etasizmi?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ha, davom etish')),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _service.reactivate(ad.id);
    if (!mounted) return;
    showSnackBar(context, result.message, isError: !result.success);
    if (result.success) _loadAds();
  }

  Future<void> _deleteAd(AdvertisementModel ad) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('O\'chirish'),
        content: const Text('Bu reklamani o\'chirmoqchimisiz? Pul qaytariladi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _service.delete(ad.id);
    if (!mounted) return;
    showSnackBar(context, result.message, isError: !result.success);
    if (result.success) _loadAds();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mening reklamalarim'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRoutes.createAdvertisement);
          if (result == true) _loadAds();
        },
        icon: PhosphorIcon(PhosphorIconsRegular.plus),
        label: const Text('Yangi reklama'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(PhosphorIconsRegular.warning, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _loadAds, child: const Text('Qayta urinish')),
                    ],
                  ),
                )
              : _ads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PhosphorIcon(PhosphorIconsRegular.megaphone, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'Reklamalar yo\'q',
                            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Birinchi reklamangizni yarating!',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAds,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSizes.paddingMedium),
                        itemCount: _ads.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildAdCard(_ads[index]),
                      ),
                    ),
    );
  }

  Widget _buildAdCard(AdvertisementModel ad) {
    final theme = Theme.of(context);
    final statusColor = switch (ad.status) {
      'pending' => Colors.orange,
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      'expired' => Colors.grey,
      _ => Colors.grey,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ad.imageUrl != null)
            CachedNetworkImage(
              imageUrl: ad.imageUrl!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 160,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 160,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: PhosphorIcon(PhosphorIconsRegular.image, size: 48, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ad.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ad.statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (ad.description != null && ad.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    ad.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(PhosphorIconsRegular.calendarBlank, '${ad.days} kun'),
                    const SizedBox(width: 12),
                    _buildInfoChip(PhosphorIconsRegular.eye, '${ad.views} ko\'rish'),
                    const SizedBox(width: 12),
                    _buildInfoChip(PhosphorIconsRegular.currencyCircleDollar, formatBalance(ad.totalPrice)),
                  ],
                ),
                if (ad.rejectionReason != null && ad.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PhosphorIcon(PhosphorIconsRegular.info, size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ad.rejectionReason!,
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (ad.expiresAt != null && ad.isActive) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tugash: ${formatBalanceHistoryDate(ad.expiresAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (ad.canReactivate)
                      TextButton.icon(
                        onPressed: () => _reactivate(ad),
                        icon: PhosphorIcon(PhosphorIconsRegular.arrowClockwise, size: 18),
                        label: const Text('Qayta yuborish'),
                      ),
                    if (ad.canDelete)
                      TextButton.icon(
                        onPressed: () => _deleteAd(ad),
                        icon: PhosphorIcon(PhosphorIconsRegular.trash, size: 18, color: AppColors.error),
                        label: Text('O\'chirish', style: TextStyle(color: AppColors.error)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
