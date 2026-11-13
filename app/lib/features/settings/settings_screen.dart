import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    final ctrl = ref.read(themeControllerProvider.notifier);
    final text = context.tt;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text('Настройки', style: text.titleLarge)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _sectionLabel(context, 'Оформление'),
          FloatingCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _themeOption(context, ctrl, mode, ThemeMode.system, Icons.brightness_auto, 'Как в системе'),
                _divider(context),
                _themeOption(context, ctrl, mode, ThemeMode.light, Icons.light_mode_outlined, 'Светлая'),
                _divider(context),
                _themeOption(context, ctrl, mode, ThemeMode.dark, Icons.dark_mode_outlined, 'Тёмная'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _sectionLabel(context, 'О приложении'),
          FloatingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset('assets/logo.png', width: 40, height: 40, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Capsule', style: text.titleLarge),
                        Text('Версия 1.0.0', style: text.bodySmall),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('AI-гардероб и стилист. Сфотографируйте одежду — Capsule соберёт образ дня.',
                    style: text.bodyMedium),
                const SizedBox(height: 6),
                Text(AppConfig.apiBaseUrl, style: text.bodySmall?.copyWith(color: context.cs.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, color: context.cs.onSurfaceVariant)),
      );

  Widget _divider(BuildContext context) =>
      Divider(height: 1, indent: 16, endIndent: 16, color: context.cs.surfaceContainerHigh);

  Widget _themeOption(BuildContext context, ThemeController ctrl, ThemeMode current, ThemeMode value,
      IconData icon, String label) {
    final selected = current == value;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => ctrl.set(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: context.cs.onSurface),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: context.tt.labelLarge)),
            if (selected) const Icon(Icons.check_circle, color: AppColors.accent, size: 22),
          ],
        ),
      ),
    );
  }
}
