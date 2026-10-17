import 'package:flutter/material.dart';

import '../moves/fighter.dart';
import '../moves/moves.dart';
import '../moves/pose_data.g.dart';
import '../theme.dart';
import 'move_detail_page.dart';

/// Technique library: every move with a vector figure.
class TechniquesPage extends StatelessWidget {
  const TechniquesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cats = MoveCategory.values;
    return DefaultTabController(
      length: cats.length + 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('آموزش حرکات'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              const Tab(text: 'همه'),
              for (final c in cats) Tab(text: categoryLabels[c]),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _MoveGrid(moves),
            for (final c in cats) _MoveGrid(moves.where((m) => m.category == c).toList()),
          ],
        ),
      ),
    );
  }
}

class _MoveGrid extends StatelessWidget {
  const _MoveGrid(this.items);

  final List<Move> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => MoveCard(move: items[i]),
    );
  }
}

class MoveCard extends StatelessWidget {
  const MoveCard({super.key, required this.move});

  final Move move;

  @override
  Widget build(BuildContext context) {
    final clip = moveClips[move.id];
    return Material(
      shape: cutShape,
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MoveDetailPage(move: move)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF0B1630), AppColors.surface],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: clip == null
                            ? const SizedBox()
                            : FighterStill(
                                pose: clip.impactPose,
                                highlight: clip.limb,
                              ),
                      ),
                    ),
                  ),
                  if (move.code != null)
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: const ShapeDecoration(
                          color: AppColors.blue,
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(7)),
                          ),
                        ),
                        child: Text(move.code!, style: display(18, spacing: 0)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(move.nameEn, style: display(13, color: AppColors.cyan)),
                  const SizedBox(height: 2),
                  Text(
                    move.nameFa,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(levelLabels[move.level],
                      style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
