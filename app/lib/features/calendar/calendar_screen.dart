import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/api/api_client.dart';
import '../../core/models/event.dart';
import '../../core/models/outfit.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../subscription/subscription_screen.dart';
import '../wardrobe/wardrobe_screen.dart';

final calendarRefreshProvider = StateProvider<int>((_) => 0);

final eventsProvider = FutureProvider.autoDispose<List<WardrobeEvent>>((ref) async {
  ref.watch(calendarRefreshProvider);
  return ref.read(calendarRepositoryProvider).events();
});

final outfitsByDateProvider = FutureProvider.autoDispose<List<Outfit>>((ref) async {
  ref.watch(calendarRefreshProvider);
  return ref.read(calendarRepositoryProvider).outfits();
});

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final text = context.tt;
    final cs = context.cs;
    final eventsAsync = ref.watch(eventsProvider);
    final outfitsAsync = ref.watch(outfitsByDateProvider);

    final outfitsByDay = <DateTime, Outfit>{};
    for (final o in outfitsAsync.valueOrNull ?? const <Outfit>[]) {
      if (o.date != null) outfitsByDay[_dayKey(o.date!)] = o;
    }
    final events = eventsAsync.valueOrNull ?? const <WardrobeEvent>[];
    final eventDays = {for (final e in events) _dayKey(e.date)};

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        onPressed: _showAddEvent,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: cs.onSurface,
          onRefresh: () async => ref.read(calendarRefreshProvider.notifier).state++,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              Row(
                children: [
                  const AiSpark(size: 20),
                  const SizedBox(width: 8),
                  Text('Планирование', style: text.labelSmall),
                ],
              ),
              const SizedBox(height: 16),
              Text('Календарь', style: text.displayMedium),
              const SizedBox(height: 20),
              FloatingCard(
                padding: const EdgeInsets.all(12),
                child: TableCalendar(
                  locale: 'ru_RU',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focused,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  selectedDayPredicate: (d) => _selected != null && isSameDay(_selected, d),
                  onDaySelected: (sel, foc) => setState(() {
                    _selected = sel;
                    _focused = foc;
                  }),
                  onPageChanged: (foc) => _focused = foc,
                  calendarFormat: CalendarFormat.month,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: text.titleLarge!,
                    leftChevronIcon: Icon(Icons.chevron_left, color: cs.onSurface),
                    rightChevronIcon: Icon(Icons.chevron_right, color: cs.onSurface),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    weekendStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    defaultTextStyle: TextStyle(color: cs.onSurface),
                    weekendTextStyle: TextStyle(color: cs.onSurface),
                    todayDecoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(color: cs.onSurface),
                    selectedDecoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: TextStyle(color: cs.onPrimary),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, _) {
                      final hasEvent = eventDays.contains(_dayKey(day));
                      final outfit = outfitsByDay[_dayKey(day)];
                      if (outfit != null && outfit.items.isNotEmpty) {
                        return Positioned(
                          bottom: 2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.surfaceContainerLowest, width: 1.5),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ItemImage(url: outfit.items.first.imageUrl, radius: 999),
                          ),
                        );
                      }
                      if (hasEvent) {
                        return Positioned(
                          bottom: 6,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('Предстоящие события', style: text.headlineSmall),
              const SizedBox(height: 16),
              eventsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: LoadingView(),
                ),
                error: (e, _) => Text(ApiClient.errorMessage(e), style: text.bodyMedium),
                data: (list) {
                  final upcoming = list
                      .where((e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 1))))
                      .toList();
                  if (upcoming.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        'Событий пока нет. Добавьте событие кнопкой «+», чтобы AI подобрал образ.',
                        style: text.bodyMedium,
                      ),
                    );
                  }
                  return Column(
                    children: upcoming.map((e) => _EventCard(event: e)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _showAddEvent() async {
    final titleCtrl = TextEditingController();
    final dressCtrl = TextEditingController();
    DateTime date = _selected ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: ctx.cs.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Новое событие', style: ctx.tt.headlineSmall),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(hintText: 'Название (напр. Свадьба подруги)'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: dressCtrl,
                    decoration: const InputDecoration(hintText: 'Дресс-код (напр. Коктейль)'),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setModalState(() => date = picked);
                    },
                    icon: const Icon(Icons.event, size: 18),
                    label: Text(DateFormat('d MMMM yyyy', 'ru').format(date)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      try {
                        await ref.read(calendarRepositoryProvider).createEvent(
                              title: titleCtrl.text.trim(),
                              date: date,
                              dressCode: dressCtrl.text.trim(),
                            );
                        ref.read(calendarRefreshProvider.notifier).state++;
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) showSnack(ctx, ApiClient.errorMessage(e), error: true);
                      }
                    },
                    child: const Text('Создать событие'),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

class _EventCard extends ConsumerStatefulWidget {
  final WardrobeEvent event;
  const _EventCard({required this.event});

  @override
  ConsumerState<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<_EventCard> {
  bool _planning = false;
  Outfit? _planned;

  @override
  Widget build(BuildContext context) {
    final text = context.tt;
    final isPremium = ref.watch(authControllerProvider).isPremium;
    final e = widget.event;
    final dow = DateFormat('EEEE, d MMMM', 'ru').format(e.date).toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FloatingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.celebration_outlined, size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(dow, style: text.labelSmall?.copyWith(color: AppColors.accent, fontSize: 11)),
                ),
                GestureDetector(
                  onTap: _delete,
                  child: Icon(Icons.close, size: 18, color: context.cs.outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(e.title, style: text.headlineSmall),
            if (e.dressCode.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Дресс-код: ${e.dressCode}', style: text.bodyMedium),
            ],
            if (_planning) ...[
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const AiSpark(size: 16),
                    const SizedBox(width: 10),
                    Expanded(child: Text('AI подбирает образ под событие…', style: text.bodyMedium)),
                  ],
                ),
              ),
            ] else if (_planned != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AiSpark(size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_planned!.title, style: text.titleLarge?.copyWith(fontSize: 16))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_planned!.items.isEmpty)
                      Text('В гардеробе пока мало вещей для этого образа. Добавьте больше и попробуйте снова.',
                          style: text.bodySmall)
                    else
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _planned!.items.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => SizedBox(
                            width: 64,
                            child: ItemImage(url: _planned!.items[i].imageUrl, radius: AppRadius.sm),
                          ),
                        ),
                      ),
                    if (_planned!.rationale.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(_planned!.rationale, style: text.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _planning ? null : _plan,
              icon: _planning
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: context.cs.onPrimary))
                  : Icon(isPremium ? Icons.auto_awesome : Icons.lock_outline, size: 18),
              label: Text(_planned == null
                  ? (isPremium ? 'Подобрать образ' : 'Подобрать образ · Premium')
                  : 'Другой образ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _plan() async {
    setState(() => _planning = true);
    try {
      final outfit = await ref.read(calendarRepositoryProvider).planOutfit(widget.event.id);
      if (!mounted) return;
      setState(() => _planned = outfit);
      ref.read(calendarRefreshProvider.notifier).state++;
      showSnack(context, 'Образ подобран');
    } catch (e) {
      if (!mounted) return;
      if (ApiClient.isPremiumRequired(e)) {
        showPremiumRequired(context);
      } else {
        showSnack(context, ApiClient.errorMessage(e), error: true);
      }
    } finally {
      if (mounted) setState(() => _planning = false);
    }
  }

  Future<void> _delete() async {
    try {
      await ref.read(calendarRepositoryProvider).deleteEvent(widget.event.id);
      ref.read(calendarRefreshProvider.notifier).state++;
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    }
  }
}
