import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../insights/insights_screen.dart';
import '../settings/settings_screen.dart';
import '../subscription/subscription_screen.dart';

Future<void> showProfileSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ProfileSheet(),
  );
}

class _ProfileSheet extends ConsumerWidget {
  const _ProfileSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final text = context.tt;
    final premium = auth.isPremium;

    return Container(
      decoration: BoxDecoration(
        color: context.cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: context.cs.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: context.cs.surfaceContainerHigh,
                child: Text(
                  (user?.displayName ?? '?').characters.first.toUpperCase(),
                  style: text.headlineSmall,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.displayName ?? '', style: text.titleLarge),
                    Text(user?.email ?? '', style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FloatingCard(
            color: premium ? AppColors.onyx : null,
            child: Row(
              children: [
                Icon(
                  premium ? Icons.workspace_premium : Icons.lock_outline,
                  color: premium ? AppColors.accentSoft : context.cs.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        premium ? 'Premium активна' : 'Тариф Free',
                        style: text.titleLarge?.copyWith(
                          fontSize: 17,
                          color: premium ? Colors.white : context.cs.onSurface,
                        ),
                      ),
                      if (premium && user?.subscription.expiresAt != null)
                        Text(
                          'До ${DateFormat('d MMMM yyyy', 'ru').format(user!.subscription.expiresAt!)}',
                          style: text.bodySmall?.copyWith(color: AppColors.accentSoft),
                        )
                      else
                        Text('Откройте все возможности AI-стилиста', style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _tile(context, Icons.workspace_premium_outlined, premium ? 'Управление подпиской' : 'Смотреть Premium',
              () => _push(context, const SubscriptionScreen())),
          _tile(context, Icons.insights_outlined, 'Аналитика гардероба',
              () => _push(context, const InsightsScreen())),
          _tile(context, Icons.settings_outlined, 'Настройки',
              () => _push(context, const SettingsScreen())),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 22, color: context.cs.onSurface),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: context.tt.labelLarge)),
                Icon(Icons.chevron_right, size: 20, color: context.cs.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
