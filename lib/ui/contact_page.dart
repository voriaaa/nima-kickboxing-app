import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../club_info.dart';
import '../theme.dart';

/// Opens a link in the matching app; if that fails, copies [fallback].
Future<void> openLink(BuildContext context, Uri uri, String fallback) async {
  final messenger = ScaffoldMessenger.of(context);
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    await Clipboard.setData(ClipboardData(text: fallback));
    messenger.showSnackBar(SnackBar(content: Text('کپی شد: $fallback')));
  }
}

/// Booking and contact page: private sessions and sports consulting.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رزرو و مشاوره')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          ClipPath(
            clipper: const ShapeBorderClipper(shape: cutShape),
            child: SizedBox(
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(clubPhotoAsset, fit: BoxFit.cover,
                      alignment: const Alignment(0, 0.3)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xEE05070D)],
                        stops: [0.35, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    left: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PRIVATE TRAINING',
                            style: display(15, color: AppColors.cyan, spacing: 4)),
                        const SizedBox(height: 4),
                        const Text(
                          coachName,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'برای رزرو تایم کلاس خصوصی یا مشاوره‌ی ورزشی (برنامه‌ی تمرینی، آمادگی مسابقه، تغذیه و کاهش وزن) از یکی از راه‌های زیر با استاد در ارتباط باش.',
            style: TextStyle(color: AppColors.muted, height: 1.8),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tag('کلاس خصوصی'),
              Tag('مشاوره ورزشی'),
              Tag('آمادگی مسابقه'),
              Tag('برنامه تمرینی'),
            ],
          ),
          const SizedBox(height: 16),
          _ContactTile(
            icon: const _InstagramGlyph(),
            colors: const [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
            title: 'اینستاگرام',
            value: '@$instagramHandle',
            onTap: () => openLink(context, Uri.parse(instagramUrl), instagramUrl),
          ),
          _ContactTile(
            icon: Directionality(
              textDirection: TextDirection.ltr,
              child: Transform.rotate(
                angle: -0.45,
                child: const Icon(Icons.send, color: Colors.white, size: 22),
              ),
            ),
            colors: const [Color(0xFF2AABEE), Color(0xFF229ED9)],
            title: 'تلگرام',
            value: '@$telegramHandle',
            onTap: () => openLink(context, Uri.parse(telegramUrl), '@$telegramHandle'),
          ),
          _ContactTile(
            icon: const Icon(Icons.call, color: Colors.white, size: 22),
            colors: const [AppColors.blue, AppColors.blueDeep],
            title: 'تماس تلفنی',
            value: clubPhone,
            onTap: () => openLink(context, Uri(scheme: 'tel', path: clubPhone), clubPhone),
          ),
          _ContactTile(
            icon: const Icon(Icons.sms, color: Colors.white, size: 22),
            colors: const [Color(0xFF3DDC97), Color(0xFF1E9E6A)],
            title: 'پیامک',
            value: clubPhone,
            onTap: () => openLink(context, Uri(scheme: 'sms', path: clubPhone), clubPhone),
          ),
          const SizedBox(height: 32),
          const Text(
            builderCredit,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.colors,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final Widget icon;
  final List<Color> colors;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: ShapeDecoration(
                  gradient: LinearGradient(colors: colors),
                  shape: const BeveledRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                child: Center(child: icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(value,
                          style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple Instagram-style glyph: rounded square, lens and flash dot.
class _InstagramGlyph extends StatelessWidget {
  const _InstagramGlyph();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 22, height: 22, child: CustomPaint(painter: _InstaPainter()));
  }
}

class _InstaPainter extends CustomPainter {
  const _InstaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, w * 0.05, w * 0.9, w * 0.9),
        Radius.circular(w * 0.26),
      ),
      p,
    );
    canvas.drawCircle(Offset(w / 2, w / 2), w * 0.21, p);
    canvas.drawCircle(Offset(w * 0.74, w * 0.26), w * 0.06, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
