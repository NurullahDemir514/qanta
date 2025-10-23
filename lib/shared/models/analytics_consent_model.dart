/// Kullanıcı veri toplama izin modeli
class AnalyticsConsent {
  final bool isConsentGiven;
  final DateTime consentDate;
  final String? userId;
  
  const AnalyticsConsent({
    required this.isConsentGiven,
    required this.consentDate,
    this.userId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'isConsentGiven': isConsentGiven,
      'consentDate': consentDate.toIso8601String(),
      'userId': userId,
    };
  }
  
  factory AnalyticsConsent.fromJson(Map<String, dynamic> json) {
    return AnalyticsConsent(
      isConsentGiven: json['isConsentGiven'] ?? false,
      consentDate: json['consentDate'] != null
          ? DateTime.parse(json['consentDate'])
          : DateTime.now(),
      userId: json['userId'],
    );
  }
}

/// Anonim harcama verisi modeli
class AnonymousExpenseData {
  final String anonymousId; // UUID
  final double amount; // Aylık tutar (taksitli ise aylık, değilse toplam)
  final String category;
  final DateTime transactionDate;
  final String? description;
  final bool isInstallment; // Taksitli mi?
  final int? installmentCount; // Kaç taksit
  final double? monthlyAmount; // Aylık taksit tutarı
  final double? totalInstallmentAmount; // Toplam taksit tutarı
  
  const AnonymousExpenseData({
    required this.anonymousId,
    required this.amount,
    required this.category,
    required this.transactionDate,
    this.description,
    this.isInstallment = false,
    this.installmentCount,
    this.monthlyAmount,
    this.totalInstallmentAmount,
  });
  
  Map<String, dynamic> toJson() {
    final json = {
      'anonymousId': anonymousId,
      'amount': amount,
      'category': category,
      'transactionDate': transactionDate.toIso8601String(),
      'isInstallment': isInstallment,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Null olmayan değerleri ekle
    if (installmentCount != null) {
      json['installmentCount'] = installmentCount!;
    }
    if (monthlyAmount != null) {
      json['monthlyAmount'] = monthlyAmount!;
    }
    if (totalInstallmentAmount != null) {
      json['totalInstallmentAmount'] = totalInstallmentAmount!;
    }
    
    return json;
  }
}

