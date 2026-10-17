import 'package:flutter/material.dart';

import 'club_page.dart';
import 'combos_page.dart';
import 'home_page.dart';
import 'techniques_page.dart';
import 'timer_page.dart';

/// One shared app for coach and students. Coach-only tools sit behind a PIN
/// inside the club tab.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(onNavigate: _go),
      const TechniquesPage(),
      const CombosPage(),
      const TimerPage(),
      const ClubPage(),
    ];
    return Scaffold(
      // IndexedStack keeps the timer running while switching tabs.
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_martial_arts_outlined),
            selectedIcon: Icon(Icons.sports_martial_arts),
            label: 'آموزش',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt),
            label: 'کمبو',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'تایمر',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'باشگاه',
          ),
        ],
      ),
    );
  }
}
