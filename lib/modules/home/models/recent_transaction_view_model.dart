import 'package:flutter/material.dart';

class TransactionModel {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final double amount;
  final Color color;

  const TransactionModel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.amount,
    required this.color,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      time: json['time'] as String,
      amount: (json['amount'] as num).toDouble(),
      color: Color(json['colorValue'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'iconCodePoint': icon.codePoint,
      'title': title,
      'subtitle': subtitle,
      'time': time,
      'amount': amount,
      'colorValue': color.value,
    };
  }

  TransactionModel copyWith({
    IconData? icon,
    String? title,
    String? subtitle,
    String? time,
    double? amount,
    Color? color,
  }) {
    return TransactionModel(
      icon: icon ?? this.icon,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      time: time ?? this.time,
      amount: amount ?? this.amount,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TransactionModel &&
      other.icon == icon &&
      other.title == title &&
      other.subtitle == subtitle &&
      other.time == time &&
      other.amount == amount &&
      other.color == color;
  }

  @override
  int get hashCode {
    return icon.hashCode ^
      title.hashCode ^
      subtitle.hashCode ^
      time.hashCode ^
      amount.hashCode ^
      color.hashCode;
  }

  @override
  String toString() {
    return 'TransactionModel(icon: $icon, title: $title, subtitle: $subtitle, time: $time, amount: $amount, color: $color)';
  }
} 