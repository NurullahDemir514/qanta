import 'package:cloud_firestore/cloud_firestore.dart';

/// Tasarruf hedefi modeli
class SavingsGoal {
  final String id;
  final String userId;
  final String name;
  final String? emoji;
  final String? imageUrl;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Özellikler
  final String color; // Hex color (e.g., "FF5733")
  final String? category; // Kullanıcının belirlediği kategori (opsiyonel)
  final bool isArchived;
  final bool isCompleted;
  
  // Otomatik transfer
  final AutoTransferSettings? autoTransfer;
  
  // Round-up özelliği
  final RoundUpSettings? roundUpSettings;
  
  // Bildirim ayarları
  final NotificationSettings notificationSettings;
  
  // Milestone tracking
  final List<Milestone> achievedMilestones;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    this.emoji,
    this.imageUrl,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.createdAt,
    required this.updatedAt,
    required this.color,
    required this.category,
    this.isArchived = false,
    this.isCompleted = false,
    this.autoTransfer,
    this.roundUpSettings,
    NotificationSettings? notificationSettings,
    List<Milestone>? achievedMilestones,
  })  : notificationSettings = notificationSettings ?? NotificationSettings(),
        achievedMilestones = achievedMilestones ?? [];

  /// İlerleme yüzdesi (0.0 - 1.0)
  double get progress => currentAmount / targetAmount;

  /// Kalan miktar
  double get remainingAmount => targetAmount - currentAmount;

  /// Kalan gün sayısı
  int? get daysRemaining => targetDate?.difference(DateTime.now()).inDays;

  /// Günlük gerekli tasarruf miktarı
  double? get dailyRequiredSaving {
    if (daysRemaining == null || daysRemaining! <= 0) return null;
    return remainingAmount / daysRemaining!;
  }

  /// Aylık gerekli tasarruf miktarı
  double? get monthlyRequiredSaving {
    if (daysRemaining == null || daysRemaining! <= 0) return null;
    final monthsRemaining = daysRemaining! / 30.0;
    if (monthsRemaining <= 0) return null;
    return remainingAmount / monthsRemaining;
  }

  /// Tamamlanma yüzdesi (0-100)
  double get completionPercentage => (progress * 100).clamp(0, 100);

  /// Aktif mi?
  bool get isActive => !isArchived && !isCompleted;

  /// Tamamlandı mı?
  bool get hasReachedTarget => currentAmount >= targetAmount;

  /// Ulaşılan milestone yüzdeleri
  List<int> get reachedMilestones => achievedMilestones.map((m) => m.percentage).toList();

  /// AI önerisi
  String getAiSuggestion(String currencySymbol) {
    if (hasReachedTarget) {
      return 'Tebrikler! Hedefinize ulaştınız! 🎉';
    }
    
    if (daysRemaining != null && daysRemaining! > 0 && dailyRequiredSaving != null) {
      final daily = dailyRequiredSaving!.toStringAsFixed(0);
      return 'Hedefe ulaşmak için günde $currencySymbol$daily tasarruf edin';
    }
    
    if (targetDate != null && daysRemaining != null && daysRemaining! < 0) {
      return 'Hedef tarihi geçti. Yeni bir tarih belirleyin';
    }
    
    final remaining = remainingAmount.toStringAsFixed(0);
    return '$currencySymbol$remaining kaldı. Devam edin! 💪';
  }

  /// Firebase'e dönüştür
  Map<String, dynamic> toJson() {
    return {
      // NOT: 'id' field'ı dahil etmiyoruz çünkü Firestore document ID olarak saklanıyor
      'user_id': userId,
      'name': name,
      'emoji': emoji,
      'image_url': imageUrl,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'color': color,
      'category': category,
      'is_archived': isArchived,
      'is_completed': isCompleted,
      'auto_transfer': autoTransfer?.toJson(),
      'round_up_settings': roundUpSettings?.toJson(),
      'notification_settings': notificationSettings.toJson(),
      'achieved_milestones': achievedMilestones.map((m) => m.toJson()).toList(),
    };
  }

  /// Firebase'den oluştur
  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String?,
      imageUrl: json['image_url'] as String?,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      createdAt: json['created_at'] is Timestamp
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] is Timestamp
          ? (json['updated_at'] as Timestamp).toDate()
          : DateTime.parse(json['updated_at'] as String),
      color: json['color'] as String,
      category: json['category'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      autoTransfer: json['auto_transfer'] != null
          ? AutoTransferSettings.fromJson(
              json['auto_transfer'] as Map<String, dynamic>)
          : null,
      roundUpSettings: json['round_up_settings'] != null
          ? RoundUpSettings.fromJson(
              json['round_up_settings'] as Map<String, dynamic>)
          : null,
      notificationSettings: json['notification_settings'] != null
          ? NotificationSettings.fromJson(
              json['notification_settings'] as Map<String, dynamic>)
          : NotificationSettings(),
      achievedMilestones: json['achieved_milestones'] != null
          ? (json['achieved_milestones'] as List)
              .map((m) => Milestone.fromJson(m as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  /// Kopyalama metodu
  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? name,
    String? emoji,
    String? imageUrl,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    String? category,
    bool? isArchived,
    bool? isCompleted,
    AutoTransferSettings? autoTransfer,
    RoundUpSettings? roundUpSettings,
    NotificationSettings? notificationSettings,
    List<Milestone>? achievedMilestones,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      imageUrl: imageUrl ?? this.imageUrl,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      category: category ?? this.category,
      isArchived: isArchived ?? this.isArchived,
      isCompleted: isCompleted ?? this.isCompleted,
      autoTransfer: autoTransfer ?? this.autoTransfer,
      roundUpSettings: roundUpSettings ?? this.roundUpSettings,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      achievedMilestones: achievedMilestones ?? this.achievedMilestones,
    );
  }
}

/// Transfer sıklığı
enum TransferFrequency {
  daily('daily', 'Günlük'),
  weekly('weekly', 'Haftalık'),
  monthly('monthly', 'Aylık');

  final String id;
  final String label;

  const TransferFrequency(this.id, this.label);

  static TransferFrequency fromId(String id) {
    return TransferFrequency.values.firstWhere(
      (e) => e.id == id,
      orElse: () => TransferFrequency.monthly,
    );
  }
}

/// Otomatik transfer ayarları
class AutoTransferSettings {
  final double amount;
  final TransferFrequency frequency;
  final DateTime nextTransferDate;
  final String sourceAccountId;
  final bool isEnabled;

  AutoTransferSettings({
    required this.amount,
    required this.frequency,
    required this.nextTransferDate,
    required this.sourceAccountId,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'frequency': frequency.id,
      'next_transfer_date': nextTransferDate.toIso8601String(),
      'source_account_id': sourceAccountId,
      'is_enabled': isEnabled,
    };
  }

  factory AutoTransferSettings.fromJson(Map<String, dynamic> json) {
    return AutoTransferSettings(
      amount: (json['amount'] as num).toDouble(),
      frequency: TransferFrequency.fromId(json['frequency'] as String),
      nextTransferDate: DateTime.parse(json['next_transfer_date'] as String),
      sourceAccountId: json['source_account_id'] as String,
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }
}

/// Round-up kuralı
enum RoundUpRule {
  toNext1('toNext1', 'En yakın 1 TL'),
  toNext5('toNext5', 'En yakın 5 TL'),
  toNext10('toNext10', 'En yakın 10 TL');

  final String id;
  final String label;

  const RoundUpRule(this.id, this.label);

  static RoundUpRule fromId(String id) {
    return RoundUpRule.values.firstWhere(
      (e) => e.id == id,
      orElse: () => RoundUpRule.toNext1,
    );
  }
}

/// Round-up ayarları
class RoundUpSettings {
  final bool isEnabled;
  final RoundUpRule rule;
  final double multiplier; // 1x, 2x, 3x
  final String sourceAccountId;

  RoundUpSettings({
    this.isEnabled = false,
    this.rule = RoundUpRule.toNext1,
    this.multiplier = 1.0,
    required this.sourceAccountId,
  });

  Map<String, dynamic> toJson() {
    return {
      'is_enabled': isEnabled,
      'rule': rule.id,
      'multiplier': multiplier,
      'source_account_id': sourceAccountId,
    };
  }

  factory RoundUpSettings.fromJson(Map<String, dynamic> json) {
    return RoundUpSettings(
      isEnabled: json['is_enabled'] as bool? ?? false,
      rule: RoundUpRule.fromId(json['rule'] as String? ?? 'toNext1'),
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
      sourceAccountId: json['source_account_id'] as String,
    );
  }
}

/// Bildirim ayarları
class NotificationSettings {
  final bool milestoneNotifications;
  final bool weeklyReminder;
  final bool dailyProgress;
  final bool nearTarget;

  NotificationSettings({
    this.milestoneNotifications = true,
    this.weeklyReminder = true,
    this.dailyProgress = false,
    this.nearTarget = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'milestone_notifications': milestoneNotifications,
      'weekly_reminder': weeklyReminder,
      'daily_progress': dailyProgress,
      'near_target': nearTarget,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      milestoneNotifications: json['milestone_notifications'] as bool? ?? true,
      weeklyReminder: json['weekly_reminder'] as bool? ?? true,
      dailyProgress: json['daily_progress'] as bool? ?? false,
      nearTarget: json['near_target'] as bool? ?? true,
    );
  }
}

/// Milestone (başarı rozeti)
class Milestone {
  final int percentage; // 25, 50, 75, 100
  final DateTime achievedAt;
  final double amount; // Milestone'a ulaşıldığında ki miktar
  final String? badgeUrl;

  Milestone({
    required this.percentage,
    required this.achievedAt,
    required this.amount,
    this.badgeUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'percentage': percentage,
      'achieved_at': achievedAt.toIso8601String(),
      'amount': amount,
      'badge_url': badgeUrl,
    };
  }

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      percentage: json['percentage'] as int,
      achievedAt: json['achieved_at'] is Timestamp
          ? (json['achieved_at'] as Timestamp).toDate()
          : DateTime.parse(json['achieved_at'] as String),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      badgeUrl: json['badge_url'] as String?,
    );
  }
}

