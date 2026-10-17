import 'package:flutter/material.dart';

import '../club_info.dart';
import '../data/app_store.dart';
import '../moves/fighter.dart';
import '../moves/moves.dart';
import '../theme.dart';
import '../util.dart';
import 'combo_detail_page.dart';
import 'contact_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onNavigate});

  /// Switches the bottom tab (1 lessons, 2 combos, 3 timer, 4 club).
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final combo = comboOfTheDay(now);
    final todayPlans = store.plans.where((p) => p.weekday == now.weekday).toList();
    final latest = ([...store.announcements]
          ..sort((a, b) => b.createdAtIso.compareTo(a.createdAtIso)))
        .take(1)
        .toList();

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _Hero()),
        SliverToBoxAdapter(
          child: SectionTitle(
            'کمبوی امروز',
            kicker: 'COMBO OF THE DAY',
            trailing: Tag(levelLabels[combo.level]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              child: InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ComboDetailPage(
                    moveIds: combo.moveIds,
                    level: combo.level,
                    note: combo.note,
                  ),
                )),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ArenaBox(
                      height: 190,
                      child: FighterAnimation(
                        moveIds: combo.moveIds,
                        speed: 0.8,
                        returnMs: 200,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(combo.title,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(combo.codes,
                                style: display(18, color: AppColors.cyan)),
                          ),
                          const SizedBox(height: 4),
                          const Text('بزن تا آهسته و قدم‌به‌قدم ببینی',
                              style: TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SectionTitle('دسترسی سریع', kicker: 'TRAIN'),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              _QuickTile(
                icon: Icons.sports_martial_arts,
                title: 'آموزش حرکات',
                kicker: 'TECHNIQUES',
                onTap: () => onNavigate(1),
              ),
              _QuickTile(
                icon: Icons.bolt,
                title: 'تمرین ترکیبی',
                kicker: 'COMBOS',
                onTap: () => onNavigate(2),
              ),
              _QuickTile(
                icon: Icons.timer,
                title: 'تایمر راند',
                kicker: 'ROUND TIMER',
                onTap: () => onNavigate(3),
              ),
              _QuickTile(
                icon: Icons.event_available,
                title: 'رزرو کلاس خصوصی',
                kicker: 'BOOK',
                highlight: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ContactPage()),
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SectionTitle(
            'برنامه‌ی امروز',
            kicker: (faWeekdays[now.weekday] ?? '').isEmpty ? null : 'TODAY',
            trailing: Text(faWeekdays[now.weekday] ?? '',
                style: const TextStyle(color: AppColors.muted)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.list(
            children: todayPlans.isEmpty
                ? [
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.event_busy, color: AppColors.muted),
                        title: Text('برای امروز برنامه‌ای ثبت نشده'),
                        subtitle: Text('برنامه‌ی هفته در تب «باشگاه» است'),
                      ),
                    ),
                  ]
                : [
                    for (final p in todayPlans)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.fitness_center, color: AppColors.cyan),
                          title: Text(p.title),
                          subtitle: p.details.isEmpty ? null : Text(p.details),
                        ),
                      ),
                  ],
          ),
        ),
        if (latest.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: SectionTitle('آخرین اطلاعیه', kicker: 'NEWS'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.campaign, color: AppColors.gold),
                  title: Text(latest.first.text),
                  subtitle: Text(jalaliLabel(DateTime.parse(latest.first.createdAtIso))),
                  onTap: () => onNavigate(4),
                ),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 300 + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(clubPhotoAsset, fit: BoxFit.cover, alignment: const Alignment(0, 0.2)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x9905070D), Color(0x3305070D), AppColors.bg],
                stops: [0, 0.4, 1],
              ),
            ),
          ),
          // diagonal blue slash
          Positioned(
            left: -40,
            right: -40,
            bottom: 70,
            child: Transform.rotate(
              angle: -0.12,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Colors.transparent,
                    AppColors.blue,
                    AppColors.cyan,
                    Colors.transparent,
                  ]),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.7),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            left: 20,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('NIMA AFSHAR', style: display(46, spacing: 3)),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('KICKBOXING TEAM',
                      style: display(17, color: AppColors.cyan, spacing: 7)),
                ),
                const SizedBox(height: 4),
                const Text(
                  clubName,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.kicker,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String kicker;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: cutShape,
      clipBehavior: Clip.antiAlias,
      color: highlight ? null : AppColors.surface,
      child: Ink(
        decoration: highlight
            ? const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.blue, AppColors.blueDeep],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              )
            : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: highlight ? Colors.white : AppColors.cyan, size: 28),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kicker,
                        style: display(12,
                            color: highlight ? Colors.white70 : AppColors.muted,
                            spacing: 2)),
                    const SizedBox(height: 2),
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
