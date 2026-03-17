class ReminderModel {
  final String id;
  final String title;
  final double amount;
  final int dueDay;
  final bool isActive;
  final DateTime createdAt;

  const ReminderModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDay,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isDueSoon {
    final now = DateTime.now();
    final diff = dueDay - now.day;
    return diff >= 0 && diff <= 3;
  }

  bool get isOverdue => DateTime.now().day > dueDay;

  factory ReminderModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ReminderModel(
      id: id,
      title: data['title'] as String,
      amount: (data['amount'] as num).toDouble(),
      dueDay: data['dueDay'] as int,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'dueDay': dueDay,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
