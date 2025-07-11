class UserProfile {
  final String? id;
  final String? authUserId;
  final String name;
  final String email; // NEW required field
  final String? origin;
  final List<String> styleTags;
  final double totalKm;
  final int totalCountries;
  final String? bio; // NEW optional field
  final String? avatarUrl; // NEW optional field
  final String? timezone; // NEW optional field
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    this.id,
    this.authUserId,
    required this.name,
    required this.email, // NEW required field
    this.origin,
    this.styleTags = const [],
    this.totalKm = 0.0,
    this.totalCountries = 0,
    this.bio, // NEW optional field
    this.avatarUrl, // NEW optional field
    this.timezone, // NEW optional field
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String?,
      authUserId: json['authUserId'] as String?,
      name: json['name'] as String,
      email: json['email'] as String, // NEW required field
      origin: json['origin'] as String?,
      styleTags: List<String>.from(json['styleTags'] as List<dynamic>? ?? []),
      totalKm: (json['totalKm'] as num? ?? 0.0).toDouble(),
      totalCountries: json['totalCountries'] as int? ?? 0,
      bio: json['bio'] as String?, // NEW optional field
      avatarUrl: json['avatarUrl'] as String?, // NEW optional field
      timezone: json['timezone'] as String?, // NEW optional field
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email, // NEW required field
      'origin': origin,
      'styleTags': styleTags,
      'totalKm': totalKm,
      'totalCountries': totalCountries,
      'bio': bio, // NEW optional field
      'avatarUrl': avatarUrl, // NEW optional field
      'timezone': timezone, // NEW optional field
    };
  }

  UserProfile copyWith({
    String? id,
    String? authUserId,
    String? name,
    String? email, // NEW required field
    String? origin,
    List<String>? styleTags,
    double? totalKm,
    int? totalCountries,
    String? bio, // NEW optional field
    String? avatarUrl, // NEW optional field
    String? timezone, // NEW optional field
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      authUserId: authUserId ?? this.authUserId,
      name: name ?? this.name,
      email: email ?? this.email, // NEW required field
      origin: origin ?? this.origin,
      styleTags: styleTags ?? this.styleTags,
      totalKm: totalKm ?? this.totalKm,
      totalCountries: totalCountries ?? this.totalCountries,
      bio: bio ?? this.bio, // NEW optional field
      avatarUrl: avatarUrl ?? this.avatarUrl, // NEW optional field
      timezone: timezone ?? this.timezone, // NEW optional field
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 