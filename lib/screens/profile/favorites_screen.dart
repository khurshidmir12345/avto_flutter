import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../models/elon_model.dart';
import '../../services/favorite_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../listings/elon_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _service = FavoriteService();
  List<ElonModel> _elons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.getFavorites();
    if (mounted) {
      setState(() {
        _elons = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sevimlilar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _elons.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    itemCount: _elons.length,
                    itemBuilder: (context, index) =>
                        _buildElonCard(context, _elons[index], theme),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.heart,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            "Sevimlilar bo'sh",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "E'lonlardagi yurak tugmasini bosing",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElonCard(BuildContext context, ElonModel elon, ThemeData theme) {
    final imageUrl = elon.images.isNotEmpty ? elon.images.first.url : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ElonDetailScreen(elonId: elon.id),
            ),
          );
          _load();
        },
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 90,
                  height: 70,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _imagePlaceholder(),
                          errorWidget: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${elon.marka} ${elon.model ?? ''}'.trim(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      elon.narxFormatted,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${elon.yil} • ${elon.shahar}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PhosphorIcon(
                PhosphorIconsFill.heart,
                color: AppColors.error,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.15),
      child: Center(
        child: PhosphorIcon(
          PhosphorIconsRegular.car,
          size: 28,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }
}
