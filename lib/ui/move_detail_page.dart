import 'package:flutter/material.dart';

import '../moves/fighter.dart';
import '../moves/moves.dart';
import '../moves/pose_data.g.dart';
import '../theme.dart';
import 'combo_detail_page.dart';

class MoveDetailPage extends StatefulWidget {
  const MoveDetailPage({super.key, required this.move});

  final Move move;

  @override
  State<MoveDetailPage> createState() => _MoveDetailPageState();
}

class _MoveDetailPageState extends State<MoveDetailPage> {
  bool _playing = true;
  double _speed = 0.5;

  @override
  Widget build(BuildContext context) {
    final m = widget.move;
    final clip = moveClips[m.id];
    final related = combosWith(m.id).take(4).toList();

    return Scaffold(
      appBar: AppBar(title: Text(m.nameFa)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          ArenaBox(
            height: 300,
            child: Stack(
              children: [
                Positioned.fill(
                  child: FighterAnimation(
                    moveIds: [m.id],
                    speed: _speed,
                    playing: _playing,
                    showArrows: true,
                  ),
                ),
                PositionedDirectional(
                  top: 12,
                  start: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.nameEn, style: display(26)),
                      if (m.code != null)
                        Text('NO. ${m.code}',
                            style: display(14, color: AppColors.cyan, spacing: 3)),
                    ],
                  ),
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
          if (clip != null && clip.keyframes.isNotEmpty) ...[
            const SectionTitle('مراحل اجرا', kicker: 'STEP BY STEP'),
            SizedBox(
              height: 150,
              child: Row(
                children: [
                  _Frame(index: 1, label: 'گارد', pose: guardPose, limb: clip.limb),
                  for (var i = 0; i < clip.keyframes.length; i++) ...[
                    const SizedBox(width: 8),
                    _Frame(
                      index: i + 2,
                      label: clip.keyframes[i].label,
                      pose: clip.keyframes[i].pose,
                      limb: clip.limb,
                      arrows: i == clip.keyframes.length - 1 ? clip.arrows : const [],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SectionTitle('توضیح', kicker: 'OVERVIEW'),
          Text(m.summary, style: const TextStyle(height: 1.9)),
          if (m.target != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.gps_fixed, size: 18, color: AppColors.gold),
                const SizedBox(width: 8),
                Text('هدف: ${m.target}', style: const TextStyle(color: AppColors.gold)),
              ],
            ),
          ],
          const SectionTitle('چطور بزنیم', kicker: 'HOW TO'),
          for (var i = 0; i < m.steps.length; i++)
            _NumberedLine(number: i + 1, text: m.steps[i]),
          const SectionTitle('نکته‌ها', kicker: 'TIPS'),
          for (final t in m.tips)
            _IconLine(icon: Icons.check_circle, color: AppColors.success, text: t),
          const SectionTitle('اشتباهات رایج', kicker: 'AVOID'),
          for (final t in m.mistakes)
            _IconLine(icon: Icons.cancel, color: AppColors.danger, text: t),
          if (related.isNotEmpty) ...[
            const SectionTitle('در این کمبوها', kicker: 'COMBOS'),
            for (final c in related)
              Card(
                child: ListTile(
                  title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(levelLabels[c.level]),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ComboDetailPage(
                      moveIds: c.moveIds,
                      level: c.level,
                      note: c.note,
                    ),
                  )),
                ),
              ),
          ],
          const SizedBox(height: 12),
          const Text(
            'توضیحات برای گارد راست‌دست (پای چپ جلو) است؛ اگر چپ‌دست هستی، چپ و راست را برعکس کن.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.8),
          ),
        ],
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.index,
    required this.label,
    required this.pose,
    required this.limb,
    this.arrows = const [],
  });

  final int index;
  final String label;
  final Pose pose;
  final Limb? limb;
  final List<Arrow> arrows;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: const ShapeDecoration(color: AppColors.surface, shape: cutShape),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: FighterStill(pose: pose, highlight: limb, arrows: arrows),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
              child: Text(
                '$index. $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberedLine extends StatelessWidget {
  const _NumberedLine({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const ShapeDecoration(
              color: AppColors.blueDeep,
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
            ),
            child: Text('$number', style: display(16, spacing: 0)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.8))),
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.8))),
        ],
      ),
    );
  }
}
