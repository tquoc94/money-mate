import 'package:flutter/material.dart';
import 'package:qlct/l10n/app_localizations.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String type;
  final bool isDefault;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  Color get colorValue => Color(int.parse(color.replaceFirst('#', '0xFF')));

  IconData get iconData => _iconMap[icon] ?? Icons.category_rounded;

  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CategoryModel(
      id: id,
      name: data['name'] as String,
      icon: data['icon'] as String,
      color: data['color'] as String,
      type: data['type'] as String,
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'isDefault': isDefault,
    };
  }

  static String localizedName(String categoryId, AppLocalizations l10n) {
    switch (categoryId) {
      case 'food':
        return l10n.categoryFood;
      case 'transport':
        return l10n.categoryTransport;
      case 'housing':
        return l10n.categoryHousing;
      case 'shopping':
        return l10n.categoryShopping;
      case 'entertainment':
        return l10n.categoryEntertainment;
      case 'health':
        return l10n.categoryHealth;
      case 'education':
        return l10n.categoryEducation;
      case 'bills':
        return l10n.categoryBills;
      case 'salary':
        return l10n.categorySalary;
      case 'gift':
        return l10n.categoryGift;
      case 'investment':
        return l10n.categoryInvestment;
      case 'other_income':
        return l10n.categoryOtherIncome;
      default:
        return categoryId;
    }
  }

  static const Map<String, IconData> _iconMap = {
    'food': Icons.restaurant_rounded,
    'transport': Icons.directions_car_rounded,
    'housing': Icons.home_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'entertainment': Icons.sports_esports_rounded,
    'health': Icons.medical_services_rounded,
    'education': Icons.school_rounded,
    'bills': Icons.receipt_long_rounded,
    'salary': Icons.work_rounded,
    'gift': Icons.card_giftcard_rounded,
    'investment': Icons.trending_up_rounded,
    'other_income': Icons.attach_money_rounded,
  };

  static List<CategoryModel> get defaultCategories => [
    const CategoryModel(
      id: 'food',
      name: 'Ăn uống',
      icon: 'food',
      color: '#F97316',
      type: 'expense',
      isDefault: true,
    ),
    const CategoryModel(
      id: 'transport',
      name: 'Đi lại',
      icon: 'transport',
      color: '#3B82F6',
      type: 'expense',
      isDefault: true,
    ),
    const CategoryModel(
      id: 'housing',
      name: 'Nhà cửa',
      icon: 'housing',
      color: '#8B5CF6',
      type: 'expense',
      isDefault: true,
    ),
    const CategoryModel(
      id: 'shopping',
      name: 'Mua sắm',
      icon: 'shopping',
      color: '#EC4899',
      type: 'expense',
      isDefault: true,
    ),
    const CategoryModel(
      id: 'entertainment',
      name: 'Giải trí',
      icon: 'entertainment',
      color: '#14B8A6',
      type: 'expense',
      isDefault: true,
    ),
    const CategoryModel(
      id: 'health',
      name: 'Sức khỏe',
      icon: 'health',
      color: '#EF4444',
      type: 'expense',
      isDefault: true,
    ),
    const CategoryModel(
      id: 'education',
      name: 'Giáo dục',
      icon: 'education',
      color: '#6366F1',
      type: 'expense',
      isDefault: true,
    ),
    const CategoryModel(
      id: 'bills',
      name: 'Hóa đơn',
      icon: 'bills',
      color: '#F59E0B',
      type: 'expense',
      isDefault: true,
    ),
    const CategoryModel(
      id: 'salary',
      name: 'Lương',
      icon: 'salary',
      color: '#10B981',
      type: 'income',
      isDefault: true,
    ),
    const CategoryModel(
      id: 'gift',
      name: 'Quà tặng',
      icon: 'gift',
      color: '#F43F5E',
      type: 'income',
      isDefault: true,
    ),
    const CategoryModel(
      id: 'investment',
      name: 'Đầu tư',
      icon: 'investment',
      color: '#0EA5E9',
      type: 'income',
      isDefault: true,
    ),
    const CategoryModel(
      id: 'other_income',
      name: 'Thu nhập khác',
      icon: 'other_income',
      color: '#84CC16',
      type: 'income',
      isDefault: true,
    ),
  ];
}
