// QANTA v2 Models - Barrel Export File
// This file exports all the new models that match our QANTA v2 database schema

// Core models
export 'account_model.dart';
export 'category_model.dart';
export 'transaction_model_v2.dart';
export 'installment_models_v2.dart';

// Legacy models (for backward compatibility during migration)
export 'user_model.dart';

class QuickNote {
  final String id;
  final String userId;
  final String content;
  final QuickNoteType type;
  final DateTime createdAt;
  final bool isProcessed; // İşleme dönüştürüldü mü?
  final String? processedTransactionId; // Hangi işleme dönüştürüldü?
  final String? imagePath; // Fotoğraf yolu

  QuickNote({
    required this.id,
    required this.userId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isProcessed = false,
    this.processedTransactionId,
    this.imagePath,
  });

  factory QuickNote.fromJson(Map<String, dynamic> json) {
    return QuickNote(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      type: QuickNoteType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => QuickNoteType.text,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      isProcessed: json['is_processed'] as bool? ?? false,
      processedTransactionId: json['processed_transaction_id'] as String?,
      imagePath: json['image_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'type': type.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'is_processed': isProcessed,
      'processed_transaction_id': processedTransactionId,
      'image_path': imagePath,
    };
  }

  QuickNote copyWith({
    String? id,
    String? userId,
    String? content,
    QuickNoteType? type,
    DateTime? createdAt,
    bool? isProcessed,
    String? processedTransactionId,
    String? imagePath,
  }) {
    return QuickNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isProcessed: isProcessed ?? this.isProcessed,
      processedTransactionId: processedTransactionId ?? this.processedTransactionId,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

enum QuickNoteType {
  text,
  voice,
  image,
} 