import 'package:flutter/material.dart';
import '../../models/balance_history_model.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class BalanceHistoryScreen extends StatefulWidget {
  const BalanceHistoryScreen({super.key});

  @override
  State<BalanceHistoryScreen> createState() => _BalanceHistoryScreenState();
}

class _BalanceHistoryScreenState extends State<BalanceHistoryScreen> {
  final _apiService = ApiService();
  List<BalanceHistoryModel> _items = [];
  int _total = 0;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = true;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    setState(() => _isLoading = true);

    final result = await _apiService.getBalanceHistory(
      page: _currentPage,
      perPage: 15,
    );

    if (!mounted) return;

    if (result != null) {
      if (refresh) {
        _items = result.items;
      } else {
        _items = [..._items, ...result.items];
      }
      _total = result.total;
      _lastPage = result.lastPage;
      _hasMore = _currentPage < _lastPage;
      _currentPage++;

      if (_items.isNotEmpty) {
        await StorageService.saveBalanceHistoryViewedAt(_items.first.createdAt);
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hisob tarixi'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: _items.isEmpty && !_isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tarix bo\'sh',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Balans harakatlari shu yerda ko\'rinadi',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                itemCount: _items.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    if (!_isLoading) _load();
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final item = _items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.isCredit
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.error.withValues(alpha: 0.2),
                        child: Icon(
                          item.isCredit ? Icons.add : Icons.remove,
                          color: item.isCredit ? AppColors.success : AppColors.error,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        item.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      subtitle: Text(
                        formatBalanceHistoryDate(item.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.isCredit ? '+' : '-'}${formatBalanceAmount(item.amount)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: item.isCredit ? AppColors.success : AppColors.error,
                                ),
                          ),
                          Text(
                            'Qoldiq: ${formatBalanceAmount(item.balanceAfter)} so\'m',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
