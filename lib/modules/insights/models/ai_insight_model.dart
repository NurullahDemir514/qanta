import 'package:flutter/material.dart';

/// AI Insight Model
class AIInsight {
  final String id;
  final String type; // 'category', 'trend', 'recommendation', 'warning', 'summary'
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final double? amount;
  final double? percentage;
  final int? transactionCount;
  final String? categoryId;
  final DateTime generatedAt;
  final Map<String, dynamic> metadata;

  AIInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.amount,
    this.percentage,
    this.transactionCount,
    this.categoryId,
    DateTime? generatedAt,
    this.metadata = const {},
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: _iconFromString(json['icon'] ?? ''),
      color: _colorFromString(json['color'] ?? '#6D6D70'),
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      percentage: json['percentage'] != null ? (json['percentage'] as num).toDouble() : null,
      transactionCount: json['transactionCount'] as int?,
      categoryId: json['categoryId'] as String?,
      generatedAt: json['generatedAt'] != null 
          ? DateTime.parse(json['generatedAt']) 
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'icon': icon.codePoint,
      'color': '#${color.value.toRadixString(16).padLeft(8, '0')}',
      'amount': amount,
      'percentage': percentage,
      'transactionCount': transactionCount,
      'categoryId': categoryId,
      'generatedAt': generatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  static IconData _iconFromString(String iconStr) {
    try {
      final codePoint = int.tryParse(iconStr);
      if (codePoint != null) {
        return IconData(codePoint, fontFamily: 'MaterialIcons');
      }
    } catch (e) {
      // Fallback
    }
    return Icons.insights;
  }

  static Color _colorFromString(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0x')));
    } catch (e) {
      return const Color(0xFF6D6D70);
    }
  }
}

/// AI Insights Summary
class AIInsightsSummary {
  final String overview;
  final double totalExpenses;
  final double totalIncome;
  final double netBalance;
  final double savingsRate;
  final List<AIInsight> insights;
  final DateTime generatedAt;

  AIInsightsSummary({
    required this.overview,
    required this.totalExpenses,
    required this.totalIncome,
    required this.netBalance,
    required this.savingsRate,
    required this.insights,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory AIInsightsSummary.fromJson(Map<String, dynamic> json) {
    return AIInsightsSummary(
      overview: json['overview'] ?? '',
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      netBalance: (json['netBalance'] ?? 0).toDouble(),
      savingsRate: (json['savingsRate'] ?? 0).toDouble(),
      insights: (json['insights'] as List<dynamic>?)
          ?.map((item) => AIInsight.fromJson(item))
          .toList() ?? [],
      generatedAt: json['generatedAt'] != null 
          ? DateTime.parse(json['generatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overview': overview,
      'totalExpenses': totalExpenses,
      'totalIncome': totalIncome,
      'netBalance': netBalance,
      'savingsRate': savingsRate,
      'insights': insights.map((i) => i.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}




