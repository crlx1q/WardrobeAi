import 'clothing_item.dart';

class Outfit {
  final String? id;
  final String title;
  final String rationale;
  final List<String> tags;
  final List<ClothingItem> items;
  final DateTime? date;
  final String source;

  const Outfit({
    this.id,
    required this.title,
    required this.rationale,
    required this.tags,
    required this.items,
    this.date,
    this.source = 'daily',
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['id']?.toString(),
      title: json['title'] ?? 'Образ',
      rationale: json['rationale'] ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      items: (json['items'] as List?)
              ?.map((e) => ClothingItem.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      source: json['source'] ?? 'daily',
    );
  }

  List<String> get itemIds => items.map((e) => e.id).toList();
}

class Weather {
  final bool available;
  final int? tempC;
  final int? feelsLikeC;
  final String condition;
  final String summary;

  const Weather({
    required this.available,
    this.tempC,
    this.feelsLikeC,
    required this.condition,
    required this.summary,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      available: json['available'] ?? false,
      tempC: json['tempC'],
      feelsLikeC: json['feelsLikeC'],
      condition: json['condition'] ?? '',
      summary: json['summary'] ?? '',
    );
  }
}

class DailyLook {
  final bool empty;
  final Weather? weather;
  final Outfit? outfit;

  const DailyLook({required this.empty, this.weather, this.outfit});

  factory DailyLook.fromJson(Map<String, dynamic> json) {
    if (json['empty'] == true) return const DailyLook(empty: true);
    return DailyLook(
      empty: false,
      weather: json['weather'] != null
          ? Weather.fromJson((json['weather'] as Map).cast<String, dynamic>())
          : null,
      outfit: json['outfit'] != null
          ? Outfit.fromJson((json['outfit'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}
