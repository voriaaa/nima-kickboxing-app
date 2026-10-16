import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models.dart';
import '../util.dart';
import 'widgets.dart';

/// دو تب: برنامه‌ی هفتگی تمرین و اطلاعیه‌ها.
/// برای مربی editable=true (افزودن و حذف) و برای شاگرد فقط نمایش.
class PlansTabs extends StatelessWidget {
  const PlansTabs({super.key, required this.editable});

  final bool editable;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'برنامه تمرین'),
              Tab(text: 'اطلاعیه‌ها'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                WeeklyPlanView(editable: editable),
                AnnouncementsView(editable: editable),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyPlanView extends StatelessWidget {
  const WeeklyPlanView({super.key, required this.editable});

  final bool editable;

  Future<void> _add(BuildContext context) async {
    final store = StoreScope.read(context);
    final result = await showDialog<(int, String, String)>(
      context: context,
      builder: (_) => const _PlanDialog(),
    );
    if (result != null) store.addPlan(result.$1, result.$2, result.$3);
  }

  List<Widget> _buildItems(BuildContext context, AppStore store) {
    final today = DateTime.now().weekday;
    final theme = Theme.of(context);
    final widgets = <Widget>[];
    for (final wd in weekOrder) {
      final items = store.plans.where((p) => p.weekday == wd).toList();
      if (items.isEmpty) continue;
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Row(
          children: [
            Text(
              faWeekdays[wd] ?? '',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: wd == today ? theme.colorScheme.primary : null,
              ),
            ),
            if (wd == today) ...[
              const SizedBox(width: 8),
              Text('(امروز)', style: TextStyle(color: theme.colorScheme.primary)),
            ],
          ],
        ),
      ));
      for (final PlanItem p in items) {
        widgets.add(Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text(p.title),
            subtitle: p.details.isEmpty ? null : Text(p.details),
            trailing: editable
                ? IconButton(
                    tooltip: 'حذف',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await confirmDialog(
                        context,
                        title: 'حذف «${p.title}»؟',
                        body: 'از برنامه‌ی ${faWeekdays[p.weekday] ?? ''} پاک می‌شود.',
                        yes: 'حذف',
                      );
                      if (ok) store.deletePlan(p.id);
                    },
                  )
                : null,
          ),
        ));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: editable
          ? FloatingActionButton.extended(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add),
              label: const Text('تمرین جدید'),
            )
          : null,
      body: store.plans.isEmpty
          ? EmptyState(
              icon: Icons.event_note,
              text: editable
                  ? 'هنوز برنامه‌ای ثبت نشده.\nبا دکمه‌ی پایین تمرین هر روز هفته را اضافه کن.'
                  : 'مربی هنوز برنامه‌ای ثبت نکرده.',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: _buildItems(context, store),
            ),
    );
  }
}

class _PlanDialog extends StatefulWidget {
  const _PlanDialog();

  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  final _title = TextEditingController();
  final _details = TextEditingController();
  int _weekday = DateTime.now().weekday;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'عنوان تمرین را بنویس');
      return;
    }
    Navigator.pop(context, (_weekday, title, _details.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تمرین جدید'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: 6,
                runSpacing: 0,
                children: [
                  for (final wd in weekOrder)
                    ChoiceChip(
                      label: Text(faWeekdays[wd] ?? ''),
                      selected: _weekday == wd,
                      onSelected: (_) => setState(() => _weekday = wd),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: 'عنوان (مثلاً: کمبوی ضربات پا)',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _details,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'توضیح (اختیاری)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(onPressed: _submit, child: const Text('ثبت')),
      ],
    );
  }
}

class AnnouncementsView extends StatelessWidget {
  const AnnouncementsView({super.key, required this.editable});

  final bool editable;

  Future<void> _add(BuildContext context) async {
    final store = StoreScope.read(context);
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _AnnouncementDialog(),
    );
    if (text != null) store.addAnnouncement(text);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final list = [...store.announcements]
      ..sort((a, b) => b.createdAtIso.compareTo(a.createdAtIso));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: editable
          ? FloatingActionButton.extended(
              onPressed: () => _add(context),
              icon: const Icon(Icons.campaign),
              label: const Text('اطلاعیه جدید'),
            )
          : null,
      body: list.isEmpty
          ? EmptyState(
              icon: Icons.campaign,
              text: editable
                  ? 'هنوز اطلاعیه‌ای نداری.\nلغو کلاس، تغییر ساعت یا مسابقه را اینجا بنویس.'
                  : 'اطلاعیه‌ی جدیدی نیست.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final a = list[i];
                return Card(
                  child: ListTile(
                    title: Text(a.text),
                    subtitle: Text(jalaliLabel(DateTime.parse(a.createdAtIso))),
                    trailing: editable
                        ? IconButton(
                            tooltip: 'حذف',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await confirmDialog(
                                context,
                                title: 'حذف اطلاعیه؟',
                                body: 'این اطلاعیه برای همه پاک می‌شود.',
                                yes: 'حذف',
                              );
                              if (ok) store.deleteAnnouncement(a.id);
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}

class _AnnouncementDialog extends StatefulWidget {
  const _AnnouncementDialog();

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _text.text.trim();
    if (t.isEmpty) {
      setState(() => _error = 'متن اطلاعیه را بنویس');
      return;
    }
    Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('اطلاعیه جدید'),
      content: TextField(
        controller: _text,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(onPressed: _submit, child: const Text('انتشار')),
      ],
    );
  }
}
