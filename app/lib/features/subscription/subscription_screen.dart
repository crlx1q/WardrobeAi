import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/subscription.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';

final subscriptionProvider = FutureProvider.autoDispose<SubscriptionData>((ref) async {
  return ref.read(subscriptionRepositoryProvider).load();
});

/// Shown when a Free user tries to use a Premium-only feature.
Future<void> showPremiumRequired(BuildContext context) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      title: Row(
        children: [
          const Icon(Icons.workspace_premium, color: AppColors.accent),
          const SizedBox(width: 10),
          Text('Только в Premium', style: context.tt.titleLarge),
        ],
      ),
      content: Text(
        'Подбор новых образов, планирование под события и другие AI-функции доступны в подписке Premium.',
        style: context.tt.bodyMedium,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Позже')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Смотреть Premium')),
      ],
    ),
  );
  if (go == true && context.mounted) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
  }
}

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subscriptionProvider);
    final text = context.tt;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text('Подписка', style: text.titleLarge)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Ошибка',
          message: ApiClient.errorMessage(e),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // Current status
            _statusBanner(context, data),
            const SizedBox(height: 24),
            Row(
              children: [
                const AiSpark(size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text('Что даёт Premium', style: text.headlineSmall)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Free — базовый гардероб и один образ дня. Premium снимает лимиты и включает подбор под события, погоду и историю носки.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 24),
            ...data.plans.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _PlanCard(
                    plan: p,
                    isCurrent: data.current.tier == p.id && (p.id == 'free' || data.current.active),
                  ),
                )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cs.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: context.cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(child: Text(data.note, style: text.bodySmall)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner(BuildContext context, SubscriptionData data) {
    final active = data.current.active;
    final text = context.tt;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: active ? AppColors.onyx : context.cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(active ? Icons.workspace_premium : Icons.person_outline,
              color: active ? AppColors.accentSoft : context.cs.onSurfaceVariant, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? 'Ваш тариф: Premium' : 'Ваш тариф: Free',
                  style: text.titleLarge?.copyWith(color: active ? Colors.white : context.cs.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  active && data.current.expiresAt != null
                      ? 'Активна до ${DateFormat('d MMMM yyyy', 'ru').format(data.current.expiresAt!)}'
                      : 'Базовые возможности',
                  style: text.bodySmall?.copyWith(
                      color: active ? AppColors.accentSoft : context.cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrent;
  const _PlanCard({required this.plan, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final text = context.tt;
    final dark = plan.highlighted;
    final fg = dark ? Colors.white : context.cs.onSurface;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dark ? AppColors.onyx : context.cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.x.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.name, style: text.titleLarge?.copyWith(color: fg)),
              const Spacer(),
              if (plan.highlighted)
                _badge(context, 'POPULAR', const Color(0xFF2C1600), AppColors.accentSoft),
              if (isCurrent) ...[
                const SizedBox(width: 6),
                _badge(context, 'ТЕКУЩИЙ', dark ? Colors.white24 : context.cs.surfaceContainerHigh, fg),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(plan.price, style: text.displayMedium?.copyWith(color: fg, fontSize: 34)),
              const SizedBox(width: 4),
              Text(plan.period, style: text.bodyMedium?.copyWith(color: dark ? Colors.white70 : null)),
            ],
          ),
          const SizedBox(height: 20),
          ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 20, color: dark ? AppColors.accentSoft : AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(f,
                            style: text.bodyMedium?.copyWith(color: dark ? Colors.white : context.cs.onSurface))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
