import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config.dart';
import 'core/providers.dart';
import 'core/theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/shell/shell_screen.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  runApp(const ProviderScope(child: CapsuleApp()));
}

class CapsuleApp extends ConsumerWidget {
  const CapsuleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', 'RU'), Locale('en', 'US')],
      locale: const Locale('ru', 'RU'),
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: brightness == Brightness.dark
              ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
              : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const _RootGate(),
    );
  }
}

class _RootGate extends ConsumerStatefulWidget {
  const _RootGate();

  @override
  ConsumerState<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<_RootGate> {
  bool _minSplashDone = false;

  @override
  void initState() {
    super.initState();
    // Keep the splash visible for a beat so the brand is seen.
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _minSplashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (auth.status == AuthStatus.unknown || !_minSplashDone) {
      return const SplashScreen();
    }
    return auth.status == AuthStatus.authenticated ? const ShellScreen() : const AuthScreen();
  }
}
