import 'package:flutter/material.dart';
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
    final list = await _elonlarService.getList(
      categoryId: widget.categoryId,
      page: 1,
      perPage: _perPage,
    );
    if (mounted) {
      setState(() {
        _list = list;
        _page = 1;
        _hasMore = list.length >= _perPage;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    final nextList = await _elonlarService.getList(
      categoryId: widget.categoryId,
      page: nextPage,
      perPage: _perPage,
    );

    if (!mounted) return;
    setState(() {
      _list.addAll(nextList);
      _page = nextPage;
      _hasMore = nextList.length >= _perPage;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? _emptyState(context)
              : RefreshIndicator(
                  onRefresh: _loadInitial,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(left: 1, right: 1, top: 1),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      childAspectRatio: 1,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.createElon);
          _loadInitial();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined, size: 80, color: AppColors.primaryLight),
          const SizedBox(height: 16),
          Text(
            "Hozircha e'lonlar yo'q",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            "Pastdagi + tugmasini bosing",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => _placeholderCell(),
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
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
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
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.2),
      child: Icon(Icons.directions_car, size: 40, color: AppColors.primaryLight),
    );
  }
}
