import 'package:flutter/material.dart';

class PremiumSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const PremiumSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header / Logo
          Padding(
            padding: const EdgeInsets.only(top: 32.0, left: 24.0, bottom: 32.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLOS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Your Learning OS',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: selectedIndex == 0,
                  onTap: () => onDestinationSelected(0),
                ),
                _SidebarItem(
                  icon: Icons.library_books_rounded,
                  label: 'Library',
                  isSelected: selectedIndex == 1,
                  onTap: () => onDestinationSelected(1),
                ),
                _SidebarItem(
                  icon: Icons.task_alt_rounded,
                  label: 'Tasks',
                  isSelected: selectedIndex == 2,
                  onTap: () => onDestinationSelected(2),
                ),
                _SidebarItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Calendar',
                  isSelected: selectedIndex == 3,
                  onTap: () => onDestinationSelected(3),
                ),
                _SidebarItem(
                  icon: Icons.notes_rounded,
                  label: 'Notes',
                  isSelected: selectedIndex == 4,
                  onTap: () => onDestinationSelected(4),
                ),
                _SidebarItem(
                  icon: Icons.access_alarms_rounded,
                  label: 'Alarms',
                  isSelected: selectedIndex == 5,
                  onTap: () => onDestinationSelected(5),
                ),
                _SidebarItem(
                  icon: Icons.timer_rounded,
                  label: 'Focus Timer',
                  isSelected: selectedIndex == 6,
                  onTap: () => onDestinationSelected(6),
                ),
                _SidebarItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  isSelected: selectedIndex == 7,
                  onTap: () => onDestinationSelected(7),
                ),
                _SidebarItem(
                  icon: Icons.music_note_rounded,
                  label: 'Music',
                  isSelected: selectedIndex == 8,
                  onTap: () => onDestinationSelected(8),
                ),
                _SidebarItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: selectedIndex == 9,
                  onTap: () => onDestinationSelected(9),
                ),
              ],
            ),
          ),
          
          // User Profile Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Text('K', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kavin', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Stay Consistent 🚀', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          // Sync Status
          Padding(
            padding: const EdgeInsets.only(left: 32.0, bottom: 24.0, top: 4.0),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.tertiary, size: 16),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Synced', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('All up to date', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isSelected 
        ? Colors.white 
        : (_isHovered ? Colors.white : Colors.grey.shade400);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? theme.colorScheme.primary 
                : (_isHovered ? theme.colorScheme.surface : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(
                widget.label,
                style: TextStyle(
                  color: color,
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
