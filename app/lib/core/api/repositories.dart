import 'package:dio/dio.dart';

import '../models/clothing_item.dart';
import '../models/event.dart';
import '../models/outfit.dart';
import '../models/subscription.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  final String token;
  final AppUser user;
  const AuthResult(this.token, this.user);
}

class AuthRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<AuthResult> login(String email, String password) async {
    final res = await _dio.post('/api/auth/login', data: {'email': email, 'password': password});
    return _parse(res.data);
  }

  Future<AuthResult> register(String email, String password, String name) async {
    final res = await _dio.post('/api/auth/register',
        data: {'email': email, 'password': password, 'name': name});
    return _parse(res.data);
  }

  Future<AppUser> me() async {
    final res = await _dio.get('/api/auth/me');
    return AppUser.fromJson((res.data['user'] as Map).cast<String, dynamic>());
  }

  Future<AppUser> updateLocation(double lat, double lon) async {
    final res = await _dio.patch('/api/auth/me', data: {
      'location': {'lat': lat, 'lon': lon}
    });
    return AppUser.fromJson((res.data['user'] as Map).cast<String, dynamic>());
  }

  AuthResult _parse(dynamic data) {
    final map = (data as Map).cast<String, dynamic>();
    return AuthResult(
      map['token'] as String,
      AppUser.fromJson((map['user'] as Map).cast<String, dynamic>()),
    );
  }
}

class WardrobeResult {
  final List<ClothingItem> items;
  final int total;
  const WardrobeResult(this.items, this.total);
}

class WardrobeRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<WardrobeResult> list({String category = 'all', bool favoritesOnly = false}) async {
    final res = await _dio.get('/api/wardrobe', queryParameters: {
      'category': category,
      if (favoritesOnly) 'favorite': 'true',
    });
    final items = (res.data['items'] as List)
        .map((e) => ClothingItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    return WardrobeResult(items, res.data['total'] ?? items.length);
  }

  Future<ClothingItem> toggleFavorite(String id) async {
    final res = await _dio.post('/api/wardrobe/$id/favorite');
    return ClothingItem.fromJson((res.data['item'] as Map).cast<String, dynamic>());
  }

  Future<void> delete(String id) async {
    await _dio.delete('/api/wardrobe/$id');
  }

  Future<ClothingItem> update(String id, Map<String, dynamic> patch) async {
    final res = await _dio.patch('/api/wardrobe/$id', data: patch);
    return ClothingItem.fromJson((res.data['item'] as Map).cast<String, dynamic>());
  }
}

class ScanResult {
  final String imageUrl;
  final Map<String, dynamic> attributes;
  const ScanResult(this.imageUrl, this.attributes);
}

class ScanRepository {
  final Dio _dio = ApiClient.instance.dio;

  /// Uploads the photo, stores it in the DB and returns AI-detected attributes.
  Future<ScanResult> scan(String imagePath) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath, filename: 'scan.jpg'),
    });
    final res = await _dio.post('/api/scan', data: form);
    return ScanResult(
      res.data['imageUrl'] ?? '',
      ((res.data['attributes'] as Map?) ?? {}).cast<String, dynamic>(),
    );
  }

  /// Saves a confirmed item, reusing the already-uploaded image URL.
  Future<ClothingItem> saveItem({
    required String imageUrl,
    required Map<String, dynamic> attributes,
  }) async {
    final res = await _dio.post('/api/wardrobe', data: {
      'imageUrl': imageUrl,
      'name': attributes['name'] ?? '',
      'type': attributes['type'] ?? '',
      'category': attributes['category'] ?? 'other',
      'color': attributes['color'] ?? '',
      'material': attributes['material'] ?? '',
      'tags': attributes['tags'] ?? [],
    });
    return ClothingItem.fromJson((res.data['item'] as Map).cast<String, dynamic>());
  }
}

class StylistRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<DailyLook> today() async {
    final res = await _dio.get('/api/stylist/today');
    return DailyLook.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<DailyLook> regenerate({List<String> avoidItemIds = const []}) async {
    final res = await _dio.post('/api/stylist/regenerate', data: {'avoidItemIds': avoidItemIds});
    return DailyLook.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<void> wear(List<String> itemIds) async {
    await _dio.post('/api/stylist/wear', data: {'itemIds': itemIds});
  }
}

class CalendarRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<WardrobeEvent>> events() async {
    final res = await _dio.get('/api/calendar/events');
    return (res.data['events'] as List)
        .map((e) => WardrobeEvent.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<Outfit>> outfits({DateTime? from, DateTime? to}) async {
    final res = await _dio.get('/api/calendar/outfits', queryParameters: {
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    });
    return (res.data['outfits'] as List)
        .where((e) => e != null)
        .map((e) => Outfit.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<WardrobeEvent> createEvent({
    required String title,
    required DateTime date,
    String dressCode = '',
    String notes = '',
  }) async {
    final res = await _dio.post('/api/calendar/events', data: {
      'title': title,
      'date': date.toIso8601String(),
      'dressCode': dressCode,
      'notes': notes,
    });
    return WardrobeEvent.fromJson((res.data['event'] as Map).cast<String, dynamic>());
  }

  Future<void> deleteEvent(String id) async {
    await _dio.delete('/api/calendar/events/$id');
  }

  Future<Outfit> planOutfit(String eventId) async {
    final res = await _dio.post('/api/calendar/events/$eventId/plan-outfit');
    return Outfit.fromJson((res.data['outfit'] as Map).cast<String, dynamic>());
  }
}

class SubscriptionData {
  final List<SubscriptionPlan> plans;
  final SubscriptionStatus current;
  final String note;
  const SubscriptionData(this.plans, this.current, this.note);
}

class SubscriptionRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<SubscriptionData> load() async {
    final res = await _dio.get('/api/subscription');
    final plans = (res.data['plans'] as List)
        .map((e) => SubscriptionPlan.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final current = SubscriptionStatus.fromJson((res.data['current'] as Map).cast<String, dynamic>());
    return SubscriptionData(plans, current, res.data['note'] ?? '');
  }
}
