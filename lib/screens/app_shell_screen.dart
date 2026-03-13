import 'package:expense_tracker_app/controllers/navigation_controller.dart';
import 'package:expense_tracker_app/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  late final NavigationController _navigationController;

  final List<Widget> _tabs = const [
    DashboardScreen(),
    _PlaceholderTab(title: 'Transactions'),
    _PlaceholderTab(title: 'Budget'),
    _PlaceholderTab(title: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _navigationController = NavigationController();
  }

  @override
  void dispose() {
    _navigationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _navigationController,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            if (isWide) {
              return _buildWideScaffold();
            }
            return _buildMobileScaffold();
          },
        );
      },
    );
  }

  Scaffold _buildMobileScaffold() {
    return Scaffold(
      body: IndexedStack(
        index: _navigationController.currentIndex,
        children: _tabs,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        // Reserved for the Add Transaction flow owned by another teammate.
        onPressed: () {},
        tooltip: 'Add transaction',
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavTabItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  selected: _navigationController.currentIndex == 0,
                  onTap: () => _navigationController.changeTab(0),
                ),
                _NavTabItem(
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  label: 'Transactions',
                  selected: _navigationController.currentIndex == 1,
                  onTap: () => _navigationController.changeTab(1),
                ),
                const SizedBox(width: 44),
                _NavTabItem(
                  icon: Icons.pie_chart_outline,
                  selectedIcon: Icons.pie_chart,
                  label: 'Budget',
                  selected: _navigationController.currentIndex == 2,
                  onTap: () => _navigationController.changeTab(2),
                ),
                _NavTabItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Settings',
                  selected: _navigationController.currentIndex == 3,
                  onTap: () => _navigationController.changeTab(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Scaffold _buildWideScaffold() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        // Reserved for the Add Transaction flow owned by another teammate.
        onPressed: () {},
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _navigationController.currentIndex,
            onDestinationSelected: _navigationController.changeTab,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Transactions'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.pie_chart_outline),
                selectedIcon: Icon(Icons.pie_chart),
                label: Text('Budget'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: _navigationController.currentIndex,
              children: _tabs,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              color: selected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? activeColor : inactiveColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          '$title screen (coming soon)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
