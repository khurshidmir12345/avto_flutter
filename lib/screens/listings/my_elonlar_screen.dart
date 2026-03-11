import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../config/routes.dart';
import '../../models/elon_model.dart';
import '../../services/elonlar_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'elon_detail_screen.dart';

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

  Future<void> _markAsSold(ElonModel elon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sotildi deb belgilash'),
        content: Text("\"${elon.marka} ${elon.model ?? ''}\" sotildi deb belgilansinmi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Ha, sotildi'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final result = await _elonlarService.update(elon.id, {'holati': 'sold'});
    if (!mounted) return;

    if (result.success) {
      showSnackBar(context, "E'lon sotildi deb belgilandi");
      _loadInitial();
    } else {
      showSnackBar(context, result.message, isError: true);
    }
  }

  Future<void> _deleteElon(ElonModel elon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("E'lonni o'chirish"),
        content: Text("\"${elon.marka} ${elon.model ?? ''}\" o'chirilsinmi?\nBu amalni qaytarib bo'lmaydi."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final result = await _elonlarService.delete(elon.id);
    if (!mounted) return;

    if (result.success) {
      showSnackBar(context, "E'lon o'chirildi");
      setState(() => _list.removeWhere((e) => e.id == elon.id));
    } else {
      showSnackBar(context, result.message, isError: true);
    }
  }

  void _showElonActions(ElonModel elon) {
    final isSold = elon.holati == 'sold';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  '${elon.marka} ${elon.model ?? ''}'.trim(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: PhosphorIcon(PhosphorIconsRegular.eye, color: AppColors.primary),
                title: const Text("Batafsil ko'rish"),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ElonDetailScreen(elonId: elon.id),
                  ));
                },
              ),
              if (!isSold)
                ListTile(
                  leading: const PhosphorIcon(PhosphorIconsRegular.checkCircle, color: Colors.orange),
                  title: const Text('Sotildi deb belgilash'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _markAsSold(elon);
                  },
                ),
              ListTile(
                leading: PhosphorIcon(PhosphorIconsRegular.trash, color: AppColors.error),
                title: Text("O'chirish", style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteElon(elon);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
    final isSold = elon.holati == 'sold';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ElonDetailScreen(elonId: elon.id),
        ),
      ),
      onLongPress: () => _showElonActions(elon),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              errorWidget: (_, __, ___) => _placeholder(context),
                            )
                          : _placeholder(context),
                      if (isSold)
                        Container(
                          color: Colors.black.withValues(alpha: 0.5),
                          child: const Center(
                            child: Text(
                              'SOTILDI',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              elon.narxFormatted,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSold
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.onSurface,
                                decoration: isSold ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showElonActions(elon),
                            child: PhosphorIcon(
                              PhosphorIconsRegular.dotsThreeVertical,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
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
            if (isSold)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Sotildi',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
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
