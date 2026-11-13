import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import 'api/api_client.dart';
import 'api/repositories.dart';
import 'models/user.dart';

// Repositories
final authRepositoryProvider = Provider((_) => AuthRepository());
final wardrobeRepositoryProvider = Provider((_) => WardrobeRepository());
final scanRepositoryProvider = Provider((_) => ScanRepository());
final stylistRepositoryProvider = Provider((_) => StylistRepository());
final calendarRepositoryProvider = Provider((_) => CalendarRepository());
final subscriptionRepositoryProvider = Provider((_) => SubscriptionRepository());

// Auth state
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  const AuthState(this.status, this.user);

  const AuthState.unknown() : this(AuthStatus.unknown, null);

  bool get isPremium => user?.subscription.isPremium ?? false;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState.unknown()) {
    _bootstrap();
  }

  final Ref _ref;
  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  Future<void> _bootstrap() async {
    final token = await ApiClient.instance.readToken();
    if (token == null || token.isEmpty) {
      state = const AuthState(AuthStatus.unauthenticated, null);
      return;
    }
    try {
      final user = await _repo.me();
      state = AuthState(AuthStatus.authenticated, user);
      _syncLocation();
    } catch (_) {
      await ApiClient.instance.clearToken();
      state = const AuthState(AuthStatus.unauthenticated, null);
    }
  }

  Future<void> login(String email, String password) async {
    final result = await _repo.login(email, password);
    await ApiClient.instance.saveToken(result.token);
    state = AuthState(AuthStatus.authenticated, result.user);
    _syncLocation();
  }

  Future<void> register(String email, String password, String name) async {
    final result = await _repo.register(email, password, name);
    await ApiClient.instance.saveToken(result.token);
    state = AuthState(AuthStatus.authenticated, result.user);
    _syncLocation();
  }

  Future<void> refresh() async {
    try {
      final user = await _repo.me();
      state = AuthState(AuthStatus.authenticated, user);
    } catch (_) {}
  }

  Future<void> logout() async {
    await ApiClient.instance.clearToken();
    state = const AuthState(AuthStatus.unauthenticated, null);
  }

  /// Best-effort: push device location so the stylist can use weather.
  Future<void> _syncLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final user = await _repo.updateLocation(pos.latitude, pos.longitude);
      if (mounted) state = AuthState(AuthStatus.authenticated, user);
    } catch (_) {
      // location is optional
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref),
);

// ---------------------------------------------------------------------------
// Settings: theme mode (persisted)
// ---------------------------------------------------------------------------
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system) {
    _load();
  }

  static const _key = 'capsule_theme_mode';
  final _storage = const FlutterSecureStorage();

  Future<void> _load() async {
    final saved = await _storage.read(key: _key);
    switch (saved) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.system;
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _storage.write(key: _key, value: mode.name);
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) => ThemeController());
