import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../util.dart';
import 'widgets.dart';

/// صفحه‌ی «وضعیت من» برای شاگرد: حضور این ماه و وضعیت شهریه.
class MyStatusPage extends StatelessWidget {
  const MyStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final me = store.studentById(store.meId);
    if (me == null) {
      return const EmptyState(icon: Icons.person_off, text: 'شاگردی پیدا نشد.');
    }

    final theme = Theme.of(context);
    final month = monthKey(DateTime.now());
    final present = store.presentCountInMonth(me.id, month);
    final recent = store.attendedDays(me.id).take(8).toList();
    final fee = me.monthlyFee;
    final paid = store.paidFor(me.id, month);
    final remaining = fee > paid ? fee - paid : 0;

    final String feeText;
    final Color feeColor;
    if (fee == 0) {
      feeText = 'شهریه‌ای برای تو ثبت نشده';
      feeColor = Colors.grey;
    } else if (paid >= fee) {
      feeText = 'شهریه‌ی این ماه پرداخت شده ✓';
      feeColor = Colors.green;
    } else {
      feeText = 'باقی‌مانده: ${money(remaining)} تومان';
      feeColor = Colors.orange;
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('حضور در ${monthLabel(month)}',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '${toFa(present)} جلسه',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (recent.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('آخرین جلسه‌ها', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  for (final day in recent)
                    Text(jalaliLabel(DateTime.parse(day))),
                ],
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('شهریه‌ی ${monthLabel(month)}',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(feeText,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: feeColor, fontWeight: FontWeight.bold)),
                if (fee > 0) ...[
                  const SizedBox(height: 8),
                  Text('شهریه‌ی ماهانه: ${money(fee)} تومان'),
                  Text('پرداخت‌شده: ${money(paid)} تومان'),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
