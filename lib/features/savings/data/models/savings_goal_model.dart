class SavingsGoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String icon;
  final String color;
  final DateTime createdAt;

  const SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.icon = 'savings',
    this.color = '4CAF50',
    required this.createdAt,
  });

  double get percentage => targetAmount > 0 ? currentAmount / targetAmount : 0;
  bool get isCompleted => currentAmount >= targetAmount;
  double get remaining => targetAmount - currentAmount;

  factory SavingsGoalModel.fromFirestore(String id, Map<String, dynamic> data) {
    return SavingsGoalModel(
      id: id,
      name: data['name'] as String,
      targetAmount: (data['targetAmount'] as num).toDouble(),
      currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0,
      icon: data['icon'] as String? ?? 'savings',
      color: data['color'] as String? ?? '4CAF50',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'icon': icon,
      'color': color,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
