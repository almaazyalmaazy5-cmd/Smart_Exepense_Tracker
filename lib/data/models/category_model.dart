import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String nameEn;
  final IconData icon;
  final Color color;
  final bool isExpense;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.color,
    this.isExpense = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'iconCode': icon.codePoint,
      'colorHex': color.toARGB32(),
      'isExpense': isExpense,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      nameEn: map['nameEn'] as String? ?? map['name'] as String,
      icon: IconData(map['iconCode'] as int, fontFamily: 'MaterialIcons'),
      color: Color(map['colorHex'] as int),
      isExpense: map['isExpense'] as bool? ?? true,
    );
  }
}
