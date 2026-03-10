import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../config/routes.dart';
import '../../models/elon_model.dart';
import '../../services/elonlar_service.dart';
import '../../utils/constants.dart';
import 'elon_detail_screen.dart';

/// Mening e'lonlarim — soddalik va qulaylik ustida qurilgan.
class MyElonlarScreen extends StatefulWidget {
  const MyElonlarScreen({super.key});

  @override
  State<MyElonlarScreen> createState() => _MyElonlarScreenState();
}

class _MyElonlarScreenState extends State<MyElonlarScreen> {
  final _elonlarService = ElonlarService();
  final _scrollController = ScrollController();
  static const int _perPage = 30;
  static const double _scrollThreshold = 300;

  List<ElonModel> _list = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loading || _loadingMore || !_hasMore) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels <= _scrollThreshold) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    final result = await _elonlarService.getMyList(page: 1, perPage: _perPage);
    if (mounted) {
      setState(() {
        _list = result.items;
        _page = 1;
        _hasMore = result.items.length >= _perPage;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    final result = await _elonlarService.getMyList(page: _page + 1, perPage: _perPage);
    if (!mounted) return;
    setState(() {
      _list.addAll(result.items);
      _page++;
      _hasMore = result.items.length >= _perPage;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mening e'lonlarim"),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? _emptyState(context)
              : RefreshIndicator(
                  onRefresh: _loadInitial,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1 / 1.3,
                    ),
                    itemCount: _list.length + (_loadingMore ? 2 : 0),
                    itemBuilder: (_, i) {
                      if (i >= _list.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return _elonCard(context, _list[i]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.createElon);
          _loadInitial();
        },
        icon: PhosphorIcon(PhosphorIconsRegular.plus),
        label: const Text("E'lon qo'shish"),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(PhosphorIconsRegular.car, size: 72, color: AppColors.primaryLight),
            const SizedBox(height: 24),
            Text(
              "Sizda hozircha e'lon yo'q",
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Pastdagi tugmani bosing va yangi e'lon qo'shing",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.createElon);
                _loadInitial();
              },
              icon: PhosphorIcon(PhosphorIconsRegular.plus),
              label: const Text("E'lon qo'shish"),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _elonCard(BuildContext context, ElonModel elon) {
    final theme = Theme.of(context);
    final firstImage = elon.images.isNotEmpty ? elon.images.first : null;
    final imageUrl = firstImage != null && firstImage.url.isNotEmpty ? firstImage.url : null;
    final title = '${elon.marka} ${elon.model ?? ''}'.trim();
    final subtitle = '${elon.yil} • ${elon.probeg} km';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ElonDetailScreen(elonId: elon.id),
        ),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (_, __, ___) => _placeholder(context),
                    )
                  : _placeholder(context),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    elon.narxFormatted,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (title.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: PhosphorIcon(PhosphorIconsRegular.car, size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
    );
  }
}
