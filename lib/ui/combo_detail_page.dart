import 'dart:math';

import 'package:flutter/material.dart';

import '../moves/fighter.dart';
import '../moves/moves.dart';
import '../theme.dart';
import 'move_detail_page.dart';

/// Plays a combo with the animated fighter and highlights the current move.
class ComboDetailPage extends StatefulWidget {
  const ComboDetailPage({
    super.key,
    required this.moveIds,
    required this.level,
    this.note,
    this.isRandom = false,
  });

  final List<String> moveIds;
  final int level;
  final String? note;
  final bool isRandom;

  @override
  State<ComboDetailPage> createState() => _ComboDetailPageState();
}

class _ComboDetailPageState extends State<ComboDetailPage> {
  late List<String> _ids = widget.moveIds;
  bool _playing = true;
  double _speed = 0.5;
  int _current = -1;
  final _random = Random();

  void _reroll() => setState(() {
        _ids = randomCombo(_random, widget.level);
        _current = -1;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRandom ? 'کمبوی تصادفی' : 'تمرین کمبو'),
        actions: [
          if (widget.isRandom)
            IconButton(
              tooltip: 'کمبوی دیگر',
              onPressed: _reroll,
              icon: const Icon(Icons.casino),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          ArenaBox(
            height: 300,
            child: Stack(
              children: [
                Positioned.fill(
                  child: FighterAnimation(
                    moveIds: _ids,
                    speed: _speed,
                    playing: _playing,
                    returnMs: 200,
                    onClipChanged: (i) {
                      if (mounted) setState(() => _current = i);
                    },
                  ),
                ),
                PositionedDirectional(
                  top: 12,
                  start: 14,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      _current >= 0 && _current < _ids.length
                          ? moveById(_ids[_current]).nameEn
                          : 'READY',
                      key: ValueKey(_current),
                      style: display(28,
                          color: _current >= 0 ? AppColors.cyan : AppColors.muted),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 14,
                  end: 14,
                  child: Tag(levelLabels[widget.level]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton.filled(
                onPressed: () => setState(() => _playing = !_playing),
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 8),
              const Text('سرعت', style: TextStyle(color: AppColors.muted)),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<double>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0.25, label: Text('0.25x')),
                    ButtonSegment(value: 0.5, label: Text('0.5x')),
                    ButtonSegment(value: 1.0, label: Text('1x')),
                  ],
                  selected: {_speed},
                  onSelectionChanged: (v) => setState(() => _speed = v.first),
                ),
              ),
            ],
          ),
          const SectionTitle('ترتیب حرکات', kicker: 'SEQUENCE'),
          for (var i = 0; i < _ids.length; i++)
            _SequenceTile(
              index: i,
              move: moveById(_ids[i]),
              active: i == _current,
            ),
          if (widget.note != null) ...[
            const SectionTitle('نکته‌ی مربی', kicker: 'COACH NOTE'),
            Text(widget.note!, style: const TextStyle(height: 1.9)),
          ],
          const SizedBox(height: 16),
          const Text(
            'اول آهسته و تمیز بزن، بعد سرعت را بالا ببر. بعد از هر حرکت دست‌ها به گارد برگردند.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.8),
          ),
        ],
      ),
    );
  }
}

class _SequenceTile extends StatelessWidget {
  const _SequenceTile({required this.index, required this.move, required this.active});

  final int index;
  final Move move;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: ShapeDecoration(
        color: active ? AppColors.blue.withValues(alpha: 0.2) : AppColors.surface,
        shape: BeveledRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          side: BorderSide(color: active ? AppColors.cyan : AppColors.line),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
        leading: Text('${index + 1}',
            style: display(28, color: active ? AppColors.cyan : AppColors.muted)),
        title: Text(move.nameFa, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(move.nameEn, style: display(13, color: AppColors.muted)),
        trailing: const Icon(Icons.info_outline, color: AppColors.muted),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MoveDetailPage(move: move)),
        ),
      ),
      ),
    );
  }
}
