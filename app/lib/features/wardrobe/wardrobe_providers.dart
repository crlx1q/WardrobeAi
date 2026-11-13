import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/repositories.dart';
import '../../core/providers.dart';

/// Currently selected filter tab id ("all", "top", ...).
final selectedCategoryProvider = StateProvider<String>((_) => 'all');

/// Bumped to force the wardrobe list to refetch.
final wardrobeRefreshProvider = StateProvider<int>((_) => 0);

final wardrobeProvider = FutureProvider.autoDispose<WardrobeResult>((ref) async {
  ref.watch(wardrobeRefreshProvider);
  final category = ref.watch(selectedCategoryProvider);
  final repo = ref.read(wardrobeRepositoryProvider);
  return repo.list(category: category);
});

void refreshWardrobe(Ref ref) {
  ref.read(wardrobeRefreshProvider.notifier).state++;
}

/// WidgetRef variant for use inside widgets.
void refreshWardrobeW(WidgetRef ref) {
  ref.read(wardrobeRefreshProvider.notifier).state++;
}
