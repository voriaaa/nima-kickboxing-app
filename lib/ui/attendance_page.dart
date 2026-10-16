import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../util.dart';
import 'widgets.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime _day = DateTime.now();

  void _shift(int days) => setState(() => _day = _day.add(Duration(days: days)));

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final key = dateKey(_day);
    final students = [...store.students]
      ..sort((a, b) => a.name.compareTo(b.name));
    final presentCount = store.attendance[key]?.length ?? 0;
    final isToday = key == dateKey(DateTime.now());
    final weekday = faWeekdays[_day.weekday] ?? '';

    return Column(
      children: [
        PeriodNav(
          label: '$weekday ${jalaliLabel(_day)}',
          prevText: 'روز قبل',
          nextText: 'روز بعد',
          onPrev: () => _shift(-1),
          onNext: () => _shift(1),
          resetText: isToday ? null : 'برو به امروز',
          onReset: isToday ? null : () => setState(() => _day = DateTime.now()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'حاضر: ${toFa(presentCount)} از ${toFa(students.length)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: students.isEmpty
              ? const EmptyState(
                  icon: Icons.fact_check,
                  text: 'اول در تب «شاگردان» شاگردها را اضافه کن.',
                )
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, i) {
                    final s = students[i];
                    return CheckboxListTile(
                      value: store.isPresent(key, s.id),
                      onChanged: (_) => store.toggleAttendance(key, s.id),
                      title: Text(s.name),
                      subtitle: Text(s.levelLabel),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
