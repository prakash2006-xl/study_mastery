import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/global_ai_chat.dart';
import 'widgets/premium_sidebar.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      drawer: isWideScreen ? null : Drawer(
        child: PremiumSidebar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            _goBranch(index);
            Navigator.pop(context); // close drawer
          },
        ),
      ),
      body: isWideScreen
          ? Row(
              children: [
                PremiumSidebar(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _goBranch,
                ),
                Expanded(child: navigationShell),
              ],
            )
          : Column(
              children: [
                AppBar(
                  title: const Text('PLOS', style: TextStyle(fontWeight: FontWeight.bold)),
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
                Expanded(child: navigationShell),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => const GlobalAiChat(),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        tooltip: 'Global AI Companion',
        child: const Icon(Icons.psychology, size: 32),
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
