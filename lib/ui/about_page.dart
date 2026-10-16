import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../club_info.dart';
import '../util.dart';

/// تماس با باشگاه: اگر برنامه‌ی تماس باز نشد، شماره کپی می‌شود.
Future<void> callClub(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  var ok = false;
  try {
    ok = await launchUrl(Uri(scheme: 'tel', path: clubPhone));
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    await Clipboard.setData(const ClipboardData(text: clubPhone));
    messenger.showSnackBar(
      const SnackBar(content: Text('شماره کپی شد')),
    );
  }
}

/// عکس باشگاه با گوشه‌های گرد
class ClubPhoto extends StatelessWidget {
  const ClubPhoto({super.key, this.size});

  /// اگر null باشد، به عرض موجود کشیده می‌شود.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(clubPhotoAsset, fit: BoxFit.cover),
    );
    if (size != null) {
      return SizedBox(width: size, height: size, child: image);
    }
    return AspectRatio(aspectRatio: 1, child: image);
  }
}

/// ردیف تماس با شماره‌ی باشگاه
class PhoneTile extends StatelessWidget {
  const PhoneTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.call),
      title: Text(toFa(clubPhone)),
      subtitle: const Text('برای تماس با مربی بزن'),
      onTap: () => callClub(context),
    );
  }
}

/// نوشته‌ی کوچک و کم‌رنگ سازنده‌ی برنامه
class BuilderCredit extends StatelessWidget {
  const BuilderCredit({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      builderCredit,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('درباره‌ی باشگاه')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ClubPhoto(),
          const SizedBox(height: 16),
          Text(
            clubName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Card(child: PhoneTile()),
          const SizedBox(height: 24),
          const BuilderCredit(),
        ],
      ),
    );
  }
}
