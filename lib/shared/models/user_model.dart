class UserModel {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEmailVerified;
  final String? phoneNumber;
  final String preferredCurrency;
  final String preferredLanguage;

  const UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.profileImageUrl,
    required this.createdAt,
    this.updatedAt,
    this.isEmailVerified = false,
    this.phoneNumber,
    this.preferredCurrency = 'TRY',
    this.preferredLanguage = 'tr',
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? email.split('@').first;
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName!.substring(0, 1)}${lastName!.substring(0, 1)}'.toUpperCase();
    }
    return email.substring(0, 2).toUpperCase();
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    String? phoneNumber,
    String? preferredCurrency,
    String? preferredLanguage,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_email_verified': isEmailVerified,
      'phone_number': phoneNumber,
      'preferred_currency': preferredCurrency,
      'preferred_language': preferredLanguage,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      phoneNumber: json['phone_number'] as String?,
      preferredCurrency: json['preferred_currency'] as String? ?? 'TRY',
      preferredLanguage: json['preferred_language'] as String? ?? 'tr',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName)';
  }
} 