import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models.dart';
import '../util.dart';
import 'widgets.dart';

class FeesPage extends StatefulWidget {
  const FeesPage({super.key});

  @override
  State<FeesPage> createState() => _FeesPageState();
}

class _FeesPageState extends State<FeesPage> {
  String _month = monthKey(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final students = [...store.students]
      ..sort((a, b) => a.name.compareTo(b.name));

    var expected = 0;
    var received = 0;
    for (final s in students) {
      expected += s.monthlyFee;
      received += store.paidFor(s.id, _month);
    }
    final remaining = expected > received ? expected - received : 0;
    final isCurrent = _month == monthKey(DateTime.now());

    return Column(
      children: [
        PeriodNav(
          label: monthLabel(_month),
          prevText: 'ماه قبل',
          nextText: 'ماه بعد',
          onPrev: () => setState(() => _month = shiftMonth(_month, -1)),
          onNext: () => setState(() => _month = shiftMonth(_month, 1)),
          resetText: isCurrent ? null : 'برو به این ماه',
          onReset: isCurrent
              ? null
              : () => setState(() => _month = monthKey(DateTime.now())),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                children: [
                  _Stat(label: 'انتظار', value: expected),
                  _Stat(label: 'دریافتی', value: received),
                  _Stat(label: 'باقی‌مانده', value: remaining),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? const EmptyState(
                  icon: Icons.payments,
                  text: 'اول در تب «شاگردان» شاگردها و شهریه‌شان را ثبت کن.',
                )
              : ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = students[i];
                    final paid = store.paidFor(s.id, _month);
                    return ListTile(
                      title: Text(s.name),
                      subtitle: Text(
                        'شهریه ${money(s.monthlyFee)} · پرداختی ${money(paid)} تومان',
                      ),
                      trailing: _StatusChip(fee: s.monthlyFee, paid: paid),
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) =>
                            _PaymentSheet(studentId: s.id, month: _month),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            money(value),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text('تومان', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.fee, required this.paid});

  final int fee;
  final int paid;

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;
    if (fee == 0) {
      text = 'بدون شهریه';
      color = Colors.grey;
    } else if (paid >= fee) {
      text = 'پرداخت شده';
      color = Colors.green;
    } else if (paid > 0) {
      text = 'بخشی';
      color = Colors.orange;
    } else {
      text = 'پرداخت نشده';
      color = Colors.redAccent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.studentId, required this.month});

  final String studentId;
  final String month;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _amount = TextEditingController();
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    final store = StoreScope.of(context);
    final s = store.studentById(widget.studentId);
    if (s != null) {
      final rem = s.monthlyFee - store.paidFor(s.id, widget.month);
      if (rem > 0) _amount.text = toFa(rem);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _add(AppStore store) {
    final value = parseInt(_amount.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مبلغ را درست وارد کن')),
      );
      return;
    }
    store.addPayment(widget.studentId, value, widget.month);
    _amount.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final s = store.studentById(widget.studentId);
    if (s == null) return const SizedBox.shrink();

    final paid = store.paidFor(s.id, widget.month);
    final remaining = s.monthlyFee > paid ? s.monthlyFee - paid : 0;
    final list = store.paymentsFor(s.id, widget.month);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.name, style: theme.textTheme.titleLarge),
            Text(
              '${monthLabel(widget.month)} · باقی‌مانده ${money(remaining)} تومان',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'مبلغ پرداختی (تومان)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _add(store),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _add(store),
                  child: const Text('ثبت'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              const Text('در این ماه هنوز پرداختی ثبت نشده.')
            else
              for (final Payment p in list)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${money(p.amount)} تومان'),
                  subtitle: Text(jalaliLabel(DateTime.parse(p.dateIso))),
                  trailing: IconButton(
                    tooltip: 'حذف پرداخت',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await confirmDialog(
                        context,
                        title: 'حذف این پرداخت؟',
                        body: '${money(p.amount)} تومان از این ماه کم می‌شود.',
                        yes: 'حذف',
                      );
                      if (ok) store.deletePayment(p.id);
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
