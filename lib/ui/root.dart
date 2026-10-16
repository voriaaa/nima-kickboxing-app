import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../util.dart';
import 'about_page.dart';
import 'coach_shell.dart';
import 'student_shell.dart';

/// بر اساس نقش ذخیره‌شده، صفحه‌ی مربی یا شاگرد یا انتخاب نقش را نشان می‌دهد.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    if (store.role == 'coach') return const CoachShell();
    if (store.role == 'student' && store.studentById(store.meId) != null) {
      return const StudentShell();
    }
    return const RoleScreen();
  }
}

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bigFilled =
        FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56));
    final bigOutlined =
        OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ClubPhoto(size: 200),
                const SizedBox(height: 16),
                Text('باشگاه کیک‌بوکس', style: theme.textTheme.titleLarge),
                Text(
                  'نیما افشار',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  style: bigFilled,
                  onPressed: () => _coachLogin(context),
                  icon: const Icon(Icons.sports),
                  label: const Text('ورود مربی'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: bigOutlined,
                  onPressed: () => _studentLogin(context),
                  icon: const Icon(Icons.person),
                  label: const Text('ورود شاگرد'),
                ),
                const SizedBox(height: 24),
                const PhoneTile(),
                const SizedBox(height: 8),
                const BuilderCredit(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _coachLogin(BuildContext context) async {
    final store = StoreScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final creating = store.coachPin == null;
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => PinDialog(creating: creating),
    );
    if (pin == null) return;
    if (creating) {
      await store.setCoachPin(pin);
      await store.signInCoach();
    } else if (store.checkPin(pin)) {
      await store.signInCoach();
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('رمز اشتباه است')));
    }
  }

  Future<void> _studentLogin(BuildContext context) async {
    final store = StoreScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    if (store.students.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('هنوز شاگردی ثبت نشده. اول مربی باید شاگردها را اضافه کند.'),
      ));
      return;
    }
    final sorted = [...store.students]..sort((a, b) => a.name.compareTo(b.name));
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('اسم خودت را انتخاب کن'),
        children: [
          for (final s in sorted)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, s.id),
              child: Text(s.name),
            ),
        ],
      ),
    );
    if (id != null) await store.signInStudent(id);
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
      setState(() => _error = 'رمز باید ۴ تا ۸ رقم باشد');
      return;
    }
    Navigator.pop(context, pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.creating ? 'یک رمز برای ورود مربی بساز' : 'رمز مربی'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.creating)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('رمز ۴ تا ۸ رقمی انتخاب کن. دفعه‌های بعد با همین وارد می‌شوی.'),
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
        FilledButton(onPressed: _submit, child: const Text('ادامه')),
      ],
    );
  }
}
