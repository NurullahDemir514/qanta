import 'package:cloud_firestore/cloud_firestore.dart';

class SupportMessage {
  final String id;
  final String senderType; // 'user' or 'admin'
  final String senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.senderType,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });

  factory SupportMessage.fromFirestore(Map<String, dynamic> data) {
    return SupportMessage(
      id: data['id'] ?? '',
      senderType: data['sender_type'] ?? 'user',
      senderId: data['sender_id'] ?? '',
      senderName: data['sender_name'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'sender_type': senderType,
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}

class SupportRequest {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String subject;
  final String message;
  final String category;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final List<SupportMessage> messages;

  SupportRequest({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.subject,
    required this.message,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    required this.messages,
  });

  factory SupportRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    List<SupportMessage> messages = [];
    if (data['messages'] != null) {
      messages = (data['messages'] as List)
          .map((msg) => SupportMessage.fromFirestore(msg as Map<String, dynamic>))
          .toList();
    } else {
      // Fallback: Create message from initial message field
      messages = [
        SupportMessage(
          id: doc.id,
          senderType: 'user',
          senderId: data['user_id'] ?? '',
          senderName: data['user_name'] ?? '',
          message: data['message'] ?? '',
          createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ),
      ];
    }

    return SupportRequest(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userEmail: data['user_email'] ?? '',
      userName: data['user_name'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      category: data['category'] ?? 'general',
      status: data['status'] ?? 'pending',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolved_at'] as Timestamp?)?.toDate(),
      messages: messages,
    );
  }

  bool get hasUnreadMessages {
    if (messages.isEmpty) return false;
    final lastMessage = messages.last;
    return lastMessage.senderType == 'admin' && status != 'resolved' && status != 'closed';
  }
}

