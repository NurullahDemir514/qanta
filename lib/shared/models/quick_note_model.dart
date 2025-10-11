import 'package:cloud_firestore/cloud_firestore.dart';

/// Hızlı not modeli
class QuickNote {
  final String id;
  final String userId;
  final String content;
  final QuickNoteType type;
  final DateTime createdAt;
  final bool isProcessed;
  final String? processedTransactionId;
  final String? imagePath;

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

  /// Firestore'dan QuickNote oluştur
  factory QuickNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuickNote(
      id: doc.id,
      userId: data['user_id'] ?? '',
      content: data['content'] ?? '',
      type: QuickNoteType.fromString(data['type'] ?? 'text'),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isProcessed: data['is_processed'] ?? false,
      processedTransactionId: data['processed_transaction_id'],
      imagePath: data['image_path'],
    );
  }

  /// Firestore'a gönderilecek Map oluştur
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'content': content,
      'type': type.toString().split('.').last,
      'created_at': Timestamp.fromDate(createdAt),
      'is_processed': isProcessed,
      'processed_transaction_id': processedTransactionId,
      'image_path': imagePath,
    };
  }

  /// QuickNote'u kopyala ve güncelle
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

  @override
  String toString() {
    return 'QuickNote(id: $id, content: $content, type: $type, isProcessed: $isProcessed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuickNote && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Hızlı not türleri
enum QuickNoteType {
  text,
  voice,
  image;

  static QuickNoteType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'text':
        return QuickNoteType.text;
      case 'voice':
        return QuickNoteType.voice;
      case 'image':
        return QuickNoteType.image;
      default:
        return QuickNoteType.text;
    }
  }

  String get displayName {
    switch (this) {
      case QuickNoteType.text:
        return 'Metin';
      case QuickNoteType.voice:
        return 'Ses';
      case QuickNoteType.image:
        return 'Resim';
    }
  }

  String get icon {
    switch (this) {
      case QuickNoteType.text:
        return '📝';
      case QuickNoteType.voice:
        return '🎤';
      case QuickNoteType.image:
        return '📷';
    }
  }
}
