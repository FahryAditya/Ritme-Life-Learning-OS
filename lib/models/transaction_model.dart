class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final bool isExpense;
  final String category;
  final String date;
  final String createdAt;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.isExpense,
    this.category = 'Umum',
    required this.date,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'is_expense': isExpense ? 1 : 0,
      'category': category,
      'date': date,
      'created_at': createdAt,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      isExpense: (map['is_expense'] as int? ?? 1) == 1,
      category: map['category'] as String? ?? 'Umum',
      date: map['date'] as String? ?? 'Hari ini',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    bool? isExpense,
    String? category,
    String? date,
    String? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      isExpense: isExpense ?? this.isExpense,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
