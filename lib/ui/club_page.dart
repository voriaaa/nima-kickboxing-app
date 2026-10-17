import 'package:flutter/material.dart';

import '../theme.dart';
import 'coach_panel_page.dart';
import 'contact_page.dart';
import 'plans_page.dart';

/// Club tab: weekly plan and announcements for everyone; coach tools behind a PIN.
class ClubPage extends StatelessWidget {
  const ClubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('باشگاه'),
        actions: [
          TextButton.icon(
            onPressed: () => openCoachPanel(context),
            icon: const Icon(Icons.lock_outline, size: 18),
            label: const Text('پنل مربی'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Material(
              shape: cutShape,
              color: AppColors.surface,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ContactPage()),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.event_available, color: AppColors.cyan, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('رزرو کلاس خصوصی و مشاوره',
                                style: TextStyle(fontWeight: FontWeight.w900)),
                            Text('اینستاگرام، تلگرام و تماس با استاد',
                                style: TextStyle(color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_left, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Expanded(child: PlansTabs(editable: false)),
        ],
      ),
    );
  }
}
