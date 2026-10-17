import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models.dart';
import '../util.dart';
import 'widgets.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final list = store.students
        .where((s) => s.name.contains(_query.trim()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StudentFormPage()),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('شاگرد جدید'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'جستجوی نام',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? EmptyState(
                    icon: Icons.groups,
                    text: store.students.isEmpty
                        ? 'هنوز شاگردی ثبت نشده.\nبا دکمه‌ی پایین اولین شاگرد را اضافه کن.'
                        : 'نتیجه‌ای پیدا نشد.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final s = list[i];
                      final parts = <String>[
                        s.levelLabel,
                        if (s.weightKg != null) '${fmtNum(s.weightKg!)} کیلو',
                        if (s.monthlyFee > 0) '${money(s.monthlyFee)} تومان',
                      ];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(s.name.isEmpty ? '?' : s.name.substring(0, 1)),
                        ),
                        title: Text(s.name),
                        subtitle: Text(parts.join(' · ')),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StudentFormPage(student: s),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class StudentFormPage extends StatefulWidget {
  const StudentFormPage({super.key, this.student});

  final Student? student;

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _emergency;
  late final TextEditingController _weight;
  late final TextEditingController _fee;
  late final TextEditingController _notes;
  late int _level;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _name = TextEditingController(text: s?.name ?? '');
    _phone = TextEditingController(text: s?.phone ?? '');
    _emergency = TextEditingController(text: s?.emergencyPhone ?? '');
    _weight = TextEditingController(
        text: s?.weightKg == null ? '' : fmtNum(s!.weightKg!));
    _fee = TextEditingController(
        text: (s == null || s.monthlyFee == 0) ? '' : '${s.monthlyFee}');
    _notes = TextEditingController(text: s?.notes ?? '');
    _level = s?.level ?? 0;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _emergency.dispose();
    _weight.dispose();
    _fee.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final store = StoreScope.read(context);
    final weight = parseDouble(_weight.text);
    final fee = parseInt(_fee.text) ?? 0;
    final existing = widget.student;
    if (existing == null) {
      store.addStudent(Student(
        id: store.newId(),
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        emergencyPhone: _emergency.text.trim(),
        level: _level,
        weightKg: weight,
        monthlyFee: fee,
        notes: _notes.text.trim(),
      ));
    } else {
      existing
        ..name = _name.text.trim()
        ..phone = _phone.text.trim()
        ..emergencyPhone = _emergency.text.trim()
        ..level = _level
        ..weightKg = weight
        ..monthlyFee = fee
        ..notes = _notes.text.trim();
      store.updateStudent(existing);
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final s = widget.student;
    if (s == null) return;
    final store = StoreScope.read(context);
    final nav = Navigator.of(context);
    final ok = await confirmDialog(
      context,
      title: 'حذف ${s.name}؟',
      body: 'حضور و پرداخت‌های ثبت‌شده‌ی این شاگرد هم پاک می‌شود و برنمی‌گردد.',
      yes: 'حذف',
    );
    if (!ok) return;
    store.deleteStudent(s.id);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.student != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'ویرایش شاگرد' : 'شاگرد جدید'),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'حذف',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'نام و نام خانوادگی',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'نام را وارد کن' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'شماره‌ی تماس',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergency,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'شماره‌ی تماس اضطراری (خانواده)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('سطح'),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [
                for (var i = 0; i < Student.levels.length; i++)
                  ButtonSegment<int>(value: i, label: Text(Student.levels[i])),
              ],
              selected: {_level},
              onSelectionChanged: (v) => setState(() => _level = v.first),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weight,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'وزن (کیلو)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _fee,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'شهریه‌ی ماهانه (تومان)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'یادداشت خصوصی مربی',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52)),
              onPressed: _save,
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
  }
}
