import 'package:flutter/material.dart';

import '../data/app_store.dart';
import 'about_page.dart';
import 'attendance_page.dart';
import 'fees_page.dart';
import 'plans_page.dart';
import 'students_page.dart';
import 'timer_page.dart';

class CoachShell extends StatefulWidget {
  const CoachShell({super.key});

  @override
  State<CoachShell> createState() => _CoachShellState();
}

class _CoachShellState extends State<CoachShell> {
  int _index = 0;

  static const _titles = [
    'شاگردان',
    'حضور و غیاب',
    'شهریه',
    'برنامه و اطلاعیه',
    'تایمر راند',
  ];

  static const _pages = <Widget>[
    StudentsPage(),
    AttendancePage(),
    FeesPage(),
    PlansTabs(editable: true),
    TimerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'about') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutPage()),
                );
              } else if (v == 'logout') {
                StoreScope.read(context).signOut();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'about', child: Text('درباره‌ی باشگاه')),
              PopupMenuItem(value: 'logout', child: Text('خروج')),
            ],
          ),
        ],
      ),
      // IndexedStack باعث می‌شود تایمر با عوض‌کردن تب متوقف نشود.
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'شاگردان',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'حضور',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'شهریه',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'برنامه',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'تایمر',
          ),
        ],
      ),
    );
  }
}
