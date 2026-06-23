import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../shared/theme/shadcn_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static final _tabs = [
    (icon: LucideIcons.home, label: 'Home', path: '/'),
    (icon: LucideIcons.calendarDays, label: 'Meals', path: '/meals'),
    (icon: LucideIcons.bookOpen, label: 'Recipes', path: '/recipes'),
    (icon: LucideIcons.package, label: 'Pantry', path: '/pantry'),
    (icon: LucideIcons.shoppingCart, label: 'Groceries', path: '/groceries'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _tabs.length; i++) {
      if (_tabs[i].path == '/') {
        if (location == '/') return i;
      } else if (location.startsWith(_tabs[i].path)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          border: Border(top: BorderSide(color: AppTheme.divider(context), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.surface(context),
          selectedItemColor: AppTheme.sage,
          unselectedItemColor: AppTheme.textCaption(context),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          elevation: 0,
          onTap: (i) => context.go(_tabs[i].path),
          items: _tabs.map((t) => BottomNavigationBarItem(
            icon: Icon(t.icon, size: 22),
            label: t.label,
          )).toList(),
        ),
      ),
    );
  }
}
