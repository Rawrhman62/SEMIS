import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'sheep_screen.dart';
import 'breeding_screen.dart';
import 'pen_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainShellState>();
    if (state != null) {
      state.setIndex(index);
    }
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;
  final Set<int> _loadedTabs = {};

  final _pages = const [
    DashboardScreen(),
    SheepScreen(),
    BreedingScreen(),
    PenScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _loadedTabs.add(_index);
  }

  void setIndex(int value) {
    if (value >= 0 && value < _pages.length) {
      setState(() {
        _index = value;
        _loadedTabs.add(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF14532D);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      body: IndexedStack(
        index: _index,
        children: List.generate(_pages.length, (i) {
          if (_loadedTabs.contains(i)) {
            return _pages[i];
          }
          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE4ECE4), width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: setIndex,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: const Color(0xFFDCFCE7),
          height: 66,
          labelBehavior: NavigationBarTheme.of(context).labelBehavior ??
              NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded, size: 22),
              selectedIcon: Icon(Icons.grid_view_rounded, color: green, size: 22),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.pets_outlined, size: 22),
              selectedIcon: Icon(Icons.pets_rounded, color: green, size: 22),
              label: 'Domba',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_tree_outlined, size: 22),
              selectedIcon: Icon(Icons.account_tree_rounded, color: green, size: 22),
              label: 'Silsilah',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_work_outlined, size: 22),
              selectedIcon: Icon(Icons.home_work_rounded, color: green, size: 22),
              label: 'Kandang',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, size: 22),
              selectedIcon: Icon(Icons.person_rounded, color: green, size: 22),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
