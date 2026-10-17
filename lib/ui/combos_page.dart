import 'dart:math';

import 'package:flutter/material.dart';

import '../moves/moves.dart';
import '../theme.dart';
import 'combo_detail_page.dart';

class CombosPage extends StatefulWidget {
  const CombosPage({super.key});

  @override
  State<CombosPage> createState() => _CombosPageState();
}

class _CombosPageState extends State<CombosPage> {
  int? _level; // null = all
  final _random = Random();

  void _openRandom() {
    final level = _level ?? _random.nextInt(3);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ComboDetailPage(
        moveIds: randomCombo(_random, level),
        level: level,
        isRandom: true,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final list = combos.where((c) => _level == null || c.level == _level).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('تمرین ترکیبی')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // Random combo banner
          Material(
            shape: cutShape,
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.blue, AppColors.blueDeep],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: InkWell(
                onTap: _openRandom,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(Icons.casino, size: 36, color: Colors.white),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RANDOM COMBO',
                                style: display(14, color: Colors.white70, spacing: 3)),
                            const Text('کمبوی تصادفی بساز',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                            const Text('هر بار یک ترکیب تازه، متناسب با سطح انتخابی',
                                style: TextStyle(fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_left, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('همه'),
                selected: _level == null,
                onSelected: (_) => setState(() => _level = null),
              ),
              for (var i = 0; i < levelLabels.length; i++)
                ChoiceChip(
                  label: Text(levelLabels[i]),
                  selected: _level == i,
                  onSelected: (_) => setState(() => _level = i),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final c in list) _ComboCard(combo: c),
        ],
      ),
    );
  }
}

class _ComboCard extends StatelessWidget {
  const _ComboCard({required this.combo});

  final Combo combo;

  @override
  Widget build(BuildContext context) {
    final levelColor = [AppColors.success, AppColors.warn, AppColors.danger][combo.level];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ComboDetailPage(
            moveIds: combo.moveIds,
            level: combo.level,
            note: combo.note,
          ),
        )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Tag(levelLabels[combo.level], color: levelColor),
                  const SizedBox(width: 8),
                  Text('${combo.moveIds.length} حرکت',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  const Spacer(),
                  const Icon(Icons.play_circle_fill, color: AppColors.cyan),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < combo.moveIds.length; i++) ...[
                    if (i > 0)
                      const Text('+',
                          style: TextStyle(
                              color: AppColors.blue, fontWeight: FontWeight.w900)),
                    _MoveChip(id: combo.moveIds[i]),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoveChip extends StatelessWidget {
  const _MoveChip({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final m = moveById(id);
    final kick = m.category == MoveCategory.kick;
    final def = m.category == MoveCategory.defense;
    final color = def ? AppColors.success : (kick ? AppColors.gold : AppColors.cyan);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BeveledRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
      ),
      child: Text(
        m.nameFa.split(' (').first,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}
