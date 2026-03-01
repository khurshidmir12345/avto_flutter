import 'package:flutter/material.dart';
import '../../models/elon_model.dart';
import '../../services/elonlar_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class ElonDetailScreen extends StatefulWidget {
  const ElonDetailScreen({super.key, required this.elonId});

  final int elonId;

  @override
  State<ElonDetailScreen> createState() => _ElonDetailScreenState();
}

class _ElonDetailScreenState extends State<ElonDetailScreen> {
  final _elonlarService = ElonlarService();
  ElonModel? _elon;
  bool _loading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final elon = await _elonlarService.getById(widget.elonId);
    if (mounted) {
      setState(() {
        _elon = elon;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("E'lon")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_elon == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("E'lon")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text("E'lon topilmadi"),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Orqaga'),
              ),
            ],
          ),
        ),
      );
    }

    final elon = _elon!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("E'lon"),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagesSection(elon),
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(elon),
                    const SizedBox(height: 16),
                    _buildInfoCard(elon),
                    if (elon.tavsif != null && elon.tavsif!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildTavsifCard(elon),
                    ],
                    if (elon.telefon.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildContactSection(elon),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagesSection(ElonModel elon) {
    if (elon.images.isEmpty) {
      return _placeholderImage();
    }

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            itemCount: elon.images.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (_, i) {
              final img = elon.images[i];
              return Image.network(
                img.url,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, e, s) => _placeholderImage(),
              );
            },
          ),
        ),
        if (elon.images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              elon.images.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentImageIndex == i ? 10 : 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == i
                      ? AppColors.primary
                      : AppColors.primaryLight.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 280,
      width: double.infinity,
      color: AppColors.primaryLight.withValues(alpha: 0.2),
      child: Icon(Icons.directions_car, size: 80, color: AppColors.primaryLight),
    );
  }

  Widget _buildHeaderCard(ElonModel elon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            elon.narxFormatted,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${elon.marka} ${elon.model ?? ''}'.trim(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ElonModel elon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildInfoSection(elon),
    );
  }

  Widget _buildTavsifCard(ElonModel elon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tavsif',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            elon.tavsif!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(ElonModel elon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aloqa',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            formatPhone(elon.telefon),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => launchPhone(elon.telefon),
              icon: const Icon(Icons.phone, size: 20),
              label: const Text('Qo\'ng\'iroq qilish'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ElonModel elon) {
    final modelName = '${elon.marka} ${elon.model ?? ''}'.trim();
    final items = <_InfoItem>[
      if (modelName.isNotEmpty) _InfoItem(Icons.directions_car, 'Moshina', modelName),
      _InfoItem(Icons.calendar_today, 'Yil', '${elon.yil}'),
      _InfoItem(Icons.straighten, 'Probeg', '${elon.probeg} km'),
      _InfoItem(Icons.location_on, 'Shahar', elon.shahar),
    ];
    if (elon.rang != null && elon.rang!.isNotEmpty) {
      items.add(_InfoItem(Icons.palette, 'Rang', elon.rang!));
    }
    if (elon.yoqilgiTuri != null && elon.yoqilgiTuri!.isNotEmpty) {
      items.add(_InfoItem(Icons.local_gas_station, 'Yoqilg\'i', elon.yoqilgiTuri!));
    }
    if (elon.uzatishQutisi != null && elon.uzatishQutisi!.isNotEmpty) {
      items.add(_InfoItem(Icons.settings, 'Uzatish qutisi', elon.uzatishQutisi!));
    }
    if (elon.kraskaHolati != null && elon.kraskaHolati!.isNotEmpty) {
      items.add(_InfoItem(Icons.brush, 'Kraska holati', elon.kraskaHolati!));
    }
    if (elon.bankKredit == true) {
      items.add(_InfoItem(Icons.account_balance, 'Bank kredit', 'Ha'));
    }
    if (elon.general == true) {
      items.add(_InfoItem(Icons.check_circle, 'General', 'Ha'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((e) => _infoRow(e.icon, e.label, e.value)).toList(),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withValues(alpha: 0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem(this.icon, this.label, this.value);
}
