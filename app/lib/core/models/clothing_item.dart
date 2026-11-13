class ClothingItem {
  final String id;
  final String imageUrl;
  final String name;
  final String type;
  final String category;
  final String color;
  final String material;
  final List<String> tags;
  final bool favorite;
  final int wearCount;
  final DateTime? lastWornAt;

  const ClothingItem({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.type,
    required this.category,
    required this.color,
    required this.material,
    required this.tags,
    required this.favorite,
    required this.wearCount,
    this.lastWornAt,
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      category: json['category'] ?? 'other',
      color: json['color'] ?? '',
      material: json['material'] ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      favorite: json['favorite'] ?? false,
      wearCount: json['wearCount'] ?? 0,
      lastWornAt: json['lastWornAt'] != null ? DateTime.tryParse(json['lastWornAt']) : null,
    );
  }
}

/// Wardrobe filter categories matching the mockup chips.
class WardrobeCategory {
  final String id; // matches server category key or "all"
  final String label;
  const WardrobeCategory(this.id, this.label);

  static const all = [
    WardrobeCategory('all', 'Все'),
    WardrobeCategory('top', 'Верхи'),
    WardrobeCategory('bottom', 'Низы'),
    WardrobeCategory('dress', 'Платья'),
    WardrobeCategory('outerwear', 'Верхняя'),
    WardrobeCategory('shoes', 'Обувь'),
    WardrobeCategory('accessory', 'Аксессуары'),
  ];

  static String labelFor(String categoryId) {
    return all
        .firstWhere((c) => c.id == categoryId, orElse: () => const WardrobeCategory('other', 'Другое'))
        .label;
  }
}
