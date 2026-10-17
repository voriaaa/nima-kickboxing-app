import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../util.dart';
import 'attendance_page.dart';
import 'fees_page.dart';
import 'plans_page.dart';
import 'students_page.dart';

/// Asks for the coach PIN (creates one the first time), then opens the panel.
Future<void> openCoachPanel(BuildContext context) async {
  final store = StoreScope.read(context);
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (!store.coachUnlocked) {
    final creating = store.coachPin == null;
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => PinDialog(creating: creating),
    );
    if (pin == null) return;
    if (creating) {
      await store.setCoachPin(pin);
    } else if (!store.checkPin(pin)) {
      messenger.showSnackBar(const SnackBar(content: Text('رمز اشتباه است')));
      return;
    }
    store.unlockCoach();
  }
  await nav.push(MaterialPageRoute(builder: (_) => const CoachPanelPage()));
}

class CoachPanelPage extends StatelessWidget {
  const CoachPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پنل مربی'),
          actions: [
            IconButton(
              tooltip: 'قفل پنل',
              icon: const Icon(Icons.lock),
              onPressed: () {
                StoreScope.read(context).lockCoach();
                Navigator.of(context).pop();
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'شاگردان'),
              Tab(text: 'حضور و غیاب'),
              Tab(text: 'شهریه'),
              Tab(text: 'برنامه هفتگی'),
              Tab(text: 'اطلاعیه‌ها'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            StudentsPage(),
            AttendancePage(),
            FeesPage(),
            WeeklyPlanView(editable: true),
            AnnouncementsView(editable: true),
          ],
        ),
      ),
    );
  }
}

class PinDialog extends StatefulWidget {
  const PinDialog({super.key, required this.creating});

  final bool creating;

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = toEn(_controller.text.trim());
    if (!RegExp(r'^\d{4,8}$').hasMatch(pin)) {
      setState(() => _error = 'رمز باید 4 تا 8 رقم باشد');
      return;
    }
    Navigator.pop(context, pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.creating ? 'ساخت رمز پنل مربی' : 'رمز پنل مربی'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.creating)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'این بخش مخصوص مربی است. یک رمز 4 تا 8 رقمی انتخاب کن؛ دفعه‌های بعد با همین وارد می‌شوی.',
                style: TextStyle(height: 1.8),
              ),
            ),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(errorText: _error),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(onPressed: _submit, child: const Text('ورود')),
      ],
    );
  }
}
