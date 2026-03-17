class DebtModel {
  final String id;
  final String personName;
  final double amount;
  final bool isOwedToMe;
  final String? note;
  final DateTime? dueDate;
  final bool isPaid;
  final DateTime createdAt;

  const DebtModel({
    required this.id,
    required this.personName,
    required this.amount,
    required this.isOwedToMe,
    this.note,
    this.dueDate,
    this.isPaid = false,
    required this.createdAt,
  });

  bool get isOverdue =>
      dueDate != null && !isPaid && DateTime.now().isAfter(dueDate!);

  factory DebtModel.fromFirestore(String id, Map<String, dynamic> data) {
    return DebtModel(
      id: id,
      personName: data['personName'] as String,
      amount: (data['amount'] as num).toDouble(),
      isOwedToMe: data['isOwedToMe'] as bool,
      note: data['note'] as String?,
      dueDate: data['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['dueDate'] as int)
          : null,
      isPaid: data['isPaid'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'personName': personName,
      'amount': amount,
      'isOwedToMe': isOwedToMe,
      'note': note,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'isPaid': isPaid,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
