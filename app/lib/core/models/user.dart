class SubscriptionStatus {
  final String tier;
  final bool active;
  final DateTime? expiresAt;

  const SubscriptionStatus({required this.tier, required this.active, this.expiresAt});

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      tier: json['tier'] ?? 'free',
      active: json['active'] ?? false,
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt']) : null,
    );
  }

  bool get isPremium => active && tier == 'premium';
}

class AppUser {
  final String id;
  final String email;
  final String name;
  final String avatarUrl;
  final String role;
  final SubscriptionStatus subscription;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.avatarUrl,
    required this.role,
    required this.subscription,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      role: json['role'] ?? 'user',
      subscription: SubscriptionStatus.fromJson(
        (json['subscription'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  String get displayName => name.isNotEmpty ? name : email.split('@').first;
}
