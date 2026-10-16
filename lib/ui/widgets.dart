import 'package:flutter/material.dart';

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String yes = 'بله',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(yes),
        ),
      ],
    ),
  );
  return result ?? false;
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

/// نوار جابه‌جایی بین روزها یا ماه‌ها. دکمه‌ی اول در سمت راست قرار می‌گیرد.
class PeriodNav extends StatelessWidget {
  const PeriodNav({
    super.key,
    required this.label,
    required this.prevText,
    required this.nextText,
    required this.onPrev,
    required this.onNext,
    this.resetText,
    this.onReset,
  });

  final String label;
  final String prevText;
  final String nextText;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final String? resetText;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          TextButton(onPressed: onPrev, child: Text(prevText)),
          Expanded(
            child: Column(
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (onReset != null && resetText != null)
                  TextButton(onPressed: onReset, child: Text(resetText!)),
              ],
            ),
          ),
          TextButton(onPressed: onNext, child: Text(nextText)),
        ],
      ),
    );
  }
}
