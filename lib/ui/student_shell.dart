import 'package:flutter/material.dart';

import '../data/app_store.dart';
import 'about_page.dart';
import 'my_status_page.dart';
import 'plans_page.dart';
import 'timer_page.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  static const _titles = ['برنامه و اطلاعیه', 'وضعیت من', 'تایمر راند'];

  static const _pages = <Widget>[
    PlansTabs(editable: false),
    MyStatusPage(),
    TimerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final me = store.studentById(store.meId);
    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 1 && me != null ? me.name : _titles[_index]),
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
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'برنامه',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'وضعیت من',
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
