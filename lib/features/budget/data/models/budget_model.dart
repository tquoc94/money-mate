class BudgetModel {
  final String categoryId;
  final String categoryName;
  final double limit;
  final int month;
  final int year;
  final bool isPinned;

  const BudgetModel({
    required this.categoryId,
    required this.categoryName,
    required this.limit,
    required this.month,
    required this.year,
    this.isPinned = false,
  });

  factory BudgetModel.fromFirestore(Map<String, dynamic> data) {
    return BudgetModel(
      categoryId: data['categoryId'] as String,
      categoryName: data['categoryName'] as String,
      limit: (data['limit'] as num).toDouble(),
      month: data['month'] as int,
      year: data['year'] as int,
      isPinned: data['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'limit': limit,
      'month': month,
      'year': year,
      'isPinned': isPinned,
    };
  }

  BudgetModel copyWith({bool? isPinned}) {
    return BudgetModel(
      categoryId: categoryId,
      categoryName: categoryName,
      limit: limit,
      month: month,
      year: year,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  String get docId => '${categoryId}_${year}_$month';
}
