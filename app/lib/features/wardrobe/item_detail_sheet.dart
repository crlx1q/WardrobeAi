import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/models/clothing_item.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import 'wardrobe_providers.dart';
import 'wardrobe_screen.dart';

Future<void> showItemDetail(BuildContext context, ClothingItem item) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ItemDetailSheet(item: item),
  );
}

class _ItemDetailSheet extends ConsumerWidget {
  final ClothingItem item;
  const _ItemDetailSheet({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.tt;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: context.cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Center(child: _grabber(context)),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1,
                child: ItemImage(url: item.imageUrl, radius: AppRadius.lg),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Text(item.name, style: text.headlineSmall)),
                  Icon(
                    item.favorite ? Icons.favorite : Icons.favorite_border,
                    color: item.favorite ? AppColors.accent : context.cs.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(item.type, style: text.bodyMedium),
              const SizedBox(height: 24),
              _row(context, 'Категория', WardrobeCategory.labelFor(item.category)),
              _row(context, 'Цвет', item.color),
              _row(context, 'Материал', item.material),
              _row(context, 'Носили раз', '${item.wearCount}'),
              if (item.lastWornAt != null)
                _row(context, 'Последний раз', DateFormat('d MMM yyyy', 'ru').format(item.lastWornAt!)),
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.tags.map((t) => TagChip(label: '#$t')).toList(),
                ),
              ],
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: context.cs.surfaceContainerLowest,
                      title: const Text('Удалить вещь?'),
                      content: Text('«${item.name}» будет удалена из гардероба.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Удалить', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  try {
                    await ref.read(wardrobeRepositoryProvider).delete(item.id);
                    refreshWardrobeW(ref);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: context.cs.outlineVariant),
                ),
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Удалить из гардероба'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _grabber(BuildContext context) => Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: context.cs.outlineVariant,
          borderRadius: BorderRadius.circular(999),
        ),
      );

  Widget _row(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: context.cs.onSurfaceVariant,
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
