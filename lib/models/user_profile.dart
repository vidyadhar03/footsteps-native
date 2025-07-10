class UserProfile {
  final String? id;
  final String? authUserId;
  final String name;
  final String? origin;
  final List<String> styleTags;
  final double totalKm;
  final int totalCountries;
  final int earthRotations;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    this.id,
    this.authUserId,
    required this.name,
    this.origin,
    this.styleTags = const [],
    this.totalKm = 0.0,
    this.totalCountries = 0,
    this.earthRotations = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String?,
      authUserId: json['authUserId'] as String?,
      name: json['name'] as String,
      origin: json['origin'] as String?,
      styleTags: List<String>.from(json['styleTags'] as List<dynamic>? ?? []),
      totalKm: (json['totalKm'] as num? ?? 0.0).toDouble(),
      totalCountries: json['totalCountries'] as int? ?? 0,
      earthRotations: json['earthRotations'] as int? ?? 0,
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
      'origin': origin,
      'styleTags': styleTags,
      'totalKm': totalKm,
      'totalCountries': totalCountries,
      'earthRotations': earthRotations,
    };
  }

  UserProfile copyWith({
    String? id,
    String? authUserId,
    String? name,
    String? origin,
    List<String>? styleTags,
    double? totalKm,
    int? totalCountries,
    int? earthRotations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      authUserId: authUserId ?? this.authUserId,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      styleTags: styleTags ?? this.styleTags,
      totalKm: totalKm ?? this.totalKm,
      totalCountries: totalCountries ?? this.totalCountries,
      earthRotations: earthRotations ?? this.earthRotations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 