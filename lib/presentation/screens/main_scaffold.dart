import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold(
      {super.key, required this.child, required this.currentIndex});

  static const _tabs = [
    _Tab('/home', 'Home', Icons.home_outlined, Icons.home),
    _Tab('/search', 'Search', Icons.search_outlined, Icons.search),
    _Tab('/bookings', 'Bookings', Icons.confirmation_number_outlined,
        Icons.confirmation_number),
    _Tab('/profile', 'Profile', Icons.person_outlined, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primary.withOpacity(0.12),
        destinations: _tabs
            .asMap()
            .entries
            .map((e) => NavigationDestination(
                  icon: Icon(e.value.icon),
                  selectedIcon: Icon(e.value.selectedIcon, color: AppTheme.primary),
                  label: e.value.label,
                ))
            .toList(),
        onDestinationSelected: (i) => context.go(_tabs[i].path),
      ),
    );
  }
}

class _Tab {
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _Tab(this.path, this.label, this.icon, this.selectedIcon);
}
