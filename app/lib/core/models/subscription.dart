class SubscriptionPlan {
  final String id;
  final String name;
  final String price;
  final String period;
  final bool highlighted;
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.highlighted,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? '',
      period: json['period'] ?? '',
      highlighted: json['highlighted'] ?? false,
      features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
