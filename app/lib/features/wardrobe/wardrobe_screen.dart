import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/config.dart';
import '../../core/models/clothing_item.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../profile/profile_sheet.dart';
import 'item_detail_sheet.dart';
import 'wardrobe_providers.dart';

class WardrobeScreen extends ConsumerWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(wardrobeProvider);
    final selected = ref.watch(selectedCategoryProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: context.cs.onSurface,
          onRefresh: () async => refreshWardrobeW(ref),
          child: CustomScrollView(
            slivers: [
              // Brand bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.asset('assets/logo.png', width: 32, height: 32, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 10),
                          Text('Capsule', style: context.tt.titleLarge),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => showProfileSheet(context),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: context.cs.surfaceContainerHigh,
                          backgroundImage: (user?.avatarUrl.isNotEmpty ?? false)
                              ? NetworkImage(AppConfig.resolveUrl(user!.avatarUrl))
                              : null,
                          child: (user?.avatarUrl.isEmpty ?? true)
                              ? Text(
                                  (user?.displayName ?? '?').characters.first.toUpperCase(),
                                  style: context.tt.titleLarge,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Мой Гардероб', style: context.tt.displayMedium),
                      const SizedBox(height: 6),
                      async.maybeWhen(
                        data: (d) => Text('${d.total} вещей в коллекции.', style: context.tt.bodyMedium),
                        orElse: () => Text('Загрузка…', style: context.tt.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
              // Filter chips (fixed height so text is never clipped)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 4),
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: WardrobeCategory.all.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final cat = WardrobeCategory.all[i];
                        return TagChip(
                          label: cat.label,
                          selected: selected == cat.id,
                          onTap: () => ref.read(selectedCategoryProvider.notifier).state = cat.id,
                        );
                      },
                    ),
                  ),
                ),
              ),
              async.when(
                loading: () => const SliverFillRemaining(child: LoadingView()),
                error: (e, _) => SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Не удалось загрузить',
                    message: ApiClient.errorMessage(e),
                    action: OutlinedButton(
                      onPressed: () => refreshWardrobeW(ref),
                      child: const Text('Повторить'),
                    ),
                  ),
                ),
                data: (data) {
                  if (data.items.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.checkroom_outlined,
                        title: 'Гардероб пуст',
                        message: 'Отсканируйте первую вещь на вкладке «Сканер», чтобы начать.',
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _WardrobeCard(item: data.items[i]),
                        childCount: data.items.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WardrobeCard extends ConsumerWidget {
  final ClothingItem item;
  const _WardrobeCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => showItemDetail(context, item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: ItemImage(url: item.imageUrl, radius: AppRadius.md)),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        await ref.read(wardrobeRepositoryProvider).toggleFavorite(item.id);
                        refreshWardrobeW(ref);
                      } catch (_) {}
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(
                        item.favorite ? Icons.favorite : Icons.favorite_border,
                        size: 17,
                        color: item.favorite ? AppColors.accent : const Color(0xFF444748),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(item.name,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleLarge?.copyWith(fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            item.color.isNotEmpty ? item.color : WardrobeCategory.labelFor(item.category),
            style: context.tt.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Reusable garment image with graceful placeholder. Resolves relative URLs.
class ItemImage extends StatelessWidget {
  final String url;
  final double radius;
  final BoxFit fit;
  const ItemImage({super.key, required this.url, this.radius = AppRadius.sm, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final resolved = AppConfig.resolveUrl(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: context.cs.surfaceContainerHigh,
        child: resolved.isEmpty
            ? Center(child: Icon(Icons.checkroom, color: context.cs.outline, size: 32))
            : CachedNetworkImage(
                imageUrl: resolved,
                fit: fit,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.cs.outline),
                  ),
                ),
                errorWidget: (_, __, ___) =>
                    Center(child: Icon(Icons.checkroom, color: context.cs.outline, size: 32)),
              ),
      ),
    );
  }
}
