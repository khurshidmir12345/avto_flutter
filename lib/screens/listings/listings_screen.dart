import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../config/routes.dart';
import '../../models/elon_model.dart';
import '../../services/elonlar_service.dart';
import '../../utils/constants.dart';
import 'elon_detail_screen.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key, this.categoryId});

  final int? categoryId;

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  final _elonlarService = ElonlarService();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  static const int _perPage = 30;
  static const double _scrollThreshold = 300;

  List<ElonModel> _list = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;
  bool _searchExpanded = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void didUpdateWidget(ListingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      _loadInitial();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  static const double _scrollHideSearchThreshold = 80;

  void _onScroll() {
    if (!_scrollController.hasClients || _loading || _loadingMore || !_hasMore) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels <= _scrollThreshold) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final search = _searchQuery.trim().isEmpty ? null : _searchQuery.trim();
    final result = await _elonlarService.getList(
      categoryId: widget.categoryId,
      search: search,
      page: 1,
      perPage: _perPage,
    );
    if (mounted) {
      setState(() {
        _list = result.items;
        _error = result.error;
        _page = 1;
        _hasMore = result.items.length >= _perPage;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    final search = _searchQuery.trim().isEmpty ? null : _searchQuery.trim();
    final result = await _elonlarService.getList(
      categoryId: widget.categoryId,
      search: search,
      page: nextPage,
      perPage: _perPage,
    );

    if (!mounted) return;
    setState(() {
      _list.addAll(result.items);
      _page = nextPage;
      _hasMore = result.items.length >= _perPage;
      _loadingMore = false;
    });
  }

  Future<void> _onRefresh() async {
    // Birinchi tortish: search ochiladi (reload yo'q). Ikkinchi tortish: reload.
    if (!_searchExpanded) {
      setState(() => _searchExpanded = true);
      return;
    }
    await _loadInitial();
  }

  void _onSearchSubmitted(String value) {
    setState(() => _searchQuery = value);
    _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _searchExpanded
                ? SizedBox(
                    height: 56,
                    child: Container(
                      color: theme.colorScheme.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: "Marka yoki model bo'yicha qidirish...",
                        prefixIcon: PhosphorIcon(PhosphorIconsRegular.magnifyingGlass, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: PhosphorIcon(PhosphorIconsRegular.x, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _loadInitial();
                                },
                              )
                            : null,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: _onSearchSubmitted,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      textInputAction: TextInputAction.search,
                    ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification &&
                          notification.metrics.pixels > _scrollHideSearchThreshold &&
                          _searchExpanded) {
                        setState(() => _searchExpanded = false);
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: _error != null
                        ? LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: _errorState(context),
                              ),
                            ),
                          )
                        : _list.isEmpty
                            ? LayoutBuilder(
                                builder: (context, constraints) => SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                    child: _emptyState(context),
                                  ),
                                ),
                              )
                            : GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(left: 1, right: 1, top: 1),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 2,
                                crossAxisSpacing: 2,
                                childAspectRatio: 1 / 1.3,
                              ),
                              itemCount: _list.length + (_loadingMore ? 3 : 0),
                              itemBuilder: (_, i) {
                                if (i >= _list.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(10),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                }
                                return _elonGridItem(context, _list[i]);
                              },
                            ),
                  ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.createElon);
          _loadInitial();
        },
        child: PhosphorIcon(PhosphorIconsRegular.plus),
      ),
    );
  }

  Widget _errorState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(PhosphorIconsRegular.wifiSlash, size: 64, color: AppColors.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'Xatolik yuz berdi',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInitial,
              icon: PhosphorIcon(PhosphorIconsRegular.arrowClockwise, size: 18),
              label: const Text('Qayta yuklash'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(PhosphorIconsRegular.car, size: 80, color: AppColors.primaryLight),
          const SizedBox(height: 16),
          Text(
            "Hozircha e'lonlar yo'q",
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            "Pastdagi + tugmasini bosing",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _elonGridItem(BuildContext context, ElonModel elon) {
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
      child: AspectRatio(
        aspectRatio: 1 / 1.3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (_, __, ___) => _placeholderCell(),
              )
            else
              _placeholderCell(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      elon.narxFormatted,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderCell() {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: PhosphorIcon(PhosphorIconsRegular.car, size: 34, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
    );
  }
}
