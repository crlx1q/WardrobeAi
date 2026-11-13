import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/clothing_item.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../wardrobe/wardrobe_screen.dart';

final _insightsProvider = FutureProvider.autoDispose<WardrobeResult>((ref) async {
  return ref.read(wardrobeRepositoryProvider).list(category: 'all');
});

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_insightsProvider);
    final text = context.tt;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text('Аналитика', style: text.titleLarge)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Ошибка',
          message: ApiClient.errorMessage(e),
        ),
        data: (data) {
          final items = data.items;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.insights_outlined,
              title: 'Пока нет данных',
              message: 'Добавьте вещи в гардероб, чтобы увидеть аналитику.',
            );
          }
          final favorites = items.where((i) => i.favorite).length;
          final neverWorn = items.where((i) => i.wearCount == 0).length;
          final totalWears = items.fold<int>(0, (s, i) => s + i.wearCount);
          final byCat = <String, int>{};
          for (final i in items) {
            byCat[i.category] = (byCat[i.category] ?? 0) + 1;
          }
          final sortedCats = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final mostWorn = [...items]..sort((a, b) => b.wearCount.compareTo(a.wearCount));
          final topWorn = mostWorn.where((i) => i.wearCount > 0).take(3).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              Row(
                children: [
                  Expanded(child: _statCard(context, '${items.length}', 'вещей')),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard(context, '$favorites', 'избранных')),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _statCard(context, '$totalWears', 'раз надето')),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard(context, '$neverWorn', 'ни разу')),
                ],
              ),
              const SizedBox(height: 28),
              Text('По категориям', style: text.headlineSmall),
              const SizedBox(height: 16),
              FloatingCard(
                child: Column(
                  children: [
                    for (final e in sortedCats)
                      _catBar(context, WardrobeCategory.labelFor(e.key), e.value, items.length),
                  ],
                ),
              ),
              if (topWorn.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Чаще всего носите', style: text.headlineSmall),
                const SizedBox(height: 16),
                ...topWorn.map((i) => _wornRow(context, i)),
              ],
              if (neverWorn > 0) ...[
                const SizedBox(height: 28),
                GlassCard(
                  child: Row(
                    children: [
                      const AiSpark(size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'У вас $neverWorn вещей, которые вы ещё ни разу не надевали. Попробуйте образ дня — Capsule задействует их.',
                          style: text.bodyMedium?.copyWith(color: context.cs.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(BuildContext context, String value, String label) {
    return FloatingCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: context.tt.displayMedium?.copyWith(fontSize: 36)),
          const SizedBox(height: 4),
          Text(label, style: context.tt.bodySmall),
        ],
      ),
    );
  }

  Widget _catBar(BuildContext context, String label, int count, int total) {
    final frac = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: context.tt.labelLarge),
              Text('$count', style: context.tt.bodyMedium),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 8,
              backgroundColor: context.cs.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wornRow(BuildContext context, ClothingItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FloatingCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(width: 48, height: 48, child: ItemImage(url: item.imageUrl, radius: AppRadius.sm)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: context.tt.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(WardrobeCategory.labelFor(item.category), style: context.tt.bodySmall),
                ],
              ),
            ),
            Text('${item.wearCount}×',
                style: context.tt.titleLarge?.copyWith(fontSize: 18, color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}
