import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/clothing_item.dart';
import '../../core/models/outfit.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../subscription/subscription_screen.dart';
import '../wardrobe/wardrobe_screen.dart';

class StylistState {
  final bool loading;
  final DailyLook? look;
  final Object? error;
  const StylistState({this.loading = false, this.look, this.error});
}

class StylistController extends StateNotifier<StylistState> {
  StylistController(this._ref) : super(const StylistState(loading: true)) {
    load();
  }
  final Ref _ref;

  Future<void> load() async {
    state = const StylistState(loading: true);
    try {
      final look = await _ref.read(stylistRepositoryProvider).today();
      state = StylistState(look: look);
    } catch (e) {
      state = StylistState(error: e);
    }
  }

  /// Regenerate keeps the current look on failure and rethrows so the UI can
  /// react (e.g. show a Premium prompt) without losing the shown outfit.
  Future<void> regenerate() async {
    final prev = state.look;
    state = StylistState(loading: true, look: prev);
    try {
      final avoid = prev?.outfit?.itemIds ?? const <String>[];
      final look = await _ref.read(stylistRepositoryProvider).regenerate(avoidItemIds: avoid);
      state = StylistState(look: look);
    } catch (e) {
      state = StylistState(look: prev);
      rethrow;
    }
  }

  Future<void> wear() async {
    final ids = state.look?.outfit?.itemIds ?? const <String>[];
    if (ids.isEmpty) return;
    await _ref.read(stylistRepositoryProvider).wear(ids);
  }
}

final stylistControllerProvider =
    StateNotifierProvider.autoDispose<StylistController, StylistState>(
  (ref) => StylistController(ref),
);

class StylistScreen extends ConsumerWidget {
  const StylistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stylistControllerProvider);
    final ctrl = ref.read(stylistControllerProvider.notifier);
    final text = context.tt;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: context.cs.onSurface,
          onRefresh: ctrl.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Row(
                children: [
                  const AiSpark(size: 20),
                  const SizedBox(width: 8),
                  Text('AI-стилист', style: text.labelSmall),
                ],
              ),
              const SizedBox(height: 16),
              Text('Образ дня', style: text.displayMedium),
              const SizedBox(height: 6),
              Text(
                'Персональная рекомендация на основе ИИ, погоды и вашего гардероба.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (state.loading)
                const _StylistSkeleton()
              else if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Не удалось подобрать',
                    message: ApiClient.errorMessage(state.error!),
                    action: OutlinedButton(onPressed: ctrl.load, child: const Text('Повторить')),
                  ),
                )
              else if (state.look?.empty ?? true)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: EmptyState(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Гардероб пуст',
                    message: 'Добавьте несколько вещей на вкладке «Сканер», и AI соберёт образ дня.',
                  ),
                )
              else
                _LookView(look: state.look!, ctrl: ctrl),
            ],
          ),
        ),
      ),
    );
  }
}

class _StylistSkeleton extends StatelessWidget {
  const _StylistSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Row(
            children: [
              const AiSpark(size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Shimmer(height: 12, width: 180),
                    SizedBox(height: 8),
                    Shimmer(height: 12, width: 120),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FloatingCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              AspectRatio(aspectRatio: 1.5, child: Shimmer(radius: AppRadius.md)),
              SizedBox(height: 16),
              Shimmer(height: 20, width: 200),
              SizedBox(height: 20),
              Shimmer(height: 44),
              SizedBox(height: 12),
              Shimmer(height: 44),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AiSpark(size: 16),
              const SizedBox(width: 8),
              Text('Собираем образ под погоду…', style: context.tt.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _LookView extends ConsumerWidget {
  final DailyLook look;
  final StylistController ctrl;
  const _LookView({required this.look, required this.ctrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.tt;
    final outfit = look.outfit!;
    final weather = look.weather;
    final isPremium = ref.watch(authControllerProvider).isPremium;
    final aiNote = outfit.rationale.isNotEmpty
        ? outfit.rationale
        : 'Мы собрали гармоничный образ из вещей вашего гардероба.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (weather != null && weather.available) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: context.cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.thermostat, size: 20, color: context.cs.onSurface),
                const SizedBox(width: 8),
                Text('${weather.tempC}°', style: text.titleLarge),
                const SizedBox(width: 6),
                if (weather.summary.isNotEmpty)
                  Expanded(child: Text(weather.summary, style: text.bodyMedium)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        GlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AiSpark(size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(aiNote, style: text.bodyMedium?.copyWith(color: context.cs.onSurface))),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FloatingCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OutfitCollage(items: outfit.items),
              const SizedBox(height: 16),
              Text(outfit.title, style: text.headlineSmall),
              if (outfit.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: outfit.tags.map((t) => TagChip(label: t, caps: true)).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Divider(height: 28, color: context.cs.surfaceContainerHigh),
              ...outfit.items.map((item) => _OutfitItemRow(item: item)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            await ctrl.wear();
            if (context.mounted) showSnack(context, 'Образ отмечен как надетый сегодня');
          },
          child: const Text('Надеть это'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            try {
              await ctrl.regenerate();
            } catch (e) {
              if (!context.mounted) return;
              if (ApiClient.isPremiumRequired(e)) {
                showPremiumRequired(context);
              } else {
                showSnack(context, ApiClient.errorMessage(e), error: true);
              }
            }
          },
          icon: Icon(isPremium ? Icons.refresh : Icons.lock_outline, size: 18),
          label: Text(isPremium ? 'Другой вариант' : 'Другой вариант · Premium'),
        ),
      ],
    );
  }
}

class _OutfitCollage extends StatelessWidget {
  final List<ClothingItem> items;
  const _OutfitCollage({required this.items});

  @override
  Widget build(BuildContext context) {
    final shown = items.take(4).toList();
    return AspectRatio(
      aspectRatio: 1.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: shown.isEmpty
            ? Container(color: context.cs.surfaceContainerHigh)
            : Row(
                children: [
                  for (int i = 0; i < shown.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(child: ItemImage(url: shown[i].imageUrl, radius: 4)),
                  ],
                ],
              ),
      ),
    );
  }
}

class _OutfitItemRow extends StatelessWidget {
  final ClothingItem item;
  const _OutfitItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final text = context.tt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 44, height: 44, child: ItemImage(url: item.imageUrl, radius: AppRadius.sm)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: text.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  [item.color, item.material].where((e) => e.isNotEmpty).join(' · '),
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline, size: 20, color: context.cs.outline),
        ],
      ),
    );
  }
}
