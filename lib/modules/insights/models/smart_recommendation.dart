import 'package:flutter/material.dart';

class SmartRecommendation {
  final String id;
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final RecommendationPriority priority;
  final double potentialSavings;
  final bool actionable;
  final DateTime generatedAt;
  final Map<String, dynamic> metadata;

  SmartRecommendation({
    required this.id,
    required this.title,
    required this.description,
    this.category = '',
    required this.icon,
    required this.color,
    this.priority = RecommendationPriority.medium,
    this.potentialSavings = 0,
    this.actionable = false,
    DateTime? generatedAt,
    this.metadata = const {},
  }) : generatedAt = generatedAt ?? DateTime.now();
}

enum RecommendationPriority {
  high,
  medium,
  low,
} 