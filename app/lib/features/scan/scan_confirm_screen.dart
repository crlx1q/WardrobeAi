import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/clothing_item.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../wardrobe/wardrobe_providers.dart';

class ScanConfirmScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const ScanConfirmScreen({super.key, required this.imagePath});

  @override
  ConsumerState<ScanConfirmScreen> createState() => _ScanConfirmScreenState();
}

class _ScanConfirmScreenState extends ConsumerState<ScanConfirmScreen> {
  bool _recognizing = true;
  bool _saving = false;
  Object? _error;

  final _name = TextEditingController();
  final _type = TextEditingController();
  final _color = TextEditingController();
  final _material = TextEditingController();
  String _category = 'other';
  List<String> _tags = [];
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    _recognize();
  }

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    _color.dispose();
    _material.dispose();
    super.dispose();
  }

  Future<void> _recognize() async {
    setState(() {
      _recognizing = true;
      _error = null;
    });
    try {
      final result = await ref.read(scanRepositoryProvider).scan(widget.imagePath);
      _imageUrl = result.imageUrl;
      final a = result.attributes;
      _name.text = (a['name'] ?? '').toString();
      _type.text = (a['type'] ?? '').toString();
      _color.text = (a['color'] ?? '').toString();
      _material.text = (a['material'] ?? '').toString();
      _category = (a['category'] ?? 'other').toString();
      _tags = (a['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (mounted) setState(() => _recognizing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _recognizing = false;
          _error = e;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(scanRepositoryProvider).saveItem(
        imageUrl: _imageUrl,
        attributes: {
          'name': _name.text.trim(),
          'type': _type.text.trim(),
          'category': _category,
          'color': _color.text.trim(),
          'material': _material.text.trim(),
          'tags': _tags,
        },
      );
      refreshWardrobeW(ref);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showSnack(context, ApiClient.errorMessage(e), error: true);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.tt;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(_recognizing ? 'AI-анализ' : 'Проверьте детали', style: text.titleLarge),
      ),
      body: _error != null
          ? EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Не удалось распознать',
              message: ApiClient.errorMessage(_error!),
              action: OutlinedButton(onPressed: _recognize, child: const Text('Повторить')),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(widget.imagePath), fit: BoxFit.cover),
                        if (_recognizing) const _AiScanOverlay(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_recognizing)
                  const _AiProgress()
                else ...[
                  _field('Название', _name),
                  _field('Тип', _type),
                  _categorySelector(),
                  _field('Цвет', _color),
                  _field('Материал', _material),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((t) => TagChip(label: '#$t')).toList(),
                    ),
                  ],
                ],
              ],
            ),
      bottomNavigationBar: (_error != null || _recognizing)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: context.cs.onPrimary))
                      : const Text('Добавить в гардероб'),
                ),
              ),
            ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: context.cs.onSurfaceVariant),
            ),
          ),
          TextField(controller: controller),
        ],
      ),
    );
  }

  Widget _categorySelector() {
    final cats = WardrobeCategory.all.where((c) => c.id != 'all').toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text('КАТЕГОРИЯ',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: context.cs.onSurfaceVariant)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cats
                .map((c) => TagChip(
                      label: c.label,
                      selected: _category == c.id,
                      onTap: () => setState(() => _category = c.id),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Animated scanning line drawn over the captured photo while the AI works.
class _AiScanOverlay extends StatefulWidget {
  const _AiScanOverlay();

  @override
  State<_AiScanOverlay> createState() => _AiScanOverlayState();
}

class _AiScanOverlayState extends State<_AiScanOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.15))),
            Align(
              alignment: Alignment(0, -1 + 2 * _c.value),
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.7), blurRadius: 12)],
                  gradient: LinearGradient(colors: [
                    AppColors.accent.withValues(alpha: 0),
                    AppColors.accent,
                    AppColors.accent.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Cycling status captions to make the AI step feel alive.
class _AiProgress extends StatefulWidget {
  const _AiProgress();

  @override
  State<_AiProgress> createState() => _AiProgressState();
}

class _AiProgressState extends State<_AiProgress> {
  static const _steps = [
    'Определяем тип вещи…',
    'Анализируем цвет и материал…',
    'Подбираем название и теги…',
  ];
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _i = (_i + 1) % _steps.length);
      _tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AiSpark(size: 20),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Text(
                  _steps[_i],
                  key: ValueKey(_i),
                  style: context.tt.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Shimmer(height: 44),
          const SizedBox(height: 12),
          const Shimmer(height: 44),
          const SizedBox(height: 12),
          const Shimmer(height: 44, width: 200),
        ],
      ),
    );
  }
}
