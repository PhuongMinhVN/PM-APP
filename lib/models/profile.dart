class Profile {
  final String id;
  final String role;
  final String? fullName;
  final DateTime createdAt;

  final String? phone;
  final String? avatarUrl;

  Profile({
    required this.id,
    required this.role,
    this.fullName,
    required this.createdAt,
    this.phone,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'viewer',
      fullName: json['full_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      phone: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isSales => role == 'sales';
}
