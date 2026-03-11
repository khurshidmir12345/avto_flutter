class BalanceHistoryModel {
  final int id;
  final String type; // credit | debit
  final int amount;
  final int balanceAfter;
  final String description;
  final String createdAt;

  const BalanceHistoryModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
  });

  factory BalanceHistoryModel.fromJson(Map<String, dynamic> json) {
    return BalanceHistoryModel(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'credit',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balance_after'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  bool get isCredit => type == 'credit';
}
